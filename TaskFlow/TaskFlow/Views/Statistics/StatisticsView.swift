import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedRange: TimeRange = .week
    @State private var showExport = false
    @State private var selectedExportFormat: ExportFormat = .json

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    rangePicker
                    productivityCard
                    weekSummaryCard
                    taskCompletionCard
                    categoryBreakdown
                    priorityBreakdown
                    habitsAnalytics
                    goalsProgress
                    moodTracker
                    streakHistory
                    timeSpentCard
                    achievementsGrid
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Статистика")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showExport = true } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExport) { exportSheet }
        }
    }

    private var rangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases) { range in
                    Button {
                        withAnimation { selectedRange = range }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selectedRange == range
                                ? AnyShapeStyle(Color.primary)
                                : AnyShapeStyle(Color.clear),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedRange == range ? Color(.systemBackground) : .primary)
                            .overlay(Capsule().stroke(.separator, lineWidth: selectedRange == range ? 0 : 1))
                    }
                }
            }
        }
    }

    private var productivityCard: some View {
        let score = appState.productivityScore()
        return VStack(spacing: 16) {
            HStack {
                Text("Продуктивность")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Text(score.grade)
                    .font(.system(size: 28, weight: .black, design: .rounded))
            }

            HStack(spacing: 20) {
                ProgressRing(progress: score.overall, size: 80, lineWidth: 8)
                VStack(alignment: .leading, spacing: 8) {
                    Text(score.description)
                        .font(.system(size: 14, weight: .medium))
                    Text("\(Int(score.overall * 100)) из 100 баллов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                scoreBar("Задачи", score.taskCompletion)
                scoreBar("Привычки", score.habitConsistency)
                scoreBar("Цели", score.goalProgress)
                scoreBar("Фокус", score.focusTime)
                scoreBar("Серия", score.streak)
            }
        }
        .cardStyle()
    }

    private func scoreBar(_ label: String, _ value: Double) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.separator)).frame(height: 6)
                    Capsule().fill(.primary)
                        .frame(width: max(geo.size.width * value, 4), height: 6)
                }
            }
            .frame(height: 6)
            Text("\(Int(value * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .frame(width: 34, alignment: .trailing)
        }
    }

    private var weekSummaryCard: some View {
        let summary = appState.weekSummary()
        return VStack(alignment: .leading, spacing: 14) {
            Text("Итоги недели")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                miniStat("\(summary.totalTasksCompleted)", "Выполнено")
                miniStat("\(summary.totalTasksCreated)", "Создано")
                miniStat("\(summary.streakDays) дн.", "Серия")
                miniStat("\(summary.totalFocusMinutes) мин", "Фокус")
                miniStat(String(format: "%.1f", summary.avgMood), "Настроение")
                miniStat("\(Int(summary.habitCompletionRate * 100))%", "Привычки")
            }

            if let topCat = summary.topCategory {
                HStack(spacing: 8) {
                    Image(systemName: topCat.icon).font(.system(size: 14))
                    Text("Топ категория: \(topCat.rawValue)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Text("Активность за неделю")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            WeekBarChart(data: weeklyTaskData(from: appState))
        }
        .cardStyle()
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var taskCompletionCard: some View {
        let total = appState.tasks.count
        let completed = appState.totalCompleted
        let active = total - completed

        return VStack(alignment: .leading, spacing: 14) {
            Text("Задачи")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            HStack(spacing: 20) {
                ProgressRing(progress: total > 0 ? Double(completed) / Double(total) : 0, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle().fill(.primary).frame(width: 8, height: 8)
                        Text("Выполнено: \(completed)").font(.system(size: 13))
                    }
                    HStack(spacing: 8) {
                        Circle().fill(Color(UIColor.separator)).frame(width: 8, height: 8)
                        Text("Активных: \(active)").font(.system(size: 13))
                    }
                    HStack(spacing: 8) {
                        Circle().stroke(.separator, lineWidth: 1).frame(width: 8, height: 8)
                        Text("Всего: \(total)").font(.system(size: 13)).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            if !appState.tasks.isEmpty {
                StreakCalendarView(
                    completedDates: appState.tasks.filter { $0.isCompleted }.map { task in
                        let fmt = DateFormatter()
                        fmt.dateFormat = "yyyy-MM-dd"
                        return fmt.string(from: task.startDate)
                    }
                )
            }
        }
        .cardStyle()
    }

    private var categoryBreakdown: some View {
        let stats = appState.categoryStats(for: selectedRange)
        return VStack(alignment: .leading, spacing: 14) {
            Text("По категориям")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            if stats.isEmpty {
                Text("Нет данных за выбранный период")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(stats) { stat in
                    HStack(spacing: 12) {
                        Image(systemName: stat.category.icon)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(stat.category.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Text("\(stat.completed)/\(stat.count)")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color(UIColor.separator)).frame(height: 4)
                                    Capsule().fill(.primary)
                                        .frame(width: geo.size.width * stat.percentage, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var priorityBreakdown: some View {
        let stats = appState.priorityDistribution(for: selectedRange)
        return VStack(alignment: .leading, spacing: 14) {
            Text("По приоритету")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            HStack(spacing: 16) {
                ForEach(stats) { stat in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().stroke(.separator, lineWidth: 4)
                                .frame(width: 50, height: 50)
                            Circle().trim(from: 0, to: stat.percentage)
                                .stroke(stat.priority.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            Text("\(stat.count)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        Text(stat.priority.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var habitsAnalytics: some View {
        if !appState.habits.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Привычки")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                ForEach(appState.habits) { habit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: habit.icon)
                                .font(.system(size: 16))
                                .frame(width: 30, height: 30)
                                .background(.secondary.opacity(0.1), in: Circle())
                            Text(habit.title)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text("\(habit.currentStreak) дн.")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        StreakCalendarView(completedDates: habit.completedDates, days: 21)
                    }
                    .padding(.vertical, 4)
                    if habit.id != appState.habits.last?.id {
                        Divider()
                    }
                }
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private var goalsProgress: some View {
        if !appState.goals.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("Прогресс целей")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                ForEach(appState.goals) { goal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: goal.category.icon)
                                .font(.system(size: 14))
                            Text(goal.title)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(goal.progress * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        ProgressView(value: goal.progress)
                            .tint(.primary)
                        HStack(spacing: 12) {
                            Label("\(goal.streakDays) дн.", systemImage: "flame.fill")
                            Label("\(goal.completedDays.count) отмечено", systemImage: "checkmark")
                            Label("\(goal.daysRemaining) осталось", systemImage: "clock")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    if goal.id != appState.goals.last?.id {
                        Divider()
                    }
                }
            }
            .cardStyle()
        }
    }

    private var moodTracker: some View {
        let entries = appState.journal.suffix(7)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Настроение")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            if entries.isEmpty {
                Text("Ведите журнал для отслеживания настроения")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(entries)) { entry in
                        VStack(spacing: 6) {
                            Image(systemName: entry.mood.icon)
                                .font(.system(size: 18))
                            Text("\(entry.mood.score)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Text(shortRuDate(entry.date))
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var streakHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Серия дней")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(appState.streak) дн.")
                    .font(.system(size: 20, weight: .black, design: .rounded))
            }

            HStack(spacing: 4) {
                ForEach(0..<30, id: \.self) { offset in
                    let cal = Calendar.current
                    let date = cal.date(byAdding: .day, value: -(29 - offset), to: Date()) ?? Date()
                    let tasks = appState.tasksForDate(date)
                    let allDone = !tasks.isEmpty && tasks.allSatisfy { $0.isCompleted }
                    let hasTasks = !tasks.isEmpty

                    RoundedRectangle(cornerRadius: 2)
                        .fill(allDone ? Color.primary : (hasTasks ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.08)))
                        .frame(height: 14)
                }
            }

            HStack {
                Text("30 дней назад")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Сегодня")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .cardStyle()
    }

    private var timeSpentCard: some View {
        let totalSeconds = appState.tasks.reduce(0) { $0 + $1.timeSpentSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        return VStack(alignment: .leading, spacing: 14) {
            Text("Время в фокусе")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(hours)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("часов")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    Text("\(minutes)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("минут")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ProgressRing(
                    progress: min(Double(totalSeconds) / 36000.0, 1.0),
                    size: 64
                )
            }

            if totalSeconds > 0 {
                let topTasks = appState.tasks.filter { $0.timeSpentSeconds > 0 }.sorted { $0.timeSpentSeconds > $1.timeSpentSeconds }.prefix(3)
                if !topTasks.isEmpty {
                    Divider()
                    Text("Топ по времени").font(.caption).foregroundStyle(.secondary)
                    ForEach(Array(topTasks)) { task in
                        HStack(spacing: 8) {
                            Image(systemName: task.category.icon).font(.system(size: 12))
                            Text(task.title).font(.system(size: 13)).lineLimit(1)
                            Spacer()
                            Text(formatTimeHMS(task.timeSpentSeconds))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private var achievementsGrid: some View {
        let achvs = appState.achievements()
        let unlocked = achvs.filter { $0.isUnlocked }.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Достижения")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(unlocked)/\(achvs.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(achvs) { ach in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(ach.isUnlocked ? Color.primary.opacity(0.08) : Color.secondary.opacity(0.04))
                                .frame(width: 50, height: 50)
                            Circle()
                                .trim(from: 0, to: ach.progress)
                                .stroke(.primary.opacity(ach.isUnlocked ? 1 : 0.2),
                                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            Image(systemName: ach.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(ach.isUnlocked ? .primary : .tertiary)
                        }
                        Text(ach.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(ach.isUnlocked ? .primary : .tertiary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var exportSheet: some View {
        NavigationStack {
            List {
                Section("Формат экспорта") {
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            withAnimation { selectedExportFormat = format }
                        } label: {
                            HStack {
                                Text(format.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedExportFormat == format {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        let text = appState.exportData(format: selectedExportFormat)
                        UIPasteboard.general.string = text
                        showExport = false
                    } label: {
                        Label("Копировать в буфер", systemImage: "doc.on.clipboard")
                    }

                    ShareLink(
                        item: appState.exportData(format: selectedExportFormat),
                        subject: Text("TaskFlow — Экспорт"),
                        message: Text("Данные из приложения TaskFlow")
                    ) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Информация") {
                    Label("Задач: \(appState.tasks.count)", systemImage: "checklist")
                    Label("Целей: \(appState.goals.count)", systemImage: "target")
                    Label("Привычек: \(appState.habits.count)", systemImage: "repeat.circle.fill")
                    Label("Записей журнала: \(appState.journal.count)", systemImage: "book")
                    Label("Заметок: \(appState.notes.count)", systemImage: "note.text")
                }
            }
            .navigationTitle("Экспорт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { showExport = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
