import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Colorful ambient background (so glass is visible!)
            AmbientBackground()

            VStack(spacing: 0) {
                // Main content
                Group {
                    switch selectedTab {
                    case 0: HomeView()
                    case 1: TasksTabView()
                    case 2: ProfileView()
                    default: HomeView()
                    }
                }

                // Custom Glass Tab Bar
                GlassTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Custom Glass Tab Bar
struct GlassTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill", title: "Главная", tag: 0)
            tabItem(icon: "checklist", title: "Задачи", tag: 1)
            tabItem(icon: "person.crop.circle.fill", title: "Профиль", tag: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            ZStack {
                // Thick glass for tab bar
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)

                // Top highlight
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.12), location: 0.0),
                                .init(color: Color.clear, location: 0.3),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Top border (the "liquid" edge)
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.35), location: 0.0),
                            .init(color: Color.white.opacity(0.08), location: 1.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 0.5)
                    Spacer()
                }

                // Specular highlight streak
                LinearGradient(
                    stops: [
                        .init(color: Color.clear, location: 0.0),
                        .init(color: Color.white.opacity(0.15), location: 0.2),
                        .init(color: Color.white.opacity(0.03), location: 0.4),
                        .init(color: Color.clear, location: 0.6),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -3)
    }

    private func tabItem(icon: String, title: String, tag: Int) -> some View {
        let isSelected = selectedTab == tag
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: selectedTab)

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    }
                }
            )
        }
        .buttonStyle(.plain)
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView().environmentObject(appState)
            }
        }
    }
}

// MARK: - Tasks List Content
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
                        .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Text("\(filtered.count) задач")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 16)

                if filtered.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("Задачи не найдены")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Измените фильтры или создайте новую задачу")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
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
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.3) : .white)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.4) : .white)

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
                .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: task.priority.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(task.priority.color)
                Text(shortRuDate(task.startDate))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
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
