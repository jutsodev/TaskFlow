import SwiftUI

struct TaskItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var description: String
    var steps: [TaskStep]
    var startDate: Date
    var endDate: Date?
    var priority: Priority
    var category: TaskCategory
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var notes: String = ""
    var repeatMode: RepeatMode = .none
    var timeSpentSeconds: Int = 0

    static func == (lhs: TaskItem, rhs: TaskItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct TaskStep: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}

enum RepeatMode: String, Codable, CaseIterable, Identifiable {
    case none = "Без повтора"
    case daily = "Каждый день"
    case weekly = "Каждую неделю"
    case monthly = "Каждый месяц"
    var id: String { rawValue }
}

enum Priority: String, Codable, CaseIterable, Identifiable {
    case low = "Низкий"
    case medium = "Средний"
    case high = "Высокий"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case work = "Работа"
    case personal = "Личное"
    case health = "Здоровье"
    case education = "Обучение"
    case finance = "Финансы"
    case sport = "Спорт"
    case creativity = "Творчество"
    case other = "Другое"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .finance: return "banknote.fill"
        case .sport: return "figure.run"
        case .creativity: return "paintbrush.fill"
        case .other: return "star.fill"
        }
    }
}
