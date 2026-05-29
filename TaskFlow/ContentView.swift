import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(0)

            TasksTabView()
                .tabItem {
                    Label("Задачи", systemImage: "checklist")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .tint(.primary)
    }
}

// MARK: - Combined Tasks Tab (Tasks + Calendar + Goals)
struct TasksTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSegment = 0
    @State private var showCreateTask = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Picker
                Picker("Раздел", selection: $selectedSegment) {
                    Text("Задачи").tag(0)
                    Text("Календарь").tag(1)
                    Text("Цели").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassBackground()

                // Content
                Group {
                    switch selectedSegment {
                    case 0:
                        TasksViewContent()
                    case 1:
                        CalendarView()
                    case 2:
                        GoalsView()
                    default:
                        TasksViewContent()
                    }
                }
            }
            .navigationTitle("Задачи")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView().environmentObject(appState)
            }
        }
    }
}

// MARK: - Tasks List Content (extracted from TasksView for embedding)
struct TasksViewContent: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: TaskCategory? = nil
    @State private var searchText = ""
    @State private var sortMode: TasksView.SortMode = .dateDesc
    @State private var selectedTask: TaskItem? = nil

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
        case .priorityHigh: result.sort { TasksView.priorityWeightStatic($0.priority) > TasksView.priorityWeightStatic($1.priority) }
        case .category: result.sort { $0.category.rawValue < $1.category.rawValue }
        }
        return result
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Category chips
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
                    .padding(.horizontal, 16)
                }

                // Sort menu
                HStack {
                    Menu {
                        ForEach(TasksView.SortMode.allCases, id: \.self) { mode in
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
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12))
                            Text(sortMode.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(filtered.count) задач")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)

                if filtered.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundStyle(.tertiary)
                        Text("Задачи не найдены")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text("Измените фильтры или создайте новую задачу")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(filtered) { task in
                        Button { selectedTask = task } label: {
                            taskRowContent(task)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .searchable(text: $searchText, prompt: "Поиск задач")
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task).environmentObject(appState)
        }
    }

    private func taskRowContent(_ task: TaskItem) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { appState.toggleTask(task) }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
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
        .padding(14)
        .glassCardStyle()
        .padding(.horizontal, 16)
    }

    private func chipButton(_ title: String, icon: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11))
                }
                Text(title).font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassPillStyle(isSelected: selected)
        }
    }
}
