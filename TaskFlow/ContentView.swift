import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house.fill") }
                .tag(0)
            TasksView()
                .tabItem { Label("Задачи", systemImage: "checklist") }
                .tag(1)
            CalendarView()
                .tabItem { Label("Календарь", systemImage: "calendar") }
                .tag(2)
            GoalsView()
                .tabItem { Label("Цели", systemImage: "target") }
                .tag(3)
            HabitsView()
                .tabItem { Label("Привычки", systemImage: "repeat.circle.fill") }
                .tag(4)
            FocusTimerView()
                .tabItem { Label("Фокус", systemImage: "timer") }
                .tag(5)
            JournalView()
                .tabItem { Label("Журнал", systemImage: "book.fill") }
                .tag(6)
            NotesView()
                .tabItem { Label("Заметки", systemImage: "note.text") }
                .tag(7)
            MoreView()
                .tabItem { Label("Ещё", systemImage: "ellipsis") }
                .tag(8)
        }
        .tint(.primary)
    }
}

struct MoreView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        StatisticsView().environmentObject(appState)
                    } label: {
                        Label("Статистика", systemImage: "chart.bar.fill")
                    }

                    NavigationLink {
                        SearchView().environmentObject(appState)
                    } label: {
                        Label("Поиск", systemImage: "magnifyingglass")
                    }

                    NavigationLink {
                        AchievementsView().environmentObject(appState)
                    } label: {
                        Label("Достижения", systemImage: "trophy.fill")
                    }
                }

                Section {
                    NavigationLink {
                        ProfileView().environmentObject(appState)
                    } label: {
                        HStack(spacing: 14) {
                            AvatarView(data: appState.avatarData, size: 44, initials: appState.userInitials)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.userName.isEmpty ? "Пользователь" : appState.userName)
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Профиль и настройки")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Информация") {
                    NavigationLink {
                        AboutAppView()
                    } label: {
                        Label("О приложении", systemImage: "info.circle")
                    }

                    NavigationLink {
                        TipsView()
                    } label: {
                        Label("Советы", systemImage: "lightbulb.fill")
                    }
                }
            }
            .navigationTitle("Ещё")
        }
    }
}

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                let achvs = appState.achievements()
                let unlocked = achvs.filter { $0.isUnlocked }.count

                VStack(spacing: 8) {
                    Text("\(unlocked)/\(achvs.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("достижений разблокировано")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(unlocked), total: Double(achvs.count))
                        .tint(.primary)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 8)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(achvs) { ach in
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(ach.isUnlocked ? Color.primary.opacity(0.08) : Color.secondary.opacity(0.04))
                                    .frame(width: 60, height: 60)
                                Circle()
                                    .trim(from: 0, to: ach.progress)
                                    .stroke(
                                        ach.isUnlocked ? Color.primary : Color(UIColor.separator),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(-90))
                                Image(systemName: ach.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(ach.isUnlocked ? .primary : .tertiary)
                            }

                            VStack(spacing: 4) {
                                Text(ach.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(ach.isUnlocked ? .primary : .tertiary)
                                Text(ach.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Text(ach.requirement)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.tertiary)
                            }

                            if !ach.isUnlocked {
                                ProgressView(value: ach.progress)
                                    .tint(.primary)
                            }
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Достижения")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutAppView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                LogoView(size: 80)

                VStack(spacing: 8) {
                    Text("TaskFlow")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Версия 1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    featureRow("checklist", "Задачи", "Создавайте задачи с этапами, приоритетами, категориями и отслеживанием времени")
                    featureRow("target", "Цели на год", "Ставьте долгосрочные цели с вехами и ежедневными действиями")
                    featureRow("repeat.circle.fill", "Привычки", "Выработайте полезные привычки и отслеживайте серии")
                    featureRow("timer", "Фокус-таймер", "Таймер обратного отсчёта и секундомер для продуктивной работы")
                    featureRow("calendar", "Календарь", "Визуальный календарь с задачами, целями и привычками")
                    featureRow("book.fill", "Журнал", "Ведите дневник настроения с благодарностями и достижениями")
                    featureRow("note.text", "Заметки", "Записывайте идеи с тегами, закреплением и поиском")
                    featureRow("chart.bar.fill", "Статистика", "Аналитика продуктивности с графиками и оценками")
                    featureRow("magnifyingglass", "Поиск", "Глобальный поиск по всем данным приложения")
                    featureRow("trophy.fill", "Достижения", "12 бейджей мотивации за ваш прогресс")
                }
                .cardStyle()

                VStack(spacing: 8) {
                    Text("Сделано с ❤️")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("jutsodev")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.top, 8)
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureRow(_ icon: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 34, height: 34)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(desc).font(.system(size: 13)).foregroundStyle(.secondary).lineSpacing(3)
            }
        }
    }
}

struct TipsView: View {
    private let tips: [(icon: String, title: String, text: String)] = [
        ("sunrise.fill", "Утренний ритуал",
         "Начинайте каждый день с просмотра задач и целей. Определите 3 главные задачи на день. Исследования показывают, что утреннее планирование повышает продуктивность на 25%."),
        ("brain.head.profile", "Правило 2 минут",
         "Если задача занимает меньше 2 минут — сделайте её сразу. Не откладывайте мелочи, они накапливаются и создают ментальный груз."),
        ("timer", "Техника помидора",
         "Работайте фокусированно 25 минут, затем отдыхайте 5 минут. Через 4 цикла сделайте длинный перерыв 15-30 минут. Используйте встроенный таймер."),
        ("target", "SMART цели",
         "Ставьте цели по формуле SMART: Specific (конкретная), Measurable (измеримая), Achievable (достижимая), Relevant (значимая), Time-bound (ограниченная по времени)."),
        ("repeat.circle.fill", "66 дней для привычки",
         "Исследования Университетского колледжа Лондона показали, что для формирования привычки нужно в среднем 66 дней. Не сдавайтесь раньше!"),
        ("moon.fill", "Вечерний обзор",
         "Перед сном запишите в журнал: 3 благодарности, главное достижение дня, план на завтра. Это помогает мозгу обрабатывать информацию во сне."),
        ("figure.walk", "Правило 1%",
         "Улучшайтесь на 1% каждый день. За год это даёт улучшение в 37 раз. Маленькие шаги — большие результаты."),
        ("battery.100", "Энергия важнее времени",
         "Распределяйте сложные задачи на пики энергии (обычно утро). Рутинные — на спады. Знайте свой ритм."),
        ("arrow.3.trianglepath", "Петля обратной связи",
         "Каждую неделю анализируйте статистику. Что работает? Что нет? Корректируйте подход. Без анализа — нет прогресса."),
        ("star.fill", "Награждайте себя",
         "За достижение вех и целей — награждайте себя. Мозг запоминает связь «усилие → награда» и начинает стремиться к повторению.")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(tips.indices, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: tips[i].icon)
                                .font(.system(size: 18))
                                .frame(width: 36, height: 36)
                                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
                            Text(tips[i].title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        Text(tips[i].text)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(5)
                    }
                    .cardStyle()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Советы")
        .navigationBarTitleDisplayMode(.inline)
    }
}
