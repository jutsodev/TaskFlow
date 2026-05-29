import SwiftUI

struct TaskEditView: View {
    let task: TaskItem
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var title: String
    @State private var description: String
    @State private var notes: String
    @State private var steps: [TaskStep]
    @State private var newStepTitle = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndDate: Bool
    @State private var priority: Priority
    @State private var category: TaskCategory
    @State private var repeatMode: RepeatMode

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _notes = State(initialValue: task.notes)
        _steps = State(initialValue: task.steps)
        _startDate = State(initialValue: task.startDate)
        _endDate = State(initialValue: task.endDate ?? Date())
        _hasEndDate = State(initialValue: task.endDate != nil)
        _priority = State(initialValue: task.priority)
        _category = State(initialValue: task.category)
        _repeatMode = State(initialValue: task.repeatMode)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Основное") {
                    TextField("Название", text: $title)
                        .font(.system(size: 17, weight: .medium))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Описание").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $description)
                            .font(.system(size: 15))
                            .frame(minHeight: 80)
                    }
                }

                Section("Этапы (\(steps.filter { $0.isCompleted }.count)/\(steps.count))") {
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Button {
                                withAnimation { steps[i].isCompleted.toggle() }
                            } label: {
                                Image(systemName: steps[i].isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(steps[i].isCompleted ? .secondary : .primary)
                            }
                            .buttonStyle(.plain)
                            TextField("Шаг \(i + 1)", text: $steps[i].title)
                                .font(.system(size: 15))
                                .strikethrough(steps[i].isCompleted)
                        }
                    }
                    .onDelete { indexSet in
                        steps.remove(atOffsets: indexSet)
                    }
                    .onMove { source, dest in
                        steps.move(fromOffsets: source, toOffset: dest)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle").foregroundStyle(.secondary)
                        TextField("Добавить шаг", text: $newStepTitle)
                            .font(.system(size: 15))
                            .onSubmit {
                                if !newStepTitle.isEmpty {
                                    steps.append(TaskStep(title: newStepTitle))
                                    newStepTitle = ""
                                }
                            }
                    }

                    if !steps.isEmpty {
                        ProgressView(value: Double(steps.filter { $0.isCompleted }.count), total: Double(steps.count))
                            .tint(.primary)
                    }
                }

                Section("Даты") {
                    DatePicker("Начало", selection: $startDate, displayedComponents: .date)
                        .tint(.primary)
                    Toggle("Дата окончания", isOn: $hasEndDate.animation())
                        .tint(.primary)
                    if hasEndDate {
                        DatePicker("Окончание", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .tint(.primary)
                    }
                }

                Section("Приоритет") {
                    Picker("Приоритет", selection: $priority) {
                        ForEach(Priority.allCases) { p in
                            HStack {
                                Image(systemName: p.icon)
                                Text(p.rawValue)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Категория") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(TaskCategory.allCases) { cat in
                            Button {
                                withAnimation { category = cat }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.icon).font(.system(size: 12))
                                    Text(cat.rawValue).font(.system(size: 13, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    category == cat ? AnyShapeStyle(Color.primary.opacity(0.1)) : AnyShapeStyle(Color.clear),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(category == cat ? .primary : .separator, lineWidth: 1)
                                )
                                .foregroundStyle(category == cat ? .primary : .secondary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Повтор") {
                    ForEach(RepeatMode.allCases) { mode in
                        Button {
                            withAnimation { repeatMode = mode }
                        } label: {
                            HStack {
                                Text(mode.rawValue).foregroundStyle(.primary)
                                Spacer()
                                if repeatMode == mode {
                                    Image(systemName: "checkmark").font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                }

                Section("Заметки") {
                    TextEditor(text: $notes)
                        .font(.system(size: 15))
                        .frame(minHeight: 60)
                }

                if task.timeSpentSeconds > 0 {
                    Section("Время") {
                        Label("Затрачено: \(formatTimeHMS(task.timeSpentSeconds))", systemImage: "clock")
                    }
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty)
                }
            }
            .environment(\.editMode, .constant(.active))
        }
        .presentationDragIndicator(.visible)
    }

    private func save() {
        var updated = task
        updated.title = title
        updated.description = description
        updated.notes = notes
        updated.steps = steps
        updated.startDate = startDate
        updated.endDate = hasEndDate ? endDate : nil
        updated.priority = priority
        updated.category = category
        updated.repeatMode = repeatMode
        updated.isCompleted = !steps.isEmpty ? steps.allSatisfy { $0.isCompleted } : updated.isCompleted
        appState.updateTask(updated)
        dismiss()
    }
}

struct TasksBatchView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTasks: Set<UUID> = []
    @State private var isSelecting = false
    @State private var showBatchActions = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.tasks) { task in
                    HStack(spacing: 12) {
                        if isSelecting {
                            Image(systemName: selectedTasks.contains(task.id) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedTasks.contains(task.id) ? .primary : .secondary)
                                .onTapGesture {
                                    if selectedTasks.contains(task.id) {
                                        selectedTasks.remove(task.id)
                                    } else {
                                        selectedTasks.insert(task.id)
                                    }
                                }
                        }

                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 14, weight: .medium))
                                .strikethrough(task.isCompleted)
                            HStack(spacing: 6) {
                                Label(task.category.rawValue, systemImage: task.category.icon)
                                Label(task.priority.rawValue, systemImage: task.priority.icon)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            if selectedTasks.contains(task.id) {
                                selectedTasks.remove(task.id)
                            } else {
                                selectedTasks.insert(task.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Управление задачами")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSelecting ? "Готово" : "Выбрать") {
                        isSelecting.toggle()
                        if !isSelecting { selectedTasks.removeAll() }
                    }
                }
                if isSelecting && !selectedTasks.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Button {
                                for id in selectedTasks {
                                    if let task = appState.tasks.first(where: { $0.id == id }) {
                                        appState.toggleTask(task)
                                    }
                                }
                                selectedTasks.removeAll()
                            } label: {
                                Label("Выполнить", systemImage: "checkmark")
                            }

                            Spacer()

                            Text("\(selectedTasks.count) выбрано")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button(role: .destructive) {
                                for id in selectedTasks {
                                    if let task = appState.tasks.first(where: { $0.id == id }) {
                                        appState.deleteTask(task)
                                    }
                                }
                                selectedTasks.removeAll()
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DailyPlannerView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var showCreateTask = false
    @State private var showTemplates = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    dateSelector
                    dayOverview
                    timelineSection
                    quickActions
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Планировщик")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button { showTemplates = true } label: {
                            Image(systemName: "doc.on.doc")
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
            .sheet(isPresented: $showTemplates) {
                TaskTemplatesView().environmentObject(appState)
            }
        }
    }

    private var dateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(-3..<4, id: \.self) { offset in
                    let cal = Calendar.current
                    let date = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: Date())) ?? Date()
                    let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
                    let isToday = offset == 0

                    Button {
                        withAnimation { selectedDate = date }
                    } label: {
                        VStack(spacing: 6) {
                            Text(dayOfWeek(date))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isSelected ? Color(.systemBackground) : .secondary)
                            Text("\(cal.component(.day, from: date))")
                                .font(.system(size: 18, weight: isToday ? .bold : .regular, design: .rounded))
                                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                            let tasks = appState.tasksForDate(date)
                            let done = tasks.filter { $0.isCompleted }.count
                            if !tasks.isEmpty {
                                Text("\(done)/\(tasks.count)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(isSelected ? Color(.systemBackground).opacity(0.7) : .tertiary)
                            }
                        }
                        .frame(width: 48)
                        .padding(.vertical, 10)
                        .background(
                            isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.clear),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(
                            isToday && !isSelected
                            ? RoundedRectangle(cornerRadius: 14).stroke(.primary, lineWidth: 1)
                            : nil
                        )
                    }
                }
            }
        }
    }

    private func dayOfWeek(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "EE"
        return fmt.string(from: date).uppercased()
    }

    private var dayOverview: some View {
        let tasks = appState.tasksForDate(selectedDate)
        let completed = tasks.filter { $0.isCompleted }.count
        let total = tasks.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0

        return HStack(spacing: 16) {
            ProgressRing(progress: progress, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text(Calendar.current.isDateInToday(selectedDate) ? "Сегодня" : formattedRuDate(selectedDate))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("\(completed) из \(total) задач выполнено")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var timelineSection: some View {
        let tasks = appState.tasksForDate(selectedDate).sorted { $0.startDate < $1.startDate }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Задачи")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            if tasks.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "Нет задач",
                    subtitle: "Добавьте задачи или используйте шаблон",
                    actionTitle: "Шаблоны",
                    action: { showTemplates = true }
                )
            } else {
                ForEach(tasks) { task in
                    HStack(spacing: 14) {
                        VStack {
                            Circle()
                                .fill(task.isCompleted ? Color.primary : Color.separator)
                                .frame(width: 10, height: 10)
                            if task.id != tasks.last?.id {
                                Rectangle()
                                    .fill(.separator)
                                    .frame(width: 1)
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    appState.toggleTask(task)
                                }
                            } label: {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(task.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .strikethrough(task.isCompleted)
                                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                HStack(spacing: 6) {
                                    Image(systemName: task.category.icon).font(.system(size: 9))
                                    Text(task.category.rawValue).font(.caption2)
                                    if !task.steps.isEmpty {
                                        Text("· \(task.steps.filter { $0.isCompleted }.count)/\(task.steps.count)")
                                            .font(.caption2)
                                    }
                                }
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: task.priority.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(task.priority.color)
                        }
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Быстрые действия")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                quickAction("checklist", "Новая задача") { showCreateTask = true }
                quickAction("doc.on.doc", "Из шаблона") { showTemplates = true }
                quickAction("checkmark.circle", "Завершить все") {
                    let tasks = appState.tasksForDate(selectedDate).filter { !$0.isCompleted }
                    for task in tasks { appState.toggleTask(task) }
                }
                quickAction("arrow.uturn.backward", "Сбросить день") {
                    let tasks = appState.tasksForDate(selectedDate).filter { $0.isCompleted }
                    for task in tasks { appState.toggleTask(task) }
                }
            }
        }
    }

    private func quickAction(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14))
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
        }
    }
}

struct HabitStreakView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if appState.habits.isEmpty {
                    EmptyStateView(icon: "repeat.circle.fill", title: "Нет привычек", subtitle: "Создайте привычки для отслеживания серий")
                } else {
                    overallStats
                    ForEach(appState.habits) { habit in
                        habitStreakCard(habit)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Серии привычек")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overallStats: some View {
        let totalStreak = appState.habits.map { $0.currentStreak }.max() ?? 0
        let totalCompleted = appState.habits.reduce(0) { $0 + $1.totalCompleted }
        let avgRate: Int = {
            guard !appState.habits.isEmpty else { return 0 }
            let days = max(1, Calendar.current.dateComponents([.day], from: appState.habits.map { $0.createdAt }.min() ?? Date(), to: Date()).day ?? 1)
            return Int(Double(totalCompleted) / Double(days * appState.habits.count) * 100)
        }()

        return HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(totalStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Макс. серия").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()

            VStack(spacing: 4) {
                Text("\(totalCompleted)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Всего отметок").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()

            VStack(spacing: 4) {
                Text("\(avgRate)%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Средний %").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
    }

    private func habitStreakCard(_ habit: HabitItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: habit.icon)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(.secondary.opacity(0.1), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title).font(.system(size: 15, weight: .semibold))
                    Text("Создано: \(shortRuDate(habit.createdAt))").font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 12))
                        Text("\(habit.currentStreak)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    Text("дней").font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 4) {
                Text("Последние 7 дней:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                let cal = Calendar.current
                let fmt = DateFormatter()
                let _ = fmt.dateFormat = "yyyy-MM-dd"
                ForEach(0..<7, id: \.self) { offset in
                    let date = cal.date(byAdding: .day, value: -(6 - offset), to: Date()) ?? Date()
                    let done = habit.completedDates.contains(fmt.string(from: date))
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(done ? .primary : .separator)
                }
            }

            StreakCalendarView(completedDates: habit.completedDates)

            HStack(spacing: 16) {
                Label("\(habit.totalCompleted) всего", systemImage: "checkmark")
                let days = max(1, Calendar.current.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 1)
                let rate = Int(Double(habit.totalCompleted) / Double(days) * 100)
                Label("\(rate)% успешность", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

struct GoalTimelineView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if appState.goals.isEmpty {
                    EmptyStateView(icon: "target", title: "Нет целей", subtitle: "Создайте цель для отслеживания прогресса")
                } else {
                    ForEach(appState.goals) { goal in
                        goalTimelineCard(goal)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Хронология целей")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func goalTimelineCard(_ goal: YearGoal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 20))
                    .frame(width: 42, height: 42)
                    .background(.secondary.opacity(0.1), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title).font(.system(size: 16, weight: .semibold))
                    Text(goal.category.rawValue).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                ProgressRing(progress: goal.progress, size: 44, lineWidth: 4)
            }

            HStack(spacing: 0) {
                let total = max(goal.totalDays, 1)
                let elapsed = total - goal.daysRemaining
                let ratio = min(Double(elapsed) / Double(total), 1.0)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.separator).frame(height: 8)
                        Capsule().fill(.primary).frame(width: geo.size.width * ratio, height: 8)
                        Circle()
                            .fill(.primary)
                            .frame(width: 14, height: 14)
                            .offset(x: max(0, geo.size.width * ratio - 7))
                    }
                }
                .frame(height: 14)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Начало").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Text(shortRuDate(goal.startDate)).font(.system(size: 11, weight: .medium))
                }
                Spacer()
                VStack {
                    Text("Сегодня").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Text(shortRuDate(Date())).font(.system(size: 11, weight: .medium))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Цель").font(.system(size: 10)).foregroundStyle(.tertiary)
                    Text(shortRuDate(goal.targetDate)).font(.system(size: 11, weight: .medium))
                }
            }

            if !goal.milestones.isEmpty {
                Divider()
                Text("Вехи").font(.caption).foregroundStyle(.secondary)
                ForEach(goal.milestones) { ms in
                    HStack(spacing: 8) {
                        Image(systemName: ms.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(ms.isCompleted ? .secondary : .primary)
                        Text(ms.title).font(.system(size: 13)).lineLimit(1)
                            .strikethrough(ms.isCompleted)
                        Spacer()
                        Text(shortRuDate(ms.targetDate)).font(.system(size: 10)).foregroundStyle(.tertiary)
                    }
                }
            }

            HStack(spacing: 12) {
                Label("\(goal.streakDays) серия", systemImage: "flame.fill")
                Label("\(goal.completedDays.count) дней", systemImage: "checkmark")
                Label("\(goal.daysRemaining) ост.", systemImage: "clock")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}
