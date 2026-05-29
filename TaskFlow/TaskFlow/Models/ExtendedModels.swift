import SwiftUI

struct JournalEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var mood: Mood
    var text: String
    var gratitude: [String]
    var highlights: [String]
    var createdAt: Date = Date()

    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool { lhs.id == rhs.id }
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case terrible = "Ужасно"
    case bad = "Плохо"
    case neutral = "Нормально"
    case good = "Хорошо"
    case great = "Отлично"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .terrible: return "cloud.bolt.rain.fill"
        case .bad: return "cloud.rain.fill"
        case .neutral: return "cloud.fill"
        case .good: return "sun.max.fill"
        case .great: return "sparkles"
        }
    }

    var score: Int {
        switch self {
        case .terrible: return 1
        case .bad: return 2
        case .neutral: return 3
        case .good: return 4
        case .great: return 5
        }
    }
}

struct NoteItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var content: String
    var isPinned: Bool = false
    var tags: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    static func == (lhs: NoteItem, rhs: NoteItem) -> Bool { lhs.id == rhs.id }
}

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let requirement: String
    let isUnlocked: Bool
    let progress: Double
}

struct DayStats: Identifiable {
    let id = UUID()
    let date: Date
    let tasksCompleted: Int
    let tasksTotal: Int
    let habitsCompleted: Int
    let habitsTotal: Int
    let focusMinutes: Int
    let mood: Mood?
}

struct WeekSummary {
    let startDate: Date
    let endDate: Date
    let totalTasksCompleted: Int
    let totalTasksCreated: Int
    let avgMood: Double
    let topCategory: TaskCategory?
    let totalFocusMinutes: Int
    let streakDays: Int
    let bestDay: Date?
    let habitCompletionRate: Double
}

struct MonthGrid {
    let year: Int
    let month: Int
    let days: [MonthDay]
}

struct MonthDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let tasksCount: Int
    let completedCount: Int
    let hasGoalCheckIn: Bool
    let habitsCompleted: Int
    let habitsTotal: Int
}

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: TaskCategory
    let count: Int
    let completed: Int
    let percentage: Double
}

struct PriorityDistribution: Identifiable {
    let id = UUID()
    let priority: Priority
    let count: Int
    let percentage: Double
}

struct TimeBlock: Identifiable {
    let id = UUID()
    let hour: Int
    let taskCount: Int
}

struct ProductivityScore {
    let overall: Double
    let taskCompletion: Double
    let habitConsistency: Double
    let goalProgress: Double
    let focusTime: Double
    let streak: Double

    var grade: String {
        switch overall {
        case 0.9...: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B+"
        case 0.6..<0.7: return "B"
        case 0.5..<0.6: return "C+"
        case 0.4..<0.5: return "C"
        default: return "D"
        }
    }

    var description: String {
        switch overall {
        case 0.8...: return "Превосходная продуктивность!"
        case 0.6..<0.8: return "Хорошая продуктивность"
        case 0.4..<0.6: return "Средняя продуктивность"
        default: return "Есть куда расти"
        }
    }
}

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var title: String
    var time: Date
    var isEnabled: Bool = true
    var repeatDays: [Int] = []
}

struct Tag: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var usageCount: Int = 0
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    case markdown = "Markdown"
    var id: String { rawValue }
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Сначала новые"
    case dateOldest = "Сначала старые"
    case nameAZ = "По названию А-Я"
    case nameZA = "По названию Я-А"
    case priorityHigh = "По приоритету ↓"
    case priorityLow = "По приоритету ↑"
    var id: String { rawValue }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Неделя"
    case month = "Месяц"
    case quarter = "Квартал"
    case year = "Год"
    case all = "Всё время"
    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .all: return 9999
        }
    }
}
