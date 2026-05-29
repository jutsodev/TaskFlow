import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateEntry = false
    @State private var selectedEntry: JournalEntry? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if appState.journal.isEmpty {
                        EmptyStateView(
                            icon: "book.closed.fill",
                            title: "Ведите дневник",
                            subtitle: "Записывайте мысли, отмечайте настроение и то, за что вы благодарны",
                            actionTitle: "Написать",
                            action: { showCreateEntry = true }
                        )
                    } else {
                        moodOverview
                        ForEach(appState.journal.sorted { $0.date > $1.date }) { entry in
                            journalCard(entry)
                                .onTapGesture { selectedEntry = entry }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { appState.deleteJournalEntry(entry) }
                                    } label: { Label("Удалить", systemImage: "trash") }
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Журнал")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateEntry) {
                CreateJournalEntryView().environmentObject(appState)
            }
            .sheet(item: $selectedEntry) { entry in
                JournalDetailSheet(entry: entry).environmentObject(appState)
            }
        }
    }

    private var moodOverview: some View {
        let recent = appState.journal.sorted { $0.date > $1.date }.prefix(7)
        let avg = recent.isEmpty ? 0.0 : Double(recent.map { $0.mood.score }.reduce(0, +)) / Double(recent.count)

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Среднее настроение")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(String(format: "%.1f / 5.0", avg))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("за последние \(recent.count) записей")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(Array(recent)) { entry in
                    VStack(spacing: 2) {
                        Image(systemName: entry.mood.icon)
                            .font(.system(size: 14))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.primary)
                            .frame(width: 6, height: CGFloat(entry.mood.score) * 6)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func journalCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedRuDate(entry.date))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    let fmt = DateFormatter()
                    let _ = { fmt.locale = Locale(identifier: "ru_RU"); fmt.dateFormat = "EEEE" }()
                    Text(fmt.string(from: entry.date).capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: entry.mood.icon).font(.system(size: 14))
                    Text(entry.mood.rawValue).font(.system(size: 12, weight: .medium))
                }
                .pillStyle()
            }

            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .lineLimit(3)
                    .foregroundStyle(.secondary)
            }

            if !entry.gratitude.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill").font(.system(size: 10))
                    Text("\(entry.gratitude.count) благодарностей")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }

            if !entry.highlights.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill").font(.system(size: 10))
                    Text("\(entry.highlights.count) достижений")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

struct JournalDetailSheet: View {
    let entry: JournalEntry
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: entry.mood.icon).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.mood.rawValue)
                                .font(.system(size: 17, weight: .semibold))
                            Text(formattedRuDate(entry.date))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !entry.text.isEmpty {
                    Section("Запись") {
                        Text(entry.text)
                            .font(.system(size: 15))
                            .lineSpacing(5)
                    }
                }

                if !entry.gratitude.isEmpty {
                    Section("Благодарности") {
                        ForEach(entry.gratitude, id: \.self) { item in
                            Label(item, systemImage: "heart.fill")
                                .font(.system(size: 14))
                        }
                    }
                }

                if !entry.highlights.isEmpty {
                    Section("Достижения дня") {
                        ForEach(entry.highlights, id: \.self) { item in
                            Label(item, systemImage: "star.fill")
                                .font(.system(size: 14))
                        }
                    }
                }

                Section("Статистика дня") {
                    let dayTasks = appState.tasksForDate(entry.date)
                    Label("Задач: \(dayTasks.filter { $0.isCompleted }.count)/\(dayTasks.count)", systemImage: "checklist")
                    let fmtKey = DateFormatter()
                    let _ = fmtKey.dateFormat = "yyyy-MM-dd"
                    let key = fmtKey.string(from: entry.date)
                    let hDone = appState.habits.filter { $0.completedDates.contains(key) }.count
                    Label("Привычек: \(hDone)/\(appState.habits.count)", systemImage: "repeat.circle.fill")
                }

                Section {
                    Button(role: .destructive) {
                        appState.deleteJournalEntry(entry)
                        dismiss()
                    } label: {
                        Label("Удалить запись", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

struct CreateJournalEntryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var currentStep = 0
    @State private var mood: Mood = .neutral
    @State private var text = ""
    @State private var gratitude: [String] = ["", "", ""]
    @State private var highlights: [String] = [""]
    @State private var entryDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Шаг \(currentStep + 1) из 4")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    ProgressView(value: Double(currentStep + 1), total: 4)
                        .tint(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0: moodStep
                        case 1: textStep
                        case 2: gratitudeStep
                        default: highlightsStep
                        }
                    }
                    .padding(24)
                }

                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button("Назад") { withAnimation { currentStep -= 1 } }
                            .buttonStyle(.bordered)
                    }
                    Button(currentStep < 3 ? "Далее" : "Сохранить") {
                        withAnimation {
                            if currentStep < 3 { currentStep += 1 }
                            else { save() }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.regularMaterial)
            }
            .navigationTitle("Новая запись")
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

    private var moodStep: some View {
        VStack(spacing: 24) {
            Text("Как ваше настроение?")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            HStack(spacing: 12) {
                ForEach(Mood.allCases) { m in
                    Button {
                        withAnimation { mood = m }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: m.icon)
                                .font(.system(size: 28))
                                .frame(width: 52, height: 52)
                                .background(
                                    mood == m ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.clear),
                                    in: Circle()
                                )
                                .overlay(Circle().stroke(mood == m ? Color.clear : Color(UIColor.separator), lineWidth: 1))
                                .foregroundStyle(mood == m ? Color(.systemBackground) : .primary)
                            Text(m.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(mood == m ? .primary : .secondary)
                        }
                    }
                }
            }

            DatePicker("Дата", selection: $entryDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(.primary)
        }
    }

    private var textStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Что у вас на душе?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("Запишите мысли, события дня, рефлексию")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.system(size: 16))
                .frame(minHeight: 200)
                .scrollContentBackground(.hidden)
                .inputStyle()
        }
    }

    private var gratitudeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("За что вы благодарны?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("3 вещи за которые вы благодарны сегодня")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(gratitude.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    TextField("Благодарность \(i + 1)", text: $gratitude[i])
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var highlightsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            highlightsHeader
            highlightsList
            addHighlightButton
        }
    }

    private var highlightsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Достижения дня")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("Чем вы гордитесь сегодня?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var highlightsList: some View {
        let count = highlights.count
        return ForEach(0..<count, id: \.self) { i in
            self.highlightRow(at: i)
        }
    }

    private func highlightRow(at i: Int) -> some View {
        HighlightInputRow(index: i, text: $highlights[i], canDelete: highlights.count > 1) {
            withAnimation { highlights.remove(at: i) }
        }
    }

    private var addHighlightButton: some View {
        Button {
            withAnimation { highlights.append("") }
        } label: {
            Label("Добавить", systemImage: "plus.circle.fill")
                .font(.system(size: 14, weight: .medium))
        }
    }

    private func save() {
        let entry = JournalEntry(
            date: entryDate,
            mood: mood,
            text: text,
            gratitude: gratitude.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            highlights: highlights.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        )
        appState.addJournalEntry(entry)
        dismiss()
    }
}

struct HighlightInputRow: View {
    let index: Int
    @Binding var text: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color(.systemBackground))
                .frame(width: 24, height: 24)
                .background(.primary, in: Circle())
            TextField("Достижение", text: $text)
                .textFieldStyle(.roundedBorder)
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                }
            }
        }
    }
}
