import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("selectedAppearance") private var selectedAppearance = 0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("dailyReminderHour") private var dailyReminderHour = 9
    @AppStorage("dailyReminderMinute") private var dailyReminderMinute = 0
    @AppStorage("weekStartsMonday") private var weekStartsMonday = true
    @AppStorage("showCompletedTasks") private var showCompletedTasks = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoArchiveDays") private var autoArchiveDays = 30
    @State private var showExport = false
    @State private var showResetAlert = false
    @State private var showOnboardingReset = false
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Оформление") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Тема")
                            .font(.system(size: 14, weight: .medium))
                        Picker("", selection: $selectedAppearance) {
                            Text("Авто").tag(0)
                            Text("Светлая").tag(1)
                            Text("Тёмная").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Уведомления") {
                    Toggle("Уведомления", isOn: $notificationsEnabled)
                        .tint(.primary)

                    if notificationsEnabled {
                        HStack {
                            Text("Ежедневное напоминание")
                            Spacer()
                            HStack(spacing: 4) {
                                Picker("Час", selection: $dailyReminderHour) {
                                    ForEach(0..<24, id: \.self) { h in
                                        Text(String(format: "%02d", h)).tag(h)
                                    }
                                }
                                .pickerStyle(.menu)
                                Text(":")
                                    .foregroundStyle(.secondary)
                                Picker("Мин", selection: $dailyReminderMinute) {
                                    ForEach([0, 15, 30, 45], id: \.self) { m in
                                        Text(String(format: "%02d", m)).tag(m)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }

                Section("Задачи") {
                    Toggle("Показывать выполненные", isOn: $showCompletedTasks)
                        .tint(.primary)

                    HStack {
                        Text("Автоархивация через")
                        Spacer()
                        Picker("", selection: $autoArchiveDays) {
                            Text("7 дней").tag(7)
                            Text("14 дней").tag(14)
                            Text("30 дней").tag(30)
                            Text("60 дней").tag(60)
                            Text("Никогда").tag(9999)
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Общие") {
                    Toggle("Тактильная отдача", isOn: $hapticFeedback)
                        .tint(.primary)

                    Toggle("Неделя с понедельника", isOn: $weekStartsMonday)
                        .tint(.primary)
                }

                Section("Данные") {
                    Button {
                        exportText = appState.exportData(format: .json)
                        showExport = true
                    } label: {
                        Label("Экспорт данных", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showOnboardingReset = true
                    } label: {
                        Label("Показать онбординг", systemImage: "questionmark.circle")
                    }

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Сбросить все данные", systemImage: "trash")
                    }
                }

                Section("Хранилище") {
                    HStack {
                        Text("Задачи")
                        Spacer()
                        Text("\(appState.tasks.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Цели")
                        Spacer()
                        Text("\(appState.goals.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Привычки")
                        Spacer()
                        Text("\(appState.habits.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Записи журнала")
                        Spacer()
                        Text("\(appState.journal.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Заметки")
                        Spacer()
                        Text("\(appState.notes.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .alert("Сбросить все данные?", isPresented: $showResetAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Сбросить", role: .destructive) {
                    appState.tasks.removeAll()
                    appState.goals.removeAll()
                    appState.habits.removeAll()
                    var j = appState.journal; j.removeAll(); appState.journal = j
                    var n = appState.notes; n.removeAll(); appState.notes = n
                }
            } message: {
                Text("Это действие нельзя отменить. Все задачи, цели, привычки, записи и заметки будут удалены.")
            }
            .alert("Показать онбординг?", isPresented: $showOnboardingReset) {
                Button("Отмена", role: .cancel) {}
                Button("Показать") { appState.hasCompletedOnboarding = false }
            }
            .sheet(isPresented: $showExport) {
                NavigationStack {
                    ScrollView {
                        Text(exportText)
                            .font(.system(size: 11, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("Экспорт")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Закрыть") { showExport = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Копировать") {
                                UIPasteboard.general.string = exportText
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TaskTemplatesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    private let templates: [(icon: String, title: String, description: String, category: TaskCategory, steps: [String])] = [
        ("sunrise.fill", "Утренний ритуал", "Начните день правильно", .personal,
         ["Подъём без отсрочки", "Стакан воды", "5 минут медитации", "Зарядка 10 минут", "Планирование дня"]),
        ("book.fill", "Чтение", "Прочитать 30 страниц", .education,
         ["Выбрать книгу", "Найти тихое место", "Читать 25 минут", "Записать ключевые мысли"]),
        ("figure.run", "Тренировка", "Спортивная тренировка", .sport,
         ["Разминка 5 минут", "Основная часть 30 минут", "Растяжка 10 минут", "Душ", "Записать результат"]),
        ("laptopcomputer", "Рабочий проект", "Работа над проектом", .work,
         ["Определить задачи", "Установить таймер 45 мин", "Фокусированная работа", "Перерыв", "Обзор прогресса"]),
        ("brain.head.profile", "Медитация", "Практика осознанности", .health,
         ["Найти тихое место", "Сесть удобно", "Дыхательные упражнения", "10 минут медитации", "Записать ощущения"]),
        ("banknote.fill", "Финансовый обзор", "Еженедельный обзор финансов", .finance,
         ["Проверить расходы", "Обновить бюджет", "Оплатить счета", "Отложить на цели", "Планирование на неделю"]),
        ("paintbrush.fill", "Творческий проект", "Время для творчества", .creativity,
         ["Собрать вдохновение", "Подготовить материалы", "Работать 30 минут", "Сделать перерыв", "Оценить результат"]),
        ("moon.fill", "Вечерний обзор", "Завершите день с пользой", .personal,
         ["Обзор выполненных задач", "Запись в журнал", "Подготовка плана на завтра", "Медитация/дыхание", "Режим сна"])
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(templates.indices, id: \.self) { i in
                        let t = templates[i]
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: t.icon)
                                    .font(.system(size: 20))
                                    .frame(width: 40, height: 40)
                                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(t.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(t.steps.count) шагов")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .pillStyle()
                            }

                            HStack(spacing: 6) {
                                ForEach(t.steps.prefix(3), id: \.self) { step in
                                    Text(step)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                                if t.steps.count > 3 {
                                    Text("+\(t.steps.count - 3)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Button {
                                createFromTemplate(t)
                            } label: {
                                Text("Создать задачу")
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.primary)
                            .controlSize(.small)
                        }
                        .cardStyle()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Шаблоны")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func createFromTemplate(_ t: (icon: String, title: String, description: String, category: TaskCategory, steps: [String])) {
        let task = TaskItem(
            title: t.title,
            description: t.description,
            steps: t.steps.map { TaskStep(title: $0) },
            startDate: Date(),
            priority: .medium,
            category: t.category
        )
        appState.addTask(task)
        dismiss()
    }
}

struct WeeklyReviewView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    let summary = appState.weekSummary()
                    let score = appState.productivityScore()

                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 40))
                            .foregroundStyle(.primary)
                        Text("Обзор недели")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("\(shortRuDate(summary.startDate)) — \(shortRuDate(summary.endDate))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    HStack(spacing: 16) {
                        ProgressRing(progress: score.overall, size: 80, lineWidth: 8)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Оценка: \(score.grade)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text(score.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .cardStyle()

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        reviewStat("checkmark.circle.fill", "\(summary.totalTasksCompleted)", "Выполнено")
                        reviewStat("plus.circle.fill", "\(summary.totalTasksCreated)", "Создано")
                        reviewStat("flame.fill", "\(summary.streakDays)", "Серия")
                        reviewStat("timer", "\(summary.totalFocusMinutes)м", "Фокус")
                        reviewStat("face.smiling", String(format: "%.1f", summary.avgMood), "Настроение")
                        reviewStat("repeat.circle.fill", "\(Int(summary.habitCompletionRate * 100))%", "Привычки")
                    }

                    WeekBarChart(data: weeklyTaskData(from: appState))
                        .cardStyle()

                    if let best = summary.bestDay {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Лучший день")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(formattedRuDate(best))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .cardStyle()
                    }

                    if let topCat = summary.topCategory {
                        HStack(spacing: 12) {
                            Image(systemName: topCat.icon)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Топ категория")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(topCat.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Советы на следующую неделю")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))

                        if score.taskCompletion < 0.5 {
                            tipRow("exclamationmark.triangle.fill", "Попробуйте создавать меньше задач, но выполнять все")
                        }
                        if score.habitConsistency < 0.7 {
                            tipRow("repeat.circle.fill", "Уделите больше внимания ежедневным привычкам")
                        }
                        if score.focusTime < 0.3 {
                            tipRow("timer", "Используйте таймер для фокусированной работы")
                        }
                        if score.streak < 0.3 {
                            tipRow("flame.fill", "Старайтесь не пропускать дни — серия мотивирует")
                        }
                        if score.overall >= 0.8 {
                            tipRow("star.fill", "Отличная работа! Продолжайте в том же духе")
                        }
                    }
                    .cardStyle()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func reviewStat(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16))
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func tipRow(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 24, height: 24)
                .background(.secondary.opacity(0.1), in: Circle())
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
    }
}
