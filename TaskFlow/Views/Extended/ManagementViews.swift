import SwiftUI

struct FocusSessionsView: View {
    @EnvironmentObject var appState: AppState

    struct FocusSession: Identifiable {
        let id = UUID()
        let taskTitle: String
        let category: TaskCategory
        let seconds: Int
        let date: Date
    }

    private var sessions: [FocusSession] {
        appState.tasks.filter { $0.timeSpentSeconds > 0 }.map {
            FocusSession(taskTitle: $0.title, category: $0.category, seconds: $0.timeSpentSeconds, date: $0.startDate)
        }.sorted { $0.seconds > $1.seconds }
    }

    private var totalSeconds: Int { sessions.reduce(0) { $0 + $1.seconds } }
    private var totalHours: Double { Double(totalSeconds) / 3600.0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                overviewCard
                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "timer",
                        title: "Нет сессий фокусировки",
                        subtitle: "Используйте таймер для отслеживания времени работы"
                    )
                } else {
                    categoryTimeBreakdown
                    topSessions
                    allSessions
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Сессии фокусировки")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                Text(String(format: "%.1f", totalHours))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("часов всего")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 60)

            VStack(spacing: 6) {
                Text("\(sessions.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("сессий")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 60)

            VStack(spacing: 6) {
                let avg = sessions.isEmpty ? 0 : totalSeconds / sessions.count
                Text(formatTimeHMS(avg))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("среднее")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
    }

    private var categoryTimeBreakdown: some View {
        let grouped = Dictionary(grouping: sessions, by: { $0.category })
        let sorted = grouped.sorted { $0.value.reduce(0) { $0 + $1.seconds } > $1.value.reduce(0) { $0 + $1.seconds } }

        return VStack(alignment: .leading, spacing: 14) {
            Text("По категориям")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            ForEach(sorted, id: \.key) { cat, items in
                let catTotal = items.reduce(0) { $0 + $1.seconds }
                let pct = totalSeconds > 0 ? Double(catTotal) / Double(totalSeconds) : 0

                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 14))
                        .frame(width: 28, height: 28)
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cat.rawValue)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(formatTimeHMS(catTotal))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(UIColor.separator)).frame(height: 4)
                                Capsule().fill(.primary).frame(width: geo.size.width * pct, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var topSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Топ по времени")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            ForEach(sessions.prefix(5)) { session in
                HStack(spacing: 12) {
                    Image(systemName: session.category.icon)
                        .font(.system(size: 14))
                        .frame(width: 28, height: 28)
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.taskTitle)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        Text(shortRuDate(session.date))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Text(formatTimeHMS(session.seconds))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                if session.id != sessions.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var allSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Все сессии (\(sessions.count))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            ForEach(sessions) { session in
                HStack(spacing: 10) {
                    Image(systemName: session.category.icon)
                        .font(.system(size: 12))
                        .frame(width: 22, height: 22)
                        .background(.secondary.opacity(0.08), in: Circle())
                    Text(session.taskTitle)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Spacer()
                    Text(formatTimeHMS(session.seconds))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }
}

struct DataManagementView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFormat: ExportFormat = .json
    @State private var showExportResult = false
    @State private var exportResult = ""
    @State private var showDeleteConfirm = false
    @State private var deleteTarget = ""

    var body: some View {
        List {
            Section("Обзор данных") {
                dataRow("Задачи", count: appState.tasks.count, icon: "checklist")
                dataRow("Цели", count: appState.goals.count, icon: "target")
                dataRow("Привычки", count: appState.habits.count, icon: "repeat.circle.fill")
                dataRow("Журнал", count: appState.journal.count, icon: "book.fill")
                dataRow("Заметки", count: appState.notes.count, icon: "note.text")
            }

            Section("Экспорт") {
                Picker("Формат", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    exportResult = appState.exportData(format: selectedFormat)
                    showExportResult = true
                } label: {
                    Label("Экспортировать", systemImage: "square.and.arrow.up")
                }

                ShareLink(
                    item: appState.exportData(format: selectedFormat),
                    subject: Text("TaskFlow Export"),
                    message: Text("Экспорт данных из TaskFlow")
                ) {
                    Label("Поделиться файлом", systemImage: "arrow.up.doc")
                }
            }

            Section("Управление") {
                Button {
                    deleteTarget = "tasks"
                    showDeleteConfirm = true
                } label: {
                    Label("Удалить все задачи (\(appState.tasks.count))", systemImage: "trash")
                        .foregroundStyle(appState.tasks.isEmpty ? Color(UIColor.tertiaryLabel) : .red)
                }
                .disabled(appState.tasks.isEmpty)

                Button {
                    deleteTarget = "goals"
                    showDeleteConfirm = true
                } label: {
                    Label("Удалить все цели (\(appState.goals.count))", systemImage: "trash")
                        .foregroundStyle(appState.goals.isEmpty ? Color(UIColor.tertiaryLabel) : .red)
                }
                .disabled(appState.goals.isEmpty)

                Button {
                    deleteTarget = "habits"
                    showDeleteConfirm = true
                } label: {
                    Label("Удалить все привычки (\(appState.habits.count))", systemImage: "trash")
                        .foregroundStyle(appState.habits.isEmpty ? Color(UIColor.tertiaryLabel) : .red)
                }
                .disabled(appState.habits.isEmpty)

                Button {
                    deleteTarget = "journal"
                    showDeleteConfirm = true
                } label: {
                    Label("Удалить журнал (\(appState.journal.count))", systemImage: "trash")
                        .foregroundStyle(appState.journal.isEmpty ? Color(UIColor.tertiaryLabel) : .red)
                }
                .disabled(appState.journal.isEmpty)

                Button {
                    deleteTarget = "notes"
                    showDeleteConfirm = true
                } label: {
                    Label("Удалить все заметки (\(appState.notes.count))", systemImage: "trash")
                        .foregroundStyle(appState.notes.isEmpty ? Color(UIColor.tertiaryLabel) : .red)
                }
                .disabled(appState.notes.isEmpty)
            }

            Section("Полный сброс") {
                Button(role: .destructive) {
                    deleteTarget = "all"
                    showDeleteConfirm = true
                } label: {
                    Label("Удалить ВСЕ данные", systemImage: "exclamationmark.triangle.fill")
                }
            }
        }
        .navigationTitle("Данные")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Подтверждение", isPresented: $showDeleteConfirm) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) { performDelete() }
        } message: {
            Text(deleteMessage)
        }
        .sheet(isPresented: $showExportResult) {
            NavigationStack {
                ScrollView {
                    Text(exportResult)
                        .font(.system(size: 11, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle("Результат экспорта")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Закрыть") { showExportResult = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Копировать") { UIPasteboard.general.string = exportResult }
                    }
                }
            }
        }
    }

    private func dataRow(_ title: String, count: Int, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var deleteMessage: String {
        switch deleteTarget {
        case "tasks": return "Все задачи (\(appState.tasks.count)) будут удалены безвозвратно."
        case "goals": return "Все цели (\(appState.goals.count)) будут удалены безвозвратно."
        case "habits": return "Все привычки (\(appState.habits.count)) будут удалены безвозвратно."
        case "journal": return "Все записи журнала (\(appState.journal.count)) будут удалены безвозвратно."
        case "notes": return "Все заметки (\(appState.notes.count)) будут удалены безвозвратно."
        case "all": return "ВСЕ данные приложения будут удалены безвозвратно. Это включает задачи, цели, привычки, журнал и заметки."
        default: return ""
        }
    }

    private func performDelete() {
        withAnimation {
            switch deleteTarget {
            case "tasks": appState.tasks.removeAll()
            case "goals": appState.goals.removeAll()
            case "habits": appState.habits.removeAll()
            case "journal": var j = appState.journal; j.removeAll(); appState.journal = j
            case "notes": var n = appState.notes; n.removeAll(); appState.notes = n
            case "all":
                appState.tasks.removeAll()
                appState.goals.removeAll()
                appState.habits.removeAll()
                var j = appState.journal; j.removeAll(); appState.journal = j
                var n = appState.notes; n.removeAll(); appState.notes = n
            default: break
            }
        }
    }
}

struct ActivityFeedView: View {
    @EnvironmentObject var appState: AppState

    struct ActivityItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
        let date: Date
        let type: String
    }

    private var activities: [ActivityItem] {
        var items: [ActivityItem] = []

        for task in appState.tasks.suffix(20) {
            items.append(ActivityItem(
                icon: task.isCompleted ? "checkmark.circle.fill" : "plus.circle",
                title: task.isCompleted ? "Выполнена: \(task.title)" : "Создана: \(task.title)",
                subtitle: task.category.rawValue,
                date: task.createdAt,
                type: "task"
            ))
        }

        for goal in appState.goals.suffix(10) {
            items.append(ActivityItem(
                icon: "target",
                title: "Цель: \(goal.title)",
                subtitle: "\(Int(goal.progress * 100))% прогресс",
                date: goal.createdAt,
                type: "goal"
            ))
        }

        for entry in appState.journal.suffix(10) {
            items.append(ActivityItem(
                icon: entry.mood.icon,
                title: "Журнал: \(entry.mood.rawValue)",
                subtitle: String(entry.text.prefix(40)),
                date: entry.date,
                type: "journal"
            ))
        }

        for note in appState.notes.suffix(10) {
            items.append(ActivityItem(
                icon: "note.text",
                title: "Заметка: \(note.title)",
                subtitle: String(note.content.prefix(40)),
                date: note.createdAt,
                type: "note"
            ))
        }

        return items.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                if activities.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "Нет активности",
                        subtitle: "Начните создавать задачи и записи"
                    )
                } else {
                    ForEach(activities) { activity in
                        HStack(spacing: 14) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(colorForType(activity.type))
                                    .frame(width: 10, height: 10)
                                if activity.id != activities.last?.id {
                                    Rectangle()
                                        .fill(Color(UIColor.separator))
                                        .frame(width: 1, height: 50)
                                }
                            }

                            HStack(spacing: 12) {
                                Image(systemName: activity.icon)
                                    .font(.system(size: 16))
                                    .frame(width: 32, height: 32)
                                    .background(.secondary.opacity(0.08), in: Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                    HStack(spacing: 6) {
                                        Text(activity.subtitle)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        Text("·").foregroundStyle(Color(UIColor.separator))
                                        Text(timeAgo(activity.date))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Активность")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "task": return .primary
        case "goal": return .primary.opacity(0.7)
        case "journal": return .secondary
        case "note": return .secondary.opacity(0.5)
        default: return Color(UIColor.separator)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "только что" }
        if seconds < 3600 { return "\(seconds / 60) мин назад" }
        if seconds < 86400 { return "\(seconds / 3600) ч назад" }
        let days = seconds / 86400
        if days == 1 { return "вчера" }
        if days < 7 { return "\(days) дн назад" }
        return shortRuDate(date)
    }
}
