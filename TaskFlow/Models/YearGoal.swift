import SwiftUI

struct YearGoal: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var description: String
    var category: GoalCategory
    var startDate: Date
    var targetDate: Date
    var milestones: [Milestone]
    var dailyAction: String
    var completedDays: [String] = []
    var createdAt: Date = Date()

    static func == (lhs: YearGoal, rhs: YearGoal) -> Bool { lhs.id == rhs.id }

    var progress: Double {
        guard !milestones.isEmpty else { return 0 }
        return Double(milestones.filter { $0.isCompleted }.count) / Double(milestones.count)
    }

    var streakDays: Int {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var count = 0
        var date = cal.startOfDay(for: Date())
        while completedDays.contains(fmt.string(from: date)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 365
    }

    var daysRemaining: Int {
        max(0, totalDays - max(0, Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0))
    }

    func isTodayCompleted() -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return completedDays.contains(fmt.string(from: Date()))
    }
}

struct Milestone: Identifiable, Codable {
    var id = UUID()
    var title: String
    var targetDate: Date
    var isCompleted: Bool = false
}

enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case health = "Здоровье"
    case fitness = "Фитнес"
    case education = "Обучение"
    case career = "Карьера"
    case finance = "Финансы"
    case mindfulness = "Осознанность"
    case relationships = "Отношения"
    case creativity = "Творчество"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .education: return "graduationcap.fill"
        case .career: return "chart.line.uptrend.xyaxis"
        case .finance: return "dollarsign.circle.fill"
        case .mindfulness: return "brain.head.profile"
        case .relationships: return "person.2.fill"
        case .creativity: return "paintbrush.pointed.fill"
        }
    }
}

struct HabitItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var icon: String
    var completedDates: [String] = []
    var createdAt: Date = Date()

    static func == (lhs: HabitItem, rhs: HabitItem) -> Bool { lhs.id == rhs.id }

    func isCompletedToday() -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return completedDates.contains(fmt.string(from: Date()))
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var count = 0
        var date = cal.startOfDay(for: Date())
        while completedDates.contains(fmt.string(from: date)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    var totalCompleted: Int { completedDates.count }
}
