import SwiftUI

struct WidgetPreviewView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Text("Превью виджетов")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Так будут выглядеть виджеты на рабочем столе")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                smallWidget
                mediumWidget
                largeWidget
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Виджеты")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Маленький").font(.caption).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                HStack {
                    LogoView(size: 24)
                    Spacer()
                    Text("\(Int(appState.todayProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                ProgressView(value: appState.todayProgress).tint(.primary)
                HStack {
                    Text("\(appState.completedTodayCount)/\(appState.todayTasks.count)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    Text("задач").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "flame.fill").font(.system(size: 10))
                    Text("\(appState.streak)").font(.system(size: 12, weight: .bold, design: .rounded))
                }
            }
            .padding(14)
            .frame(width: 170, height: 170)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Средний").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        LogoView(size: 22)
                        Text("TaskFlow").font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    ProgressRing(progress: appState.todayProgress, size: 50, lineWidth: 5)
                    Text("\(appState.completedTodayCount)/\(appState.todayTasks.count) задач")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 110)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(appState.todayTasks.prefix(4)) { task in
                        HStack(spacing: 6) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            Text(task.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .strikethrough(task.isCompleted)
                        }
                    }
                    if appState.todayTasks.count > 4 {
                        Text("+\(appState.todayTasks.count - 4) ещё")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    if appState.todayTasks.isEmpty {
                        Text("Нет задач")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .frame(width: 350, height: 170)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Большой").font(.caption).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    LogoView(size: 24)
                    Text("TaskFlow").font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                    Text(shortRuDate(Date())).font(.caption).foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("\(appState.completedTodayCount)").font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Готово").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("\(appState.todayTasks.count)").font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Всего").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("\(appState.streak)").font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Серия").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

                ProgressView(value: appState.todayProgress).tint(.primary)

                ForEach(appState.todayTasks.prefix(6)) { task in
                    HStack(spacing: 8) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        Text(task.title).font(.system(size: 12)).lineLimit(1).strikethrough(task.isCompleted)
                        Spacer()
                        Image(systemName: task.priority.icon).font(.system(size: 9)).foregroundStyle(task.priority.color)
                    }
                }

                if !appState.habits.isEmpty {
                    Divider()
                    HStack(spacing: 6) {
                        ForEach(appState.habits.prefix(6)) { habit in
                            Image(systemName: habit.icon)
                                .font(.system(size: 14))
                                .frame(width: 28, height: 28)
                                .background(
                                    habit.isCompletedToday() ? Color.primary.opacity(0.1) : Color.clear,
                                    in: Circle()
                                )
                                .overlay(Circle().stroke(habit.isCompletedToday() ? .primary : .separator, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(16)
            .frame(width: 350, height: 370)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct MoodAnalyticsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if appState.journal.isEmpty {
                    EmptyStateView(
                        icon: "face.smiling",
                        title: "Нет данных о настроении",
                        subtitle: "Ведите журнал для аналитики настроения"
                    )
                } else {
                    currentMood
                    weekMoodChart
                    moodDistribution
                    moodCorrelation
                    recentEntries
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Аналитика настроения")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentMood: some View {
        let latest = appState.journal.sorted { $0.date > $1.date }.first
        return VStack(spacing: 12) {
            if let entry = latest {
                Image(systemName: entry.mood.icon)
                    .font(.system(size: 40))
                Text(entry.mood.rawValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Последняя запись: \(shortRuDate(entry.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var weekMoodChart: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let entries = appState.journal.sorted { $0.date > $1.date }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Настроение за неделю")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { offset in
                    let date = cal.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
                    let entry = entries.first { cal.isDate($0.date, inSameDayAs: date) }
                    let score = entry?.mood.score ?? 0

                    VStack(spacing: 4) {
                        if let entry = entry {
                            Image(systemName: entry.mood.icon)
                                .font(.system(size: 12))
                        }
                        RoundedRectangle(cornerRadius: 4)
                            .fill(score > 0 ? Color.primary : Color.separator.opacity(0.3))
                            .frame(width: 24, height: CGFloat(score) * 12 + 4)
                        Text(dayAbbrev(date))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
        .cardStyle()
    }

    private func dayAbbrev(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "EE"
        return String(fmt.string(from: date).prefix(2)).uppercased()
    }

    private var moodDistribution: some View {
        let entries = appState.journal
        let total = max(entries.count, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Распределение")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            ForEach(Mood.allCases) { mood in
                let count = entries.filter { $0.mood == mood }.count
                let pct = Double(count) / Double(total)

                HStack(spacing: 10) {
                    Image(systemName: mood.icon)
                        .font(.system(size: 16))
                        .frame(width: 24)
                    Text(mood.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 70, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.separator).frame(height: 6)
                            Capsule().fill(.primary).frame(width: max(geo.size.width * pct, 2), height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
        .cardStyle()
    }

    private var moodCorrelation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Корреляции")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            let goodDays = appState.journal.filter { $0.mood.score >= 4 }
            let badDays = appState.journal.filter { $0.mood.score <= 2 }
            let cal = Calendar.current

            let goodTasks = goodDays.isEmpty ? 0.0 : Double(goodDays.map { appState.tasksForDate($0.date).filter { $0.isCompleted }.count }.reduce(0, +)) / Double(goodDays.count)
            let badTasks = badDays.isEmpty ? 0.0 : Double(badDays.map { appState.tasksForDate($0.date).filter { $0.isCompleted }.count }.reduce(0, +)) / Double(badDays.count)

            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "sun.max.fill").font(.system(size: 20))
                    Text(String(format: "%.1f", goodTasks))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("задач в хорошие дни")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 6) {
                    Image(systemName: "cloud.rain.fill").font(.system(size: 20))
                    Text(String(format: "%.1f", badTasks))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("задач в плохие дни")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }

    private var recentEntries: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние записи")
                .font(.system(size: 16, weight: .semibold, design: .rounded))

            ForEach(appState.journal.sorted { $0.date > $1.date }.prefix(5)) { entry in
                HStack(spacing: 12) {
                    Image(systemName: entry.mood.icon).font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedRuDate(entry.date))
                            .font(.system(size: 13, weight: .medium))
                        if !entry.text.isEmpty {
                            Text(entry.text)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text("\(entry.mood.score)/5")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if entry.id != appState.journal.sorted(by: { $0.date > $1.date }).prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }
}

struct ProductivityDashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showWeeklyReview = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                scoreCard
                todaySnapshot
                weekOverview
                categoryPerformance
                actionButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Продуктивность")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewView().environmentObject(appState)
        }
    }

    private var scoreCard: some View {
        let score = appState.productivityScore()
        return VStack(spacing: 16) {
            ProgressRing(progress: score.overall, size: 100, lineWidth: 10)
            Text(score.grade)
                .font(.system(size: 36, weight: .black, design: .rounded))
            Text(score.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(Int(score.overall * 100)) баллов")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var todaySnapshot: some View {
        HStack(spacing: 12) {
            miniCard("checkmark.circle.fill", "\(appState.completedTodayCount)/\(appState.todayTasks.count)", "Задачи")
            miniCard("flame.fill", "\(appState.streak)", "Серия")
            miniCard("repeat.circle.fill", "\(appState.habitsCompletedToday)/\(appState.habits.count)", "Привычки")
        }
    }

    private func miniCard(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16))
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var weekOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Неделя").font(.system(size: 16, weight: .semibold, design: .rounded))
            WeekBarChart(data: weeklyTaskData(from: appState))
        }
        .cardStyle()
    }

    private var categoryPerformance: some View {
        let stats = appState.categoryStats(for: .week)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Категории (неделя)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            if stats.isEmpty {
                Text("Нет данных").font(.subheadline).foregroundStyle(.tertiary)
            } else {
                ForEach(stats.prefix(4)) { stat in
                    HStack(spacing: 10) {
                        Image(systemName: stat.category.icon).font(.system(size: 13))
                        Text(stat.category.rawValue).font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text("\(stat.completed)/\(stat.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                }
            }
        }
        .cardStyle()
    }

    private var actionButton: some View {
        Button { showWeeklyReview = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("Полный обзор недели")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.primary)
        .controlSize(.large)
    }
}
