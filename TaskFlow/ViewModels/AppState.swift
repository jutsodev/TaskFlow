import SwiftUI

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userAge") var userAge: Int = 0
    @Published var tasks: [TaskItem] = []
    @Published var goals: [YearGoal] = []
    @Published var habits: [HabitItem] = []
    @Published var avatarData: Data? = nil

    init() {
        loadTasks()
        loadGoals()
        loadHabits()
        avatarData = UserDefaults.standard.data(forKey: "savedAvatar")
    }

    var userInitials: String {
        guard !userName.isEmpty else { return "?" }
        let words = userName.components(separatedBy: " ")
        if words.count >= 2 { return String(words[0].prefix(1) + words[1].prefix(1)).uppercased() }
        return String(userName.prefix(2)).uppercased()
    }

    func addTask(_ task: TaskItem) { tasks.append(task); saveTasks() }
    func deleteTask(_ task: TaskItem) { tasks.removeAll { $0.id == task.id }; saveTasks() }

    func updateTask(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) { tasks[i] = task; saveTasks() }
    }

    func toggleTask(_ task: TaskItem) {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i].isCompleted.toggle()
            if tasks[i].isCompleted { for j in tasks[i].steps.indices { tasks[i].steps[j].isCompleted = true } }
            saveTasks()
        }
    }

    func toggleStep(taskId: UUID, stepId: UUID) {
        if let ti = tasks.firstIndex(where: { $0.id == taskId }),
           let si = tasks[ti].steps.firstIndex(where: { $0.id == stepId }) {
            tasks[ti].steps[si].isCompleted.toggle()
            tasks[ti].isCompleted = tasks[ti].steps.allSatisfy { $0.isCompleted }
            saveTasks()
        }
    }

    func addTimeToTask(taskId: UUID, seconds: Int) {
        if let i = tasks.firstIndex(where: { $0.id == taskId }) { tasks[i].timeSpentSeconds += seconds; saveTasks() }
    }

    func tasksForDate(_ date: Date) -> [TaskItem] {
        let cal = Calendar.current
        return tasks.filter { cal.isDate($0.startDate, inSameDayAs: date) }
    }

    var todayTasks: [TaskItem] { tasksForDate(Date()) }
    var completedTodayCount: Int { todayTasks.filter { $0.isCompleted }.count }
    var todayProgress: Double { todayTasks.isEmpty ? 0 : Double(completedTodayCount) / Double(todayTasks.count) }
    var totalCompleted: Int { tasks.filter { $0.isCompleted }.count }

    var streak: Int {
        var count = 0
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        if !todayTasks.isEmpty && todayTasks.allSatisfy({ $0.isCompleted }) { count += 1 }
        else if !todayTasks.isEmpty { return 0 }
        for _ in 0..<365 {
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
            let dt = tasksForDate(date)
            if dt.isEmpty { continue }
            if dt.allSatisfy({ $0.isCompleted }) { count += 1 } else { break }
        }
        return count
    }

    func addGoal(_ goal: YearGoal) { goals.append(goal); saveGoals() }
    func deleteGoal(_ goal: YearGoal) { goals.removeAll { $0.id == goal.id }; saveGoals() }

    func toggleMilestone(goalId: UUID, milestoneId: UUID) {
        if let gi = goals.firstIndex(where: { $0.id == goalId }),
           let mi = goals[gi].milestones.firstIndex(where: { $0.id == milestoneId }) {
            goals[gi].milestones[mi].isCompleted.toggle(); saveGoals()
        }
    }

    func checkInGoal(goalId: UUID) {
        if let i = goals.firstIndex(where: { $0.id == goalId }) {
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            let today = fmt.string(from: Date())
            if !goals[i].completedDays.contains(today) { goals[i].completedDays.append(today); saveGoals() }
        }
    }

    func addHabit(_ habit: HabitItem) { habits.append(habit); saveHabits() }
    func deleteHabit(_ habit: HabitItem) { habits.removeAll { $0.id == habit.id }; saveHabits() }

    func toggleHabitToday(habitId: UUID) {
        if let i = habits.firstIndex(where: { $0.id == habitId }) {
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            let today = fmt.string(from: Date())
            if habits[i].completedDates.contains(today) { habits[i].completedDates.removeAll { $0 == today } }
            else { habits[i].completedDates.append(today) }
            saveHabits()
        }
    }

    var habitsCompletedToday: Int { habits.filter { $0.isCompletedToday() }.count }

    func saveAvatar(_ data: Data?) {
        avatarData = data
        if let data = data { UserDefaults.standard.set(data, forKey: "savedAvatar") }
        else { UserDefaults.standard.removeObject(forKey: "savedAvatar") }
    }

    private func saveTasks() { if let d = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(d, forKey: "tasks") } }
    private func loadTasks() { if let d = UserDefaults.standard.data(forKey: "tasks"), let v = try? JSONDecoder().decode([TaskItem].self, from: d) { tasks = v } }
    private func saveGoals() { if let d = try? JSONEncoder().encode(goals) { UserDefaults.standard.set(d, forKey: "goals") } }
    private func loadGoals() { if let d = UserDefaults.standard.data(forKey: "goals"), let v = try? JSONDecoder().decode([YearGoal].self, from: d) { goals = v } }
    private func saveHabits() { if let d = try? JSONEncoder().encode(habits) { UserDefaults.standard.set(d, forKey: "habits") } }
    private func loadHabits() { if let d = UserDefaults.standard.data(forKey: "habits"), let v = try? JSONDecoder().decode([HabitItem].self, from: d) { habits = v } }
}

func formatTimeHMS(_ totalSeconds: Int) -> String {
    let h = totalSeconds / 3600, m = (totalSeconds % 3600) / 60, s = totalSeconds % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
}
