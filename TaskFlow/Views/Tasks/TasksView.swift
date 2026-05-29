import SwiftUI

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateTask = false
    @State private var selectedCategory: TaskCategory? = nil
    @State private var searchText = ""
    @State private var sortMode: SortMode = .dateDesc
    @State private var selectedTask: TaskItem? = nil

    enum SortMode: String, CaseIterable {
        case dateDesc = "Новые"
        case dateAsc = "Старые"
        case priorityHigh = "Важные"
        case category = "Категория"
    }

    private var filtered: [TaskItem] {
        var result = appState.tasks
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortMode {
        case .dateDesc: result.sort { $0.startDate > $1.startDate }
        case .dateAsc: result.sort { $0.startDate < $1.startDate }
        case .priorityHigh: result.sort { Self.priorityWeightStatic($0.priority) > Self.priorityWeightStatic($1.priority) }
        case .category: result.sort { $0.category.rawValue < $1.category.rawValue }
        }
        return result
    }

    static func priorityWeightStatic(_ p: Priority) -> Int {
        switch p { case .high: return 3; case .medium: return 2; case .low: return 1 }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chipButton("Все", selected: selectedCategory == nil) {
                                withAnimation { selectedCategory = nil }
                            }
                            ForEach(TaskCategory.allCases) { cat in
                                chipButton(cat.rawValue, icon: cat.icon, selected: selectedCategory == cat) {
                                    withAnimation { selectedCategory = cat }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if filtered.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Задачи не найдены",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Попробуйте изменить фильтры или создайте новую задачу")
                        )
                    }
                } else {
                    Section("\(filtered.count) задач") {
                        ForEach(filtered) { task in
                            Button { selectedTask = task } label: {
                                taskRowContent(task)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation { appState.deleteTask(task) }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation { appState.toggleTask(task) }
                                } label: {
                                    Label(
                                        task.isCompleted ? "Отменить" : "Выполнить",
                                        systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                    )
                                }
                                .tint(task.isCompleted ? .orange : .green)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Поиск задач")
            .navigationTitle("Задачи")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(SortMode.allCases, id: \.self) { mode in
                                Button {
                                    sortMode = mode
                                } label: {
                                    HStack {
                                        Text(mode.rawValue)
                                        if sortMode == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
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
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task).environmentObject(appState)
            }
        }
    }

    private func taskRowContent(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { appState.toggleTask(task) }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(task.category.rawValue, systemImage: task.category.icon)
                    if task.timeSpentSeconds > 0 {
                        Label(formatTimeHMS(task.timeSpentSeconds), systemImage: "clock")
                    }
                    if task.repeatMode != .none {
                        Image(systemName: "repeat")
                    }
                    if !task.steps.isEmpty {
                        Label("\(task.steps.filter { $0.isCompleted }.count)/\(task.steps.count)", systemImage: "list.bullet")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: task.priority.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(task.priority.color)
                Text(shortRuDate(task.startDate))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func chipButton(_ title: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11))
                }
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassPillStyle(isSelected: selected)
        }
    }
}

struct TaskDetailSheet: View {
    let task: TaskItem
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(task.isCompleted ? .green : .primary)
                        Text(task.isCompleted ? "Выполнено" : "В процессе")
                            .font(.subheadline)
                    }
                }

                if !task.description.isEmpty {
                    Section("Описание") {
                        Text(task.description)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                }

                if !task.notes.isEmpty {
                    Section("Заметки") {
                        Text(task.notes)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                }

                if !task.steps.isEmpty {
                    Section("Этапы (\(task.steps.filter { $0.isCompleted }.count)/\(task.steps.count))") {
                        ForEach(task.steps) { step in
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation {
                                        appState.toggleStep(taskId: task.id, stepId: step.id)
                                    }
                                } label: {
                                    Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(step.isCompleted ? .secondary : .primary)
                                }
                                .buttonStyle(.plain)

                                Text(step.title)
                                    .font(.system(size: 15))
                                    .strikethrough(step.isCompleted)
                                    .foregroundStyle(step.isCompleted ? .secondary : .primary)
                            }
                        }

                        if !task.steps.isEmpty {
                            ProgressView(
                                value: Double(task.steps.filter { $0.isCompleted }.count),
                                total: Double(task.steps.count)
                            )
                            .tint(.primary)
                        }
                    }
                }

                Section("Информация") {
                    Label(task.category.rawValue, systemImage: task.category.icon)
                    HStack {
                        Label(task.priority.rawValue, systemImage: task.priority.icon)
                        Spacer()
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 10, height: 10)
                    }
                    Label("Начало: \(formattedRuDate(task.startDate))", systemImage: "calendar")
                    if let end = task.endDate {
                        Label("Окончание: \(formattedRuDate(end))", systemImage: "calendar.badge.checkmark")
                    }
                    if task.timeSpentSeconds > 0 {
                        Label("Затрачено: \(formatTimeHMS(task.timeSpentSeconds))", systemImage: "clock")
                    }
                    if task.repeatMode != .none {
                        Label(task.repeatMode.rawValue, systemImage: "repeat")
                    }
                }

                Section {
                    Button {
                        withAnimation { appState.toggleTask(task) }
                        dismiss()
                    } label: {
                        Label(
                            task.isCompleted ? "Отметить как невыполненное" : "Отметить как выполненное",
                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                        )
                    }

                    Button(role: .destructive) {
                        appState.deleteTask(task)
                        dismiss()
                    } label: {
                        Label("Удалить задачу", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
