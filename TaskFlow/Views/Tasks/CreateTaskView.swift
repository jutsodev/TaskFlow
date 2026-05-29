import SwiftUI

struct CreateTaskView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var currentStep = 0
    @State private var title = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var steps: [String] = [""]
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasEndDate = false
    @State private var priority: Priority = .medium
    @State private var category: TaskCategory = .personal
    @State private var repeatMode: RepeatMode = .none

    private let totalSteps = 6

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Шаг \(currentStep + 1) из \(totalSteps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(stepTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .tint(.primary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        stepContent
                    }
                    .padding(24)
                }

                bottomNav
            }
            .navigationTitle("Новая задача")
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

    private var stepTitle: String {
        ["Название", "Описание", "Этапы", "Дата", "Параметры", "Дополнительно"][currentStep]
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: titleStep
        case 1: descriptionStep
        case 2: stepsStep
        case 3: dateStep
        case 4: parametersStep
        case 5: extrasStep
        default: EmptyView()
        }
    }

    private var titleStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Название задачи", systemImage: "pencil.line")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Дайте задаче краткое и понятное название")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Например: Подготовить презентацию", text: $title)
                .font(.system(size: 17))
                .textFieldStyle(.roundedBorder)
        }
        
    }

    private var descriptionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Описание", systemImage: "doc.text")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Опишите подробнее что нужно сделать")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: $description)
                .font(.system(size: 16))
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .inputStyle()
        }
        
    }

    private var stepsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepsHeader
            stepsList
            addStepButton
        }
    }

    private var stepsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Этапы выполнения", systemImage: "list.number")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Разбейте задачу на конкретные шаги")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var stepsList: some View {
        ForEach(0..<steps.count, id: \.self) { index in
            StepInputRow(index: index, text: $steps[index], canDelete: steps.count > 1) {
                withAnimation { steps.remove(at: index) }
            }
        }
    }

    private var addStepButton: some View {
        Button {
            withAnimation { steps.append("") }
        } label: {
            Label("Добавить шаг", systemImage: "plus.circle.fill")
                .font(.system(size: 15, weight: .medium))
        }
    }

    private var dateStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Дата выполнения", systemImage: "calendar")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 8) {
                Text("Начало")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(.primary)
            }
            .cardStyle()

            Toggle("Дата окончания", isOn: $hasEndDate.animation())
                .tint(.primary)

            if hasEndDate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Окончание")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.primary)
                }
                .cardStyle()
                
            }
        }
        
    }

    private var parametersStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Параметры", systemImage: "slider.horizontal.3")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 10) {
                Text("Приоритет")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(Priority.allCases) { p in
                        Button {
                            withAnimation { priority = p }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: p.icon).font(.system(size: 13))
                                Text(p.rawValue).font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                priority == p ? p.color.opacity(0.12) : Color.clear,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().stroke(priority == p ? p.color : Color(UIColor.separator), lineWidth: 1)
                            )
                            .foregroundStyle(priority == p ? p.color : .secondary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Категория")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(TaskCategory.allCases) { cat in
                        Button {
                            withAnimation { category = cat }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon).font(.system(size: 14))
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
        
    }

    private var extrasStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Дополнительно", systemImage: "gearshape")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 10) {
                Text("Повтор")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(RepeatMode.allCases) { mode in
                    Button {
                        withAnimation { repeatMode = mode }
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                                .font(.system(size: 15))
                                .foregroundStyle(repeatMode == mode ? .primary : .secondary)
                            Spacer()
                            if repeatMode == mode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                Text("Заметки")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .font(.system(size: 15))
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .inputStyle()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Предпросмотр")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.isEmpty ? "Без названия" : title)
                            .font(.system(size: 15, weight: .semibold))
                        HStack(spacing: 6) {
                            Text(category.rawValue)
                            if repeatMode != .none {
                                Text("· \(repeatMode.rawValue)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: priority.icon)
                        .foregroundStyle(priority.color)
                }
                .cardStyle()
            }
        }
        
    }

    private var bottomNav: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Text("Назад")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.bordered)
            }

            Button {
                withAnimation {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        saveTask()
                    }
                }
            } label: {
                Text(currentStep < totalSteps - 1 ? "Далее" : "Создать")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .disabled(currentStep == 0 && title.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }

    private func saveTask() {
        let taskSteps = steps
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { TaskStep(title: $0) }
        let task = TaskItem(
            title: title,
            description: description,
            steps: taskSteps,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            priority: priority,
            category: category,
            notes: notes,
            repeatMode: repeatMode
        )
        appState.addTask(task)
        dismiss()
    }
}

struct StepInputRow: View {
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
            TextField("Шаг \(index + 1)", text: $text)
                .font(.system(size: 16))
                .textFieldStyle(.roundedBorder)
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
    }
}
