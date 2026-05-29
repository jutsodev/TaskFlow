import SwiftUI

extension AppState {
    @MainActor
    var journal: [JournalEntry] {
        get {
            if let d = UserDefaults.standard.data(forKey: "journal"),
               let v = try? JSONDecoder().decode([JournalEntry].self, from: d) { return v }
            return []
        }
        set {
            if let d = try? JSONEncoder().encode(newValue) { UserDefaults.standard.set(d, forKey: "journal") }
            objectWillChange.send()
        }
    }

    @MainActor
    var notes: [NoteItem] {
        get {
            if let d = UserDefaults.standard.data(forKey: "notes"),
               let v = try? JSONDecoder().decode([NoteItem].self, from: d) { return v }
            return []
        }
        set {
            if let d = try? JSONEncoder().encode(newValue) { UserDefaults.standard.set(d, forKey: "notes") }
            objectWillChange.send()
        }
    }

    func addJournalEntry(_ entry: JournalEntry) {
        var j = journal; j.append(entry); journal = j
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        var j = journal; j.removeAll { $0.id == entry.id }; journal = j
    }

    func updateJournalEntry(_ entry: JournalEntry) {
        var j = journal
        if let i = j.firstIndex(where: { $0.id == entry.id }) { j[i] = entry }
        journal = j
    }

    func journalForDate(_ date: Date) -> JournalEntry? {
        let cal = Calendar.current
        return journal.first { cal.isDate($0.date, inSameDayAs: date) }
    }

    func addNote(_ note: NoteItem) {
        var n = notes; n.append(note); notes = n
    }

    func deleteNote(_ note: NoteItem) {
        var n = notes; n.removeAll { $0.id == note.id }; notes = n
    }

    func updateNote(_ note: NoteItem) {
        var n = notes
        if let i = n.firstIndex(where: { $0.id == note.id }) { n[i] = note }
        notes = n
    }

    func toggleNotePin(_ note: NoteItem) {
        var n = notes
        if let i = n.firstIndex(where: { $0.id == note.id }) { n[i].isPinned.toggle() }
        notes = n
    }

    func categoryStats(for range: TimeRange) -> [CategoryStat] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        let filtered = tasks.filter { $0.createdAt >= cutoff }
        let total = max(filtered.count, 1)
        var dict: [TaskCategory: (count: Int, completed: Int)] = [:]
        for task in filtered {
            let existing = dict[task.category] ?? (0, 0)
            dict[task.category] = (existing.count + 1, existing.completed + (task.isCompleted ? 1 : 0))
        }
        return dict.map { cat, val in
            CategoryStat(category: cat, count: val.count, completed: val.completed,
                         percentage: Double(val.count) / Double(total))
        }.sorted { $0.count > $1.count }
    }

    func priorityDistribution(for range: TimeRange) -> [PriorityDistribution] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        let filtered = tasks.filter { $0.createdAt >= cutoff }
        let total = max(filtered.count, 1)
        return Priority.allCases.map { p in
            let count = filtered.filter { $0.priority == p }.count
            return PriorityDistribution(priority: p, count: count, percentage: Double(count) / Double(total))
        }
    }

    func weekSummary() -> WeekSummary {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekStart = cal.date(byAdding: .day, value: -6, to: today) ?? today

        let weekTasks = tasks.filter { $0.startDate >= weekStart }
        let completed = weekTasks.filter { $0.isCompleted }.count

        let catCounts = Dictionary(grouping: weekTasks, by: { $0.category })
        let topCat = catCounts.max { $0.value.count < $1.value.count }?.key

        let weekJournal = journal.filter { $0.date >= weekStart }
        let avgMood = weekJournal.isEmpty ? 0 : Double(weekJournal.map { $0.mood.score }.reduce(0, +)) / Double(weekJournal.count)

        var bestDate: Date? = nil
        var bestCount = 0
        for offset in 0..<7 {
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = tasksForDate(date).filter { $0.isCompleted }.count
            if count > bestCount { bestCount = count; bestDate = date }
        }

        let totalFocus = weekTasks.reduce(0) { $0 + $1.timeSpentSeconds } / 60

        let habitRate: Double = {
            guard !habits.isEmpty else { return 0 }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            var totalPossible = 0
            var totalDone = 0
            for offset in 0..<7 {
                let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
                let key = fmt.string(from: date)
                totalPossible += habits.count
                totalDone += habits.filter { $0.completedDates.contains(key) }.count
            }
            return totalPossible > 0 ? Double(totalDone) / Double(totalPossible) : 0
        }()

        return WeekSummary(
            startDate: weekStart, endDate: today,
            totalTasksCompleted: completed, totalTasksCreated: weekTasks.count,
            avgMood: avgMood, topCategory: topCat, totalFocusMinutes: totalFocus,
            streakDays: streak, bestDay: bestDate, habitCompletionRate: habitRate
        )
    }

    func productivityScore() -> ProductivityScore {
        let taskScore = tasks.isEmpty ? 0 : Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)

        let habitScore: Double = {
            guard !habits.isEmpty else { return 0 }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            var total = 0, done = 0
            for offset in 0..<7 {
                let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
                let key = fmt.string(from: date)
                total += habits.count
                done += habits.filter { $0.completedDates.contains(key) }.count
            }
            return total > 0 ? Double(done) / Double(total) : 0
        }()

        let goalScore = goals.isEmpty ? 0 : goals.map { $0.progress }.reduce(0, +) / Double(goals.count)
        let focusScore = min(Double(tasks.reduce(0) { $0 + $1.timeSpentSeconds }) / 36000.0, 1.0)
        let streakScore = min(Double(streak) / 30.0, 1.0)
        let overall = (taskScore * 0.3 + habitScore * 0.25 + goalScore * 0.2 + focusScore * 0.15 + streakScore * 0.1)

        return ProductivityScore(
            overall: overall, taskCompletion: taskScore, habitConsistency: habitScore,
            goalProgress: goalScore, focusTime: focusScore, streak: streakScore
        )
    }

    func monthGrid(year: Int, month: Int) -> MonthGrid {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        guard let firstDay = cal.date(from: comps) else { return MonthGrid(year: year, month: month, days: []) }

        let range = cal.range(of: .day, in: .month, for: firstDay)!
        let firstWeekday = cal.component(.weekday, from: firstDay)
        let offset = (firstWeekday + 5) % 7

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = cal.startOfDay(for: Date())

        var days: [MonthDay] = []

        for i in 0..<offset {
            let prevDate = cal.date(byAdding: .day, value: -(offset - i), to: firstDay)!
            days.append(MonthDay(date: prevDate, dayNumber: cal.component(.day, from: prevDate),
                                 isCurrentMonth: false, isToday: false,
                                 tasksCount: 0, completedCount: 0, hasGoalCheckIn: false,
                                 habitsCompleted: 0, habitsTotal: 0))
        }

        for day in range {
            comps.day = day
            let date = cal.date(from: comps)!
            let dateTasks = tasksForDate(date)
            let key = fmt.string(from: date)
            let goalCheckins = goals.filter { $0.completedDays.contains(key) }.count
            let hDone = habits.filter { $0.completedDates.contains(key) }.count

            days.append(MonthDay(
                date: date, dayNumber: day,
                isCurrentMonth: true,
                isToday: cal.isDate(date, inSameDayAs: today),
                tasksCount: dateTasks.count,
                completedCount: dateTasks.filter { $0.isCompleted }.count,
                hasGoalCheckIn: goalCheckins > 0,
                habitsCompleted: hDone,
                habitsTotal: habits.count
            ))
        }

        let remaining = 42 - days.count
        if remaining > 0 {
            let lastDay = cal.date(from: DateComponents(year: year, month: month, day: range.count))!
            for i in 1...remaining {
                let nextDate = cal.date(byAdding: .day, value: i, to: lastDay)!
                days.append(MonthDay(date: nextDate, dayNumber: cal.component(.day, from: nextDate),
                                     isCurrentMonth: false, isToday: false,
                                     tasksCount: 0, completedCount: 0, hasGoalCheckIn: false,
                                     habitsCompleted: 0, habitsTotal: 0))
            }
        }

        return MonthGrid(year: year, month: month, days: days)
    }

    @MainActor
    func achievements() -> [Achievement] {
        [
            Achievement(icon: "star.fill", title: "Первая задача", description: "Создайте первую задачу",
                        requirement: "1 задача", isUnlocked: totalCompleted >= 1,
                        progress: min(Double(totalCompleted), 1)),
            Achievement(icon: "flame.fill", title: "3 дня подряд", description: "Серия 3 дня",
                        requirement: "3 дня", isUnlocked: streak >= 3,
                        progress: min(Double(streak) / 3.0, 1)),
            Achievement(icon: "trophy.fill", title: "10 задач", description: "Выполните 10 задач",
                        requirement: "10 задач", isUnlocked: totalCompleted >= 10,
                        progress: min(Double(totalCompleted) / 10.0, 1)),
            Achievement(icon: "target", title: "Целеустремлённый", description: "Поставьте первую цель",
                        requirement: "1 цель", isUnlocked: !goals.isEmpty,
                        progress: goals.isEmpty ? 0 : 1),
            Achievement(icon: "medal.fill", title: "Полтинник", description: "Выполните 50 задач",
                        requirement: "50 задач", isUnlocked: totalCompleted >= 50,
                        progress: min(Double(totalCompleted) / 50.0, 1)),
            Achievement(icon: "bolt.fill", title: "Неделя силы", description: "Серия 7 дней",
                        requirement: "7 дней", isUnlocked: streak >= 7,
                        progress: min(Double(streak) / 7.0, 1)),
            Achievement(icon: "figure.run", title: "Марафонец", description: "Серия 30 дней",
                        requirement: "30 дней", isUnlocked: streak >= 30,
                        progress: min(Double(streak) / 30.0, 1)),
            Achievement(icon: "crown.fill", title: "Сотня", description: "Выполните 100 задач",
                        requirement: "100 задач", isUnlocked: totalCompleted >= 100,
                        progress: min(Double(totalCompleted) / 100.0, 1)),
            Achievement(icon: "repeat.circle.fill", title: "Привычка", description: "Создайте 5 привычек",
                        requirement: "5 привычек", isUnlocked: habits.count >= 5,
                        progress: min(Double(habits.count) / 5.0, 1)),
            Achievement(icon: "pencil.and.outline", title: "Писатель", description: "Напишите 10 заметок в журнале",
                        requirement: "10 записей", isUnlocked: journal.count >= 10,
                        progress: min(Double(journal.count) / 10.0, 1)),
            Achievement(icon: "clock.fill", title: "Фокус 10ч", description: "Проведите 10 часов в фокусе",
                        requirement: "10 часов", isUnlocked: tasks.reduce(0) { $0 + $1.timeSpentSeconds } >= 36000,
                        progress: min(Double(tasks.reduce(0) { $0 + $1.timeSpentSeconds }) / 36000.0, 1)),
            Achievement(icon: "calendar.badge.checkmark", title: "Год перемен", description: "Достигните 1 цели",
                        requirement: "100% прогресс", isUnlocked: goals.contains { $0.progress >= 1.0 },
                        progress: goals.isEmpty ? 0 : goals.map { $0.progress }.max() ?? 0)
        ]
    }

    func exportData(format: ExportFormat) -> String {
        switch format {
        case .json:
            return exportJSON()
        case .csv:
            return exportCSV()
        case .markdown:
            return exportMarkdown()
        }
    }

    @MainActor
    private func exportJSON() -> String {
        struct ExportData: Codable {
            let tasks: [TaskItem]
            let goals: [YearGoal]
            let habits: [HabitItem]
            let journal: [JournalEntry]
            let notes: [NoteItem]
            let userName: String
            let userAge: Int
        }
        let data = ExportData(tasks: tasks, goals: goals, habits: habits,
                               journal: journal, notes: notes,
                               userName: userName, userAge: userAge)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? encoder.encode(data), let s = String(data: d, encoding: .utf8) { return s }
        return "{}"
    }

    private func exportCSV() -> String {
        var csv = "Тип,Название,Описание,Статус,Дата создания,Категория,Приоритет\n"
        for task in tasks {
            csv += "Задача,\"\(task.title)\",\"\(task.description)\",\(task.isCompleted ? "Выполнено" : "В процессе"),\(formattedRuDate(task.createdAt)),\(task.category.rawValue),\(task.priority.rawValue)\n"
        }
        for goal in goals {
            csv += "Цель,\"\(goal.title)\",\"\(goal.description)\",\(Int(goal.progress * 100))%,\(formattedRuDate(goal.createdAt)),\(goal.category.rawValue),\n"
        }
        for habit in habits {
            csv += "Привычка,\"\(habit.title)\",,Серия: \(habit.currentStreak),\(formattedRuDate(habit.createdAt)),,\n"
        }
        return csv
    }

    private func exportMarkdown() -> String {
        var md = "# TaskFlow — Экспорт данных\n\n"
        md += "**Пользователь:** \(userName)\n"
        md += "**Дата экспорта:** \(formattedRuDate(Date()))\n\n"
        md += "## Задачи (\(tasks.count))\n\n"
        for task in tasks {
            let status = task.isCompleted ? "✅" : "⬜"
            md += "- \(status) **\(task.title)** — \(task.category.rawValue), \(task.priority.rawValue)\n"
            if !task.description.isEmpty { md += "  > \(task.description)\n" }
        }
        md += "\n## Цели (\(goals.count))\n\n"
        for goal in goals {
            md += "- 🎯 **\(goal.title)** — \(Int(goal.progress * 100))%, серия \(goal.streakDays) дн.\n"
        }
        md += "\n## Привычки (\(habits.count))\n\n"
        for habit in habits {
            let done = habit.isCompletedToday() ? "✅" : "⬜"
            md += "- \(done) **\(habit.title)** — серия \(habit.currentStreak) дн.\n"
        }
        return md
    }
}
