import SwiftUI

// MARK: - iOS 26 Liquid Glass Design System
// The key to visible glass: colorful gradient background + thick blur + specular highlights

// MARK: - Ambient Background (colorful wallpaper so glass is visible)
struct AmbientBackground: View {
    var body: some View {
        ZStack {
            // Base gradient - deep purple to blue
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.08, green: 0.04, blue: 0.18), location: 0.0),
                    .init(color: Color(red: 0.12, green: 0.06, blue: 0.22), location: 0.3),
                    .init(color: Color(red: 0.06, green: 0.10, blue: 0.24), location: 0.6),
                    .init(color: Color(red: 0.04, green: 0.08, blue: 0.16), location: 1.0),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Accent blob top-right (pink/magenta)
            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color(red: 0.6, green: 0.2, blue: 0.5).opacity(0.35), location: 0.0),
                            .init(color: Color.clear, location: 1.0),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 120, y: -200)

            // Accent blob bottom-left (blue/cyan)
            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color(red: 0.15, green: 0.35, blue: 0.65).opacity(0.30), location: 0.0),
                            .init(color: Color.clear, location: 1.0),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 350
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: -150, y: 300)

            // Accent blob center (purple)
            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color(red: 0.4, green: 0.15, blue: 0.6).opacity(0.15), location: 0.0),
                            .init(color: Color.clear, location: 1.0),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 250
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 0, y: 100)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass Modifiers

extension View {
    /// Thick liquid glass card — visible blur with specular highlights
    func glassCardStyle() -> some View {
        self
            .padding(16)
            .background(
                ZStack {
                    // Thick frosted glass
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)

                    // Inner glow - light comes through the glass
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.15), location: 0.0),
                                    .init(color: Color.white.opacity(0.05), location: 0.2),
                                    .init(color: Color.clear, location: 0.5),
                                    .init(color: Color.white.opacity(0.03), location: 1.0),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Specular highlight streak (the "shine" that makes it liquid)
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.clear, location: 0.0),
                                    .init(color: Color.white.opacity(0.25), location: 0.05),
                                    .init(color: Color.white.opacity(0.08), location: 0.15),
                                    .init(color: Color.clear, location: 0.3),
                                ],
                                startPoint: .topLeading,
                                endPoint: UnitPoint(x: 0.3, y: 1.0)
                            )
                        )

                    // Glass border - bright on top, dim on bottom
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.4), location: 0.0),
                                    .init(color: Color.white.opacity(0.1), location: 0.3),
                                    .init(color: Color.white.opacity(0.02), location: 0.7),
                                    .init(color: Color.white.opacity(0.08), location: 1.0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    /// Legacy cardStyle alias
    func cardStyle() -> some View {
        self.glassCardStyle()
    }

    /// Liquid glass pill/chip with selection glow
    func glassPillStyle(isSelected: Bool = false) -> some View {
        self
            .background(
                ZStack {
                    if isSelected {
                        // Selected: glowing glass
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.18), location: 0.0),
                                        .init(color: Color.white.opacity(0.04), location: 0.5),
                                        .init(color: Color.clear, location: 1.0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    } else {
                        // Unselected: thin glass
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
    }

    /// Legacy pillStyle alias
    func pillStyle() -> some View {
        self.glassPillStyle()
    }

    /// Glass input field
    func inputStyle() -> some View {
        self
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
            )
    }

    /// Glass navigation/tab bar background
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
                                    .init(color: Color.white.opacity(0.06), location: 0.0),
                                    .init(color: Color.clear, location: 0.3),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
    }

    /// Stat card with glass
    func glassStatCard() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.6)
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
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
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
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(width: size, height: size)
        .background(
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.15), location: 0.0),
                                .init(color: Color.clear, location: 0.5),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
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
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
                .shadow(color: .white.opacity(0.3), radius: 3)
            Text("\(Int(min(progress, 1.0) * 100))%")
                .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.3))
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            if let title = actionTitle, let action = action {
                Button(title, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.15))
                    .foregroundStyle(.white)
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
                        .foregroundStyle(item.value > 0 ? .white : .white.opacity(0.3))
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(item.value > 0 ? AnyShapeStyle(Color.white.opacity(0.7)) : AnyShapeStyle(Color.white.opacity(0.06)))
                        .frame(height: max(height * 60, 4))
                    Text(item.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
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
                    .fill(done ? AnyShapeStyle(Color.white.opacity(0.7)) : AnyShapeStyle(Color.white.opacity(0.06)))
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
