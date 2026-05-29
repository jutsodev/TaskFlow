import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var selectedTask: TaskItem? = nil
    @State private var selectedGoal: YearGoal? = nil
    @State private var selectedNote: NoteItem? = nil

    enum SearchCategory: String, CaseIterable, Identifiable {
        case all = "Всё"
        case tasks = "Задачи"
        case goals = "Цели"
        case habits = "Привычки"
        case notes = "Заметки"
        case journal = "Журнал"
        var id: String { rawValue }
    }

    private var results: (tasks: [TaskItem], goals: [YearGoal], habits: [HabitItem], notes: [NoteItem], journal: [JournalEntry]) {
        guard !searchText.isEmpty else { return ([], [], [], [], []) }
        let q = searchText.lowercased()

        let tasks = (selectedCategory == .all || selectedCategory == .tasks)
            ? appState.tasks.filter { $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) || $0.notes.lowercased().contains(q) }
            : []

        let goals = (selectedCategory == .all || selectedCategory == .goals)
            ? appState.goals.filter { $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) || $0.dailyAction.lowercased().contains(q) }
            : []

        let habits = (selectedCategory == .all || selectedCategory == .habits)
            ? appState.habits.filter { $0.title.lowercased().contains(q) }
            : []

        let notes = (selectedCategory == .all || selectedCategory == .notes)
            ? appState.notes.filter { $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q) || $0.tags.contains { $0.lowercased().contains(q) } }
            : []

        let journal = (selectedCategory == .all || selectedCategory == .journal)
            ? appState.journal.filter { $0.text.lowercased().contains(q) || $0.gratitude.contains { $0.lowercased().contains(q) } }
            : []

        return (tasks, goals, habits, notes, journal)
    }

    private var totalResults: Int {
        results.tasks.count + results.goals.count + results.habits.count + results.notes.count + results.journal.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchCategory.allCases) { cat in
                            Button {
                                withAnimation { selectedCategory = cat }
                            } label: {
                                Text(cat.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedCategory == cat ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.clear),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedCategory == cat ? Color(.systemBackground) : .primary)
                                    .overlay(Capsule().stroke(.separator, lineWidth: selectedCategory == cat ? 0 : 1))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundStyle(.tertiary)
                        Text("Глобальный поиск")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Text("Ищите по задачам, целям, привычкам, заметкам и журналу")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else if totalResults == 0 {
                    ContentUnavailableView(
                        "Ничего не найдено",
                        systemImage: "magnifyingglass",
                        description: Text("Попробуйте другой запрос")
                    )
                } else {
                    List {
                        if !results.tasks.isEmpty {
                            Section("Задачи (\(results.tasks.count))") {
                                ForEach(results.tasks) { task in
                                    Button { selectedTask = task } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(task.title)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(.primary)
                                                    .strikethrough(task.isCompleted)
                                                Label(task.category.rawValue, systemImage: task.category.icon)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !results.goals.isEmpty {
                            Section("Цели (\(results.goals.count))") {
                                ForEach(results.goals) { goal in
                                    Button { selectedGoal = goal } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: goal.category.icon)
                                                .frame(width: 28, height: 28)
                                                .background(.secondary.opacity(0.1), in: Circle())
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(goal.title)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(.primary)
                                                Text("\(Int(goal.progress * 100))% — \(goal.daysRemaining) дн.")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            ProgressRing(progress: goal.progress, size: 28, lineWidth: 3)
                                        }
                                    }
                                }
                            }
                        }

                        if !results.habits.isEmpty {
                            Section("Привычки (\(results.habits.count))") {
                                ForEach(results.habits) { habit in
                                    HStack(spacing: 12) {
                                        Image(systemName: habit.icon)
                                            .frame(width: 28, height: 28)
                                            .background(.secondary.opacity(0.1), in: Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(habit.title).font(.system(size: 14, weight: .medium))
                                            Text("Серия: \(habit.currentStreak) дн.").font(.caption2).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if habit.isCompletedToday() {
                                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }

                        if !results.notes.isEmpty {
                            Section("Заметки (\(results.notes.count))") {
                                ForEach(results.notes) { note in
                                    Button { selectedNote = note } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                if note.isPinned {
                                                    Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(.secondary)
                                                }
                                                Text(note.title.isEmpty ? "Без названия" : note.title)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundStyle(.primary)
                                            }
                                            if !note.content.isEmpty {
                                                Text(note.content)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !results.journal.isEmpty {
                            Section("Журнал (\(results.journal.count))") {
                                ForEach(results.journal) { entry in
                                    HStack(spacing: 12) {
                                        Image(systemName: entry.mood.icon).font(.system(size: 18))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(formattedRuDate(entry.date))
                                                .font(.system(size: 14, weight: .medium))
                                            Text(entry.text.prefix(60) + (entry.text.count > 60 ? "..." : ""))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Искать везде...")
            .navigationTitle("Поиск")
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task).environmentObject(appState)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailSheet(goal: goal).environmentObject(appState)
            }
            .sheet(item: $selectedNote) { note in
                NoteEditorView(mode: .edit(note)).environmentObject(appState)
            }
        }
    }
}
