import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    func pillStyle() -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.08), in: Capsule())
    }

    func inputStyle() -> some View {
        self
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct LogoView: View {
    var size: CGFloat = 40

    var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

struct AvatarView: View {
    let data: Data?
    let size: CGFloat
    var initials: String = ""

    var body: some View {
        Group {
            if let data = data, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.separator, lineWidth: 0.5))
    }
}

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(.separator, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
            Text("\(Int(min(progress, 1.0) * 100))%")
                .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
        }
        .frame(width: size, height: size)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 20)
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            if let title = actionTitle, let action = action {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.regular)
            }
            Spacer().frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeekBarChart: View {
    let data: [(label: String, value: Int, maxValue: Int)]

    var body: some View {
        let indices = Array(data.indices)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(indices, id: \.self) { i in
                let item = data[i]
                let height = item.maxValue > 0 ? CGFloat(item.value) / CGFloat(item.maxValue) : 0
                VStack(spacing: 4) {
                    Text("\(item.value)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(item.value > 0 ? .primary : .tertiary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.value > 0 ? Color.primary : Color(UIColor.separator).opacity(0.3))
                        .frame(height: max(height * 60, 4))
                    Text(item.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 90)
    }
}

struct StreakCalendarView: View {
    let completedDates: [String]
    var days: Int = 35

    var body: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let fmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f
        }()
        let dayIndices = Array(0..<days)

        HStack(spacing: 3) {
            ForEach(dayIndices, id: \.self) { offset in
                let date = cal.date(byAdding: .day, value: -(days - 1 - offset), to: today) ?? today
                let key = fmt.string(from: date)
                let done = completedDates.contains(key)

                RoundedRectangle(cornerRadius: 2)
                    .fill(done ? Color.primary : Color.secondary.opacity(0.08))
                    .frame(height: 12)
            }
        }
    }
}

// TaskDetailSheet and GoalDetailSheet are defined in their respective view files

func formattedRuDate(_ date: Date) -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "ru_RU")
    fmt.dateFormat = "d MMM yyyy"
    return fmt.string(from: date)
}

func shortRuDate(_ date: Date) -> String {
    let fmt = DateFormatter()
    fmt.locale = Locale(identifier: "ru_RU")
    fmt.dateFormat = "d MMM"
    return fmt.string(from: date)
}

func formatTimeHMS(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
    return String(format: "%02d:%02d", m, s)
}

func weeklyTaskData(from appState: AppState) -> [(label: String, value: Int, maxValue: Int)] {
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let dayNames = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]

    var data: [(label: String, value: Int, maxValue: Int)] = []
    var maxVal = 1

    for offset in (0..<7).reversed() {
        let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
        let count = appState.tasksForDate(date).filter { $0.isCompleted }.count
        if count > maxVal { maxVal = count }
        let weekday = cal.component(.weekday, from: date)
        let idx = (weekday + 5) % 7
        data.append((label: dayNames[idx], value: count, maxValue: 0))
    }

    return data.map { ($0.label, $0.value, maxVal) }
}
