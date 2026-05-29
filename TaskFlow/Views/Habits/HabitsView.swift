import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddHabit = false
    @State private var selectedHabit: HabitItem? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if appState.habits.isEmpty {
                        EmptyStateView(
                            icon: "repeat.circle.fill",
                            title: "Создайте привычки",
                            subtitle: "Отмечайте каждый день и следите за серией выполнений",
                            actionTitle: "Добавить привычку",
                            action: { showAddHabit = true }
                        )
                    } else {
                        todayProgress
                        habitsList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Привычки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddHabit = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitSheet().environmentObject(appState)
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailSheet(habit: habit).environmentObject(appState)
            }
        }
    }

    private var todayProgress: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Сегодня")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("\(appState.habitsCompletedToday) из \(appState.habits.count) выполнено")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(appState.habitsCompletedToday), total: max(Double(appState.habits.count), 1))
                    .tint(.primary)
            }
            ProgressRing(
                progress: appState.habits.isEmpty ? 0 : Double(appState.habitsCompletedToday) / Double(appState.habits.count)
            )
        }
        .cardStyle()
    }

    private var habitsList: some View {
        VStack(spacing: 10) {
            ForEach(appState.habits) { habit in
                HStack(spacing: 14) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            appState.toggleHabitToday(habitId: habit.id)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(habit.isCompletedToday() ? Color.primary.opacity(0.1) : Color.clear)
                                .frame(width: 44, height: 44)
                            Circle()
                                .stroke(habit.isCompletedToday() ? Color.primary : Color.separator, lineWidth: 2)
                                .frame(width: 44, height: 44)
                            Image(systemName: habit.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(habit.isCompletedToday() ? .primary : .secondary)
                            if habit.isCompletedToday() {
                                Circle()
                                    .fill(.primary)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(Color(.systemBackground))
                                    )
                                    .offset(x: 16, y: -16)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(habit.isCompletedToday() ? .secondary : .primary)
                        HStack(spacing: 8) {
                            Label("\(habit.currentStreak) дн.", systemImage: "flame.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text("·").foregroundStyle(.separator)
                            Text("Всего: \(habit.totalCompleted)")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    weekDots(habit: habit)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                .onTapGesture { selectedHabit = habit }
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation { appState.deleteHabit(habit) }
                    } label: { Label("Удалить", systemImage: "trash") }
                }
            }
        }
    }

    private func weekDots(habit: HabitItem) -> some View {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = calendar.startOfDay(for: Date())

        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { offset in
                let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today) ?? today
                let done = habit.completedDates.contains(fmt.string(from: date))
                Circle()
                    .fill(done ? Color.primary : Color.secondary.opacity(0.15))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct AddHabitSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var selectedIcon = "star.fill"

    private let icons = [
        "star.fill", "book.fill", "figure.run", "drop.fill", "moon.fill",
        "sun.max.fill", "heart.fill", "brain.head.profile", "music.note",
        "paintbrush.fill", "cup.and.saucer.fill", "leaf.fill",
        "dumbbell.fill", "pencil.and.outline", "phone.down.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Например: Чтение 30 мин", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Иконка")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    withAnimation { selectedIcon = icon }
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 22))
                                        .frame(width: 48, height: 48)
                                        .background(
                                            selectedIcon == icon
                                            ? AnyShapeStyle(Color.primary.opacity(0.1))
                                            : AnyShapeStyle(Color.clear),
                                            in: Circle()
                                        )
                                        .overlay(
                                            Circle().stroke(
                                                selectedIcon == icon ? .primary : .separator,
                                                lineWidth: 1.5
                                            )
                                        )
                                        .foregroundStyle(selectedIcon == icon ? .primary : .secondary)
                                }
                            }
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Предпросмотр")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(.secondary.opacity(0.1), in: Circle())
                            Text(title.isEmpty ? "Название привычки" : title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(title.isEmpty ? .tertiary : .primary)
                        }
                    }
                    .cardStyle()

                    Button {
                        if !title.isEmpty {
                            let habit = HabitItem(title: title, icon: selectedIcon)
                            appState.addHabit(habit)
                            dismiss()
                        }
                    } label: {
                        Text("Создать привычку")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
                    .disabled(title.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

struct HabitDetailSheet: View {
    let habit: HabitItem
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: habit.icon)
                            .font(.system(size: 28))
                            .frame(width: 56, height: 56)
                            .background(.secondary.opacity(0.1), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.title)
                                .font(.system(size: 18, weight: .semibold))
                            Text("Создано: \(formattedRuDate(habit.createdAt))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Статистика") {
                    HStack {
                        statBlock("\(habit.currentStreak)", "Серия")
                        Divider()
                        statBlock("\(habit.totalCompleted)", "Всего")
                        Divider()
                        let days = Calendar.current.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 0
                        let rate = days > 0 ? Int(Double(habit.totalCompleted) / Double(days) * 100) : 0
                        statBlock("\(rate)%", "Процент")
                    }
                    .frame(height: 60)
                }

                Section("Активность (35 дней)") {
                    StreakCalendarView(completedDates: habit.completedDates)
                        .padding(.vertical, 4)
                }

                Section {
                    if !habit.isCompletedToday() {
                        Button {
                            withAnimation { appState.toggleHabitToday(habitId: habit.id) }
                            dismiss()
                        } label: {
                            Label("Отметить сегодня", systemImage: "checkmark.circle")
                        }
                    } else {
                        Label("Выполнено сегодня", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        appState.deleteHabit(habit)
                        dismiss()
                    } label: {
                        Label("Удалить привычку", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(habit.title)
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
