import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateTask = false
    @State private var showWeeklyReview = false
    @State private var animateHeader = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<22: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    private var motivationalQuote: (text: String, author: String) {
        let quotes: [(String, String)] = [
            ("Дисциплина — это мост между целями и достижениями.", "Джим Рон"),
            ("Каждый день — это новая возможность стать лучше.", ""),
            ("Маленькие шаги каждый день приводят к большим результатам.", ""),
            ("Ваше будущее создаётся тем, что вы делаете сегодня.", "Роберт Кийосаки"),
            ("Не жди. Время никогда не будет подходящим.", "Наполеон Хилл"),
            ("Начните с того, что необходимо, затем делайте возможное.", "Франциск Ассизский"),
            ("Успех — это сумма маленьких усилий день за днём.", "Роберт Кольер"),
        ]
        let idx = Calendar.current.component(.day, from: Date()) % quotes.count
        return (quotes[idx].0, quotes[idx].1)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.bottom, 24)

                    VStack(spacing: 18) {
                        progressCard
                        quoteCard
                        todayTasksSection
                        habitsSection
                        goalsSnapshot
                        weekActivity
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateTask = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showCreateTask) {
                CreateTaskView().environmentObject(appState)
            }
            .sheet(isPresented: $showWeeklyReview) {
                WeeklyReviewView().environmentObject(appState)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { animateHeader = true }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                LogoView(size: 44)
                    .scaleEffect(animateHeader ? 1 : 0.5)
                    .opacity(animateHeader ? 1 : 0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(greeting)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(appState.userName.isEmpty ? "Пользователь" : appState.userName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .opacity(animateHeader ? 1 : 0)
                .offset(x: animateHeader ? 0 : -10)

                Spacer()

                AvatarView(data: appState.avatarData, size: 40, initials: appState.userInitials)
                    .scaleEffect(animateHeader ? 1 : 0.5)
                    .opacity(animateHeader ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            HStack(spacing: 2) {
                let fmtDate = DateFormatter()
                let _ = { fmtDate.locale = Locale(identifier: "ru_RU"); fmtDate.dateFormat = "EEEE, d MMMM" }()
                Text(fmtDate.string(from: Date()).capitalized)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                if appState.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                        Text("\(appState.streak) дн.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .glassPillStyle(isSelected: true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
    }

    private var progressCard: some View {
        let total = appState.todayTasks.count
        let done = appState.completedTodayCount
        let progress = total > 0 ? Double(done) / Double(total) : 0

        return HStack(spacing: 18) {
            ProgressRing(progress: progress, size: 72, lineWidth: 7)
                .scaleEffect(animateHeader ? 1 : 0.7)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(total > 0 ? "Выполнено сегодня" : "Нет задач на сегодня")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                    if total > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(done)")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("из \(total)")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }

                if total > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 5)
                            Capsule()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: max(geo.size.width * progress, 4), height: 5)
                                .animation(.spring(response: 0.8), value: progress)
                                .shadow(color: .white.opacity(0.3), radius: 2)
                        }
                    }
                    .frame(height: 5)
                }
            }

            Spacer()
        }
        .cardStyle()
    }

    private var quoteCard: some View {
        let quote = motivationalQuote
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.2))
                Text("Мотивация дня")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Text(quote.text)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .lineSpacing(5)
                .foregroundStyle(.white.opacity(0.8))
            if !quote.author.isEmpty {
                Text("— \(quote.author)")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .cardStyle()
    }

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Сегодня")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                if !appState.todayTasks.isEmpty {
                    Text("\(appState.completedTodayCount)/\(appState.todayTasks.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            if appState.todayTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("Задач на сегодня нет")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Button("Создать") { showCreateTask = true }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .cardStyle()
            } else {
                ForEach(appState.todayTasks.prefix(5)) { task in
                    HStack(spacing: 14) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                appState.toggleTask(task)
                            }
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(task.isCompleted ? .white.opacity(0.3) : .white)
                                .contentTransition(.symbolEffect(.replace))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title)
                                .font(.system(size: 15, weight: .medium))
                                .strikethrough(task.isCompleted, color: .white.opacity(0.3))
                                .foregroundStyle(task.isCompleted ? .white.opacity(0.4) : .white)

                            HStack(spacing: 6) {
                                Image(systemName: task.category.icon)
                                    .font(.system(size: 9))
                                Text(task.category.rawValue)
                                    .font(.system(size: 11))
                                if !task.steps.isEmpty {
                                    Text("·")
                                    Text("\(task.steps.filter { $0.isCompleted }.count)/\(task.steps.count)")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                }
                            }
                            .foregroundStyle(.white.opacity(0.3))
                        }

                        Spacer()

                        Image(systemName: task.priority.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(task.priority.color)
                    }
                    .padding(.vertical, 2)
                    .cardStyle()
                }

                if appState.todayTasks.count > 5 {
                    Text("+ ещё \(appState.todayTasks.count - 5)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var habitsSection: some View {
        Group {
            if !appState.habits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Привычки")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(appState.habitsCompletedToday)/\(appState.habits.count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(appState.habits) { habit in
                                let done = habit.isCompletedToday()
                                Button {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                        appState.toggleHabitToday(habitId: habit.id)
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(done ? AnyShapeStyle(Color.white.opacity(0.7)) : AnyShapeStyle(.ultraThinMaterial))
                                                .environment(\.colorScheme, .dark)
                                                .frame(width: 48, height: 48)
                                            if !done {
                                                Circle()
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                                    .frame(width: 48, height: 48)
                                            }
                                            Image(systemName: done ? "checkmark" : habit.icon)
                                                .font(.system(size: done ? 18 : 20, weight: done ? .bold : .regular))
                                                .foregroundStyle(done ? Color(red: 0.1, green: 0.06, blue: 0.18) : .white)
                                                .contentTransition(.symbolEffect(.replace))
                                        }
                                        Text(habit.title)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(done ? .white : .white.opacity(0.5))
                                            .lineLimit(1)
                                        HStack(spacing: 2) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 8))
                                            Text("\(habit.currentStreak)")
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                        }
                                        .foregroundStyle(.white.opacity(0.3))
                                    }
                                    .frame(width: 72)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var goalsSnapshot: some View {
        Group {
            if !appState.goals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Цели")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    ForEach(appState.goals.prefix(3)) { goal in
                        HStack(spacing: 14) {
                            Image(systemName: goal.category.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .environment(\.colorScheme, .dark)
                                        Circle()
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    }
                                )

                            VStack(alignment: .leading, spacing: 5) {
                                Text(goal.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                ProgressView(value: goal.progress)
                                    .tint(.white)
                            }

                            Text("\(Int(goal.progress * 100))%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 40, alignment: .trailing)
                        }
                        .cardStyle()
                    }
                }
            }
        }
    }

    private var weekActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Активность за неделю")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button { showWeeklyReview = true } label: {
                    Text("Обзор")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            WeekBarChart(data: weeklyTaskData(from: appState))
        }
        .cardStyle()
    }
}
