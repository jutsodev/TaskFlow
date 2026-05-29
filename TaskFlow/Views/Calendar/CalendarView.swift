import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var appState: AppState
    @State private var displayedMonth = Calendar.current.component(.month, from: Date())
    @State private var displayedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedDate: Date? = nil
    @State private var showCreateTask = false
    @State private var showDayDetail = false

    private let weekdays = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    monthNavigation
                    weekdayHeader
                    monthGridView
                    if let date = selectedDate {
                        selectedDaySection(date)
                    }
                    upcomingSection
                    overdueSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Календарь")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation {
                                displayedMonth = Calendar.current.component(.month, from: Date())
                                displayedYear = Calendar.current.component(.year, from: Date())
                                selectedDate = Date()
                            }
                        } label: {
                            Text("Сегодня")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Button { showCreateTask = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView().environmentObject(appState)
            }
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button {
                withAnimation { previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial, in: Circle())
                    .glassEffect(.regular, in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("\(String(displayedYear))")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation { nextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial, in: Circle())
                    .glassEffect(.regular, in: Circle())
            }
        }
    }

    private var monthName: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "LLLL"
        var comps = DateComponents()
        comps.year = displayedYear
        comps.month = displayedMonth
        comps.day = 1
        let date = Calendar.current.date(from: comps) ?? Date()
        return fmt.string(from: date).capitalized
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGridView: some View {
        let grid = appState.monthGrid(year: displayedYear, month: displayedMonth)

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(grid.days) { day in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDate = day.date
                    }
                } label: {
                    dayCell(day)
                }
            }
        }
        .cardStyle()
    }

    private func dayCell(_ day: MonthDay) -> some View {
        let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } ?? false

        return VStack(spacing: 3) {
            Text("\(day.dayNumber)")
                .font(.system(size: 14, weight: day.isToday ? .bold : .regular, design: .rounded))
                .foregroundStyle(
                    !day.isCurrentMonth ? .tertiary :
                    isSelected ? Color(.systemBackground) :
                    day.isToday ? .primary : .primary
                )

            HStack(spacing: 2) {
                if day.tasksCount > 0 {
                    Circle()
                        .fill(day.completedCount == day.tasksCount ? Color.primary : Color.secondary.opacity(0.4))
                        .frame(width: 4, height: 4)
                }
                if day.hasGoalCheckIn {
                    Circle()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: 4, height: 4)
                }
                if day.habitsCompleted > 0 {
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            isSelected ? AnyShapeStyle(Color.primary) :
            day.isToday ? AnyShapeStyle(Color.primary.opacity(0.08)) :
            AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    private func selectedDaySection(_ date: Date) -> some View {
        let dayTasks = appState.tasksForDate(date)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "d MMMM, EEEE"

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(fmt.string(from: date).capitalized)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                if !dayTasks.isEmpty {
                    Text("\(dayTasks.filter { $0.isCompleted }.count)/\(dayTasks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if dayTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray").font(.system(size: 24)).foregroundStyle(.tertiary)
                        Text("Нет задач").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(dayTasks) { task in
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { appState.toggleTask(task) }
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 14, weight: .medium))
                                .strikethrough(task.isCompleted)
                            HStack(spacing: 4) {
                                Image(systemName: task.category.icon).font(.system(size: 9))
                                Text(task.category.rawValue).font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: task.priority.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(task.priority.color)
                    }
                    if task.id != dayTasks.last?.id { Divider() }
                }
            }

            let dayGoals = appState.goals.filter { goal in
                let fmtKey = DateFormatter()
                fmtKey.dateFormat = "yyyy-MM-dd"
                return goal.completedDays.contains(fmtKey.string(from: date))
            }

            if !dayGoals.isEmpty {
                Divider()
                Text("Отмеченные цели").font(.caption).foregroundStyle(.secondary)
                ForEach(dayGoals) { goal in
                    HStack(spacing: 8) {
                        Image(systemName: goal.category.icon).font(.system(size: 13))
                        Text(goal.title).font(.system(size: 13)).lineLimit(1)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(.green)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var upcomingSection: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let nextWeek = cal.date(byAdding: .day, value: 7, to: today)!
        let upcoming = appState.tasks.filter { !$0.isCompleted && $0.startDate > today && $0.startDate <= nextWeek }
            .sorted { $0.startDate < $1.startDate }

        return Group {
            if !upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Предстоящие (7 дней)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    ForEach(upcoming) { task in
                        HStack(spacing: 12) {
                            Image(systemName: task.category.icon)
                                .font(.system(size: 14))
                                .frame(width: 28, height: 28)
                                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                                Text(shortRuDate(task.startDate)).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: task.priority.icon).font(.system(size: 11)).foregroundStyle(task.priority.color)
                        }
                        if task.id != upcoming.last?.id { Divider() }
                    }
                }
                .cardStyle()
            }
        }
    }

    private var overdueSection: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let overdue = appState.tasks.filter { !$0.isCompleted && $0.startDate < today }
            .sorted { $0.startDate > $1.startDate }

        return Group {
            if !overdue.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Просроченные")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Spacer()
                        Text("\(overdue.count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)
                    }
                    ForEach(overdue.prefix(5)) { task in
                        HStack(spacing: 12) {
                            Button {
                                withAnimation { appState.toggleTask(task) }
                            } label: {
                                Image(systemName: "circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.red.opacity(0.6))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                                Text(shortRuDate(task.startDate)).font(.caption2).foregroundStyle(.red.opacity(0.7))
                            }
                            Spacer()
                        }
                        if task.id != overdue.prefix(5).last?.id { Divider() }
                    }
                }
                .cardStyle()
            }
        }
    }

    private func previousMonth() {
        if displayedMonth == 1 { displayedMonth = 12; displayedYear -= 1 }
        else { displayedMonth -= 1 }
    }

    private func nextMonth() {
        if displayedMonth == 12 { displayedMonth = 1; displayedYear += 1 }
        else { displayedMonth += 1 }
    }
}
