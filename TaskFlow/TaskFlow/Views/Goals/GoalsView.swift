import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateGoal = false
    @State private var selectedGoal: YearGoal? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if appState.goals.isEmpty {
                        EmptyStateView(
                            icon: "target",
                            title: "Поставьте цель на год",
                            subtitle: "Определите что вы хотите изменить в себе. Каждый день делайте один шаг к мечте.",
                            actionTitle: "Создать цель",
                            action: { showCreateGoal = true }
                        )
                    } else {
                        overallProgress
                        ForEach(appState.goals) { goal in
                            GoalCard(goal: goal)
                                .onTapGesture { selectedGoal = goal }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { appState.deleteGoal(goal) }
                                    } label: { Label("Удалить", systemImage: "trash") }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Цели на год")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateGoal = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalView().environmentObject(appState)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailSheet(goal: goal).environmentObject(appState)
            }
        }
    }

    private var overallProgress: some View {
        let avg = appState.goals.map { $0.progress }.reduce(0, +) / max(Double(appState.goals.count), 1)
        return HStack(spacing: 16) {
            ProgressRing(progress: avg, size: 64, lineWidth: 7)
            VStack(alignment: .leading, spacing: 4) {
                Text("Общий прогресс")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("\(appState.goals.count) целей активно")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .cardStyle()
    }
}

struct GoalCard: View {
    let goal: YearGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 20))
                    .frame(width: 42, height: 42)
                    .background(.secondary.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    Text(goal.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("\(goal.daysRemaining) дн.")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            ProgressView(value: goal.progress)
                .tint(.primary)

            HStack(spacing: 14) {
                Label("\(goal.streakDays) дн.", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .medium))

                Text("·").foregroundStyle(Color(UIColor.separator))

                Text(goal.dailyAction)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                if goal.isTodayCompleted() {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                } else {
                    Text("Не отмечено")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red)
                }
            }
        }
        .cardStyle()
    }
}

struct GoalDetailSheet: View {
    let goal: YearGoal
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: goal.category.icon)
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .background(.secondary.opacity(0.1), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.category.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(goal.daysRemaining) дней осталось")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        ProgressRing(progress: goal.progress, size: 50, lineWidth: 5)
                    }
                }

                if !goal.description.isEmpty {
                    Section("Описание") {
                        Text(goal.description)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                    }
                }

                Section("Ежедневное действие") {
                    Label(goal.dailyAction, systemImage: "repeat")
                        .font(.system(size: 15))
                }

                Section {
                    if !goal.isTodayCompleted() {
                        Button {
                            withAnimation { appState.checkInGoal(goalId: goal.id) }
                            dismiss()
                        } label: {
                            Label("Отметить сегодня", systemImage: "checkmark.circle")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.primary)
                        .listRowBackground(Color.clear)
                    } else {
                        Label("Выполнено сегодня", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }

                Section("Статистика") {
                    HStack {
                        statBlock("\(goal.streakDays)", "Серия")
                        Divider()
                        statBlock("\(goal.completedDays.count)", "Всего дней")
                        Divider()
                        statBlock("\(goal.daysRemaining)", "Осталось")
                    }
                    .frame(height: 60)
                }

                if !goal.milestones.isEmpty {
                    Section("Вехи (\(goal.milestones.filter { $0.isCompleted }.count)/\(goal.milestones.count))") {
                        ForEach(goal.milestones) { ms in
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation {
                                        appState.toggleMilestone(goalId: goal.id, milestoneId: ms.id)
                                    }
                                } label: {
                                    Image(systemName: ms.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(ms.isCompleted ? .secondary : .primary)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ms.title)
                                        .font(.system(size: 15))
                                        .strikethrough(ms.isCompleted)
                                    Text(shortRuDate(ms.targetDate))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        ProgressView(
                            value: Double(goal.milestones.filter { $0.isCompleted }.count),
                            total: Double(goal.milestones.count)
                        )
                        .tint(.primary)
                    }
                }

                Section("Календарь") {
                    StreakCalendarView(completedDates: goal.completedDays)
                        .padding(.vertical, 4)
                }

                Section {
                    Button(role: .destructive) {
                        appState.deleteGoal(goal)
                        dismiss()
                    } label: {
                        Label("Удалить цель", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func statBlock(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CreateGoalView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: GoalCategory = .health
    @State private var dailyAction = ""
    @State private var targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var milestones: [String] = ["", "", ""]
    @State private var currentStep = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Шаг \(currentStep + 1) из 3")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    ProgressView(value: Double(currentStep + 1), total: 3)
                        .tint(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0: goalInfoStep
                        case 1: goalActionStep
                        default: goalMilestonesStep
                        }
                    }
                    .padding(24)
                }

                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button("Назад") { withAnimation { currentStep -= 1 } }
                            .buttonStyle(.bordered)
                    }
                    Button(currentStep < 2 ? "Далее" : "Создать") {
                        withAnimation {
                            if currentStep < 2 { currentStep += 1 }
                            else { saveGoal() }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .frame(maxWidth: .infinity)
                    .disabled(currentStep == 0 && title.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.regularMaterial)
            }
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var goalInfoStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Цель", systemImage: "target")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            TextField("Например: Выучить английский", text: $title)
                .textFieldStyle(.roundedBorder)

            Text("Описание")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: $description)
                .font(.system(size: 15))
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .inputStyle()

            Text("Категория")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GoalCategory.allCases) { cat in
                    Button {
                        withAnimation { category = cat }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon).font(.system(size: 13))
                            Text(cat.rawValue).font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            category == cat
                            ? AnyShapeStyle(Color.primary.opacity(0.1))
                            : AnyShapeStyle(Color.clear),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(category == cat ? Color.primary : Color(UIColor.separator), lineWidth: 1)
                        )
                        .foregroundStyle(category == cat ? .primary : .secondary)
                    }
                }
            }
        }
    }

    private var goalActionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Ежедневное действие", systemImage: "repeat")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Что вы будете делать каждый день для этой цели?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Например: 30 минут чтения", text: $dailyAction)
                .textFieldStyle(.roundedBorder)

            Label("Дата достижения", systemImage: "calendar")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .padding(.top, 8)
            DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.primary)
                .cardStyle()
        }
    }

    private var goalMilestonesStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            goalMilestonesHeader
            goalMilestonesList
            addMilestoneButton
        }
    }

    private var goalMilestonesHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Вехи", systemImage: "flag.fill")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Промежуточные цели на пути к результату")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var goalMilestonesList: some View {
        let count = milestones.count
        return ForEach(0..<count, id: \.self) { index in
            self.milestoneRow(at: index)
        }
    }

    private func milestoneRow(at index: Int) -> some View {
        MilestoneInputRow(index: index, text: $milestones[index], canDelete: milestones.count > 1) {
            withAnimation { milestones.remove(at: index) }
        }
    }

    private var addMilestoneButton: some View {
        Button {
            withAnimation { milestones.append("") }
        } label: {
            Label("Добавить веху", systemImage: "plus.circle.fill")
                .font(.system(size: 15, weight: .medium))
        }
    }

    private func saveGoal() {
        let interval = targetDate.timeIntervalSince(Date())
        let validMs = milestones.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let ms = validMs.enumerated().map { i, title in
            Milestone(
                title: title,
                targetDate: Date().addingTimeInterval(interval * Double(i + 1) / Double(max(validMs.count, 1)))
            )
        }
        let goal = YearGoal(
            title: title,
            description: description,
            category: category,
            startDate: Date(),
            targetDate: targetDate,
            milestones: ms,
            dailyAction: dailyAction.isEmpty ? "Работать над целью" : dailyAction
        )
        appState.addGoal(goal)
        dismiss()
    }
}

struct MilestoneInputRow: View {
    let index: Int
    @Binding var text: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 26, height: 26)
                .background(.primary, in: Circle())
            TextField("Веха \(index + 1)", text: $text)
                .textFieldStyle(.roundedBorder)
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                }
            }
        }
    }
}
