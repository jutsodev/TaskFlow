import SwiftUI

// MARK: - iOS 26 Liquid Glass Effect System

extension View {
    /// iOS 26-style liquid glass card with blur, transparency, and specular highlights
    func glassCardStyle() -> some View {
        self
            .padding(16)
            .background(
                ZStack {
                    // Base frosted glass layer
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // Specular highlight gradient (top edge light reflection)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.18), location: 0.0),
                                    .init(color: Color.white.opacity(0.04), location: 0.3),
                                    .init(color: Color.clear, location: 0.5),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    // Subtle border
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.3), location: 0.0),
                                    .init(color: Color.white.opacity(0.05), location: 0.5),
                                    .init(color: Color.white.opacity(0.15), location: 1.0),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    /// iOS 26 legacy card style (replaces old cardStyle)
    func cardStyle() -> some View {
        self.glassCardStyle()
    }

    /// iOS 26-style liquid glass pill/chip with selection state
    func glassPillStyle(isSelected: Bool = false) -> some View {
        self
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(.ultraThinMaterial)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.primary.opacity(0.12), location: 0.0),
                                        .init(color: Color.primary.opacity(0.06), location: 1.0),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    }
                }
            )
            .foregroundStyle(isSelected ? .primary : .secondary)
    }

    /// Legacy pill style (backward compatible)
    func pillStyle() -> some View {
        self.glassPillStyle()
    }

    /// iOS 26-style input field with glass effect
    func inputStyle() -> some View {
        self
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
            )
    }

    /// Glass background for navigation/tab bars
    func glassBackground() -> some View {
        self
            .background(
                ZStack {
                    Rectangle()
                        .fill(.bar)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.08), location: 0.0),
                                    .init(color: Color.clear, location: 0.4),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
    }

    /// iOS 26 floating action button with glass effect
    func glassFloatingStyle() -> some View {
        self
            .padding(12)
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    Circle()
                        .fill(
                            RadialGradient(
                                stops: [
                                    .init(color: Color.primary.opacity(0.1), location: 0.0),
                                    .init(color: Color.primary.opacity(0.04), location: 1.0),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    /// iOS 26-style stat card with glass
    func glassStatCard() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.12), location: 0.0),
                                    .init(color: Color.clear, location: 0.4),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                }
            )
    }
}

// MARK: - Shared UI Components

struct LogoView: View {
    var size: CGFloat = 40

    var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
                    Color.clear
                    Text(initials.isEmpty ? "?" : initials)
                        .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .background(
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            }
        )
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }
}

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
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
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(item.value > 0 ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.white.opacity(0.08)))
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

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(done ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.white.opacity(0.06)))
                    .frame(height: 12)
            }
        }
    }
}

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
