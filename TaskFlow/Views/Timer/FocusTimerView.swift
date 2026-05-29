import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject var appState: AppState
    @State private var timerMode = 0
    @State private var selectedMinutes = 25
    @State private var selectedSeconds = 0
    @State private var remainingSeconds = 0
    @State private var stopwatchSeconds = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timer: Timer? = nil
    @State private var selectedTask: TaskItem? = nil
    @State private var showTaskPicker = false
    @State private var sessionsCompleted = 0
    @State private var totalFocusSeconds = 0
    @State private var laps: [Int] = []

    private let presets = [15, 25, 45, 60]
    private let secondsOptions = [0, 15, 30, 45]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    modePicker
                    timerDisplay
                    if !isRunning && timerMode == 0 { presetSection }
                    taskLink
                    controlButtons
                    if timerMode == 1 && !laps.isEmpty { lapsSection }
                    sessionStats
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .navigationTitle("Фокус")
            .sheet(isPresented: $showTaskPicker) { taskPickerSheet }
        }
    }

    private var modePicker: some View {
        Picker("", selection: $timerMode) {
            Text("Таймер").tag(0)
            Text("Секундомер").tag(1)
        }
        .pickerStyle(.segmented)
        .disabled(isRunning)
    }

    private var timerDisplay: some View {
        ZStack {
            Circle()
                .stroke(.separator, lineWidth: 8)
                .frame(width: 260, height: 260)

            Circle()
                .trim(from: 0, to: circleProgress)
                .stroke(.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: circleProgress)

            Circle()
                .fill(.regularMaterial)
                .frame(width: 230, height: 230)
                .glassEffect(.regular, in: Circle())

            VStack(spacing: 6) {
                Text(displayTime)
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(secondsDisplay)
                    .font(.system(size: 20, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }

    private var displayTime: String {
        let secs = timerMode == 0 ? remainingSeconds : stopwatchSeconds
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private var secondsDisplay: String {
        let secs = timerMode == 0 ? remainingSeconds : stopwatchSeconds
        return String(format: ":%02d", secs % 60)
    }

    private var statusText: String {
        if isRunning { return isPaused ? "На паузе" : (timerMode == 0 ? "В фокусе" : "Идёт отсчёт") }
        return "Готов"
    }

    private var circleProgress: CGFloat {
        if timerMode == 0 {
            let total = Double(selectedMinutes * 60 + selectedSeconds)
            guard total > 0 else { return 0 }
            return CGFloat(Double(remainingSeconds) / total)
        }
        return CGFloat(min(Double(stopwatchSeconds) / 3600.0, 1.0))
    }

    private var presetSection: some View {
        VStack(spacing: 14) {
            Text("Длительность")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(presets, id: \.self) { mins in
                    Button {
                        withAnimation {
                            selectedMinutes = mins
                            selectedSeconds = 0
                            remainingSeconds = mins * 60
                        }
                    } label: {
                        Text("\(mins)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(width: 52, height: 52)
                            .background(
                                selectedMinutes == mins && selectedSeconds == 0
                                ? AnyShapeStyle(Color.primary)
                                : AnyShapeStyle(Color.clear),
                                in: Circle()
                            )
                            .overlay(
                                Circle().stroke(
                                    selectedMinutes == mins && selectedSeconds == 0 ? .clear : .separator,
                                    lineWidth: 1
                                )
                            )
                            .foregroundStyle(
                                selectedMinutes == mins && selectedSeconds == 0
                                ? Color(.systemBackground) : .primary
                            )
                    }
                }
            }

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Минуты").font(.caption2).foregroundStyle(.tertiary)
                    Picker("", selection: $selectedMinutes) {
                        ForEach(0..<121, id: \.self) { m in Text("\(m)").tag(m) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .clipped()
                }
                VStack(spacing: 4) {
                    Text("Секунды").font(.caption2).foregroundStyle(.tertiary)
                    Picker("", selection: $selectedSeconds) {
                        ForEach(secondsOptions, id: \.self) { s in Text("\(s)").tag(s) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 80)
                    .clipped()
                }
            }
            .cardStyle()
            .onChange(of: selectedMinutes) { _, _ in
                if !isRunning { remainingSeconds = selectedMinutes * 60 + selectedSeconds }
            }
            .onChange(of: selectedSeconds) { _, _ in
                if !isRunning { remainingSeconds = selectedMinutes * 60 + selectedSeconds }
            }
        }
    }

    private var taskLink: some View {
        Button { showTaskPicker = true } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedTask != nil ? selectedTask!.category.icon : "link")
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTask?.title ?? "Привязать к задаче")
                        .font(.system(size: 15, weight: .medium))
                    if let t = selectedTask {
                        Text(t.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
        }
        .cardStyle()
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            if isRunning {
                Button {
                    stopTimer()
                } label: {
                    Text("Стоп")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 80, height: 50)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    isPaused ? resumeTimer() : pauseTimer()
                } label: {
                    Text(isPaused ? "Продолжить" : "Пауза")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)

                if timerMode == 1 {
                    Button {
                        laps.insert(stopwatchSeconds, at: 0)
                    } label: {
                        Text("Круг")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 80, height: 50)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button {
                    startTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 18))
                        Text("Старт").font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: 220, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .controlSize(.large)
            }
        }
    }

    private var lapsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Круги").font(.system(size: 16, weight: .semibold, design: .rounded))
            ForEach(laps.indices, id: \.self) { i in
                HStack {
                    Text("Круг \(laps.count - i)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatTimeHMS(laps[i]))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }
                .padding(.vertical, 4)
                if i < laps.count - 1 { Divider() }
            }
        }
        .cardStyle()
    }

    private var sessionStats: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(sessionsCompleted)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Сессий")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()

            VStack(spacing: 4) {
                Text(formatTimeHMS(totalFocusSeconds))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("Всего")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
    }

    private var taskPickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button { selectedTask = nil; showTaskPicker = false } label: {
                        HStack {
                            Text("Без задачи").foregroundStyle(.secondary)
                            Spacer()
                            if selectedTask == nil {
                                Image(systemName: "checkmark").foregroundStyle(.primary)
                            }
                        }
                    }
                }
                Section("Активные задачи") {
                    ForEach(appState.tasks.filter { !$0.isCompleted }) { task in
                        Button {
                            selectedTask = task
                            showTaskPicker = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: task.category.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title).foregroundStyle(.primary)
                                    Text(task.category.rawValue).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedTask?.id == task.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выберите задачу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { showTaskPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func startTimer() {
        if timerMode == 0 {
            remainingSeconds = selectedMinutes * 60 + selectedSeconds
            guard remainingSeconds > 0 else { return }
        } else {
            stopwatchSeconds = 0
            laps = []
        }
        isRunning = true
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerMode == 0 {
                if remainingSeconds > 0 { remainingSeconds -= 1 }
                else { completeSession() }
            } else {
                stopwatchSeconds += 1
            }
        }
    }

    private func pauseTimer() {
        isPaused = true
        timer?.invalidate()
    }

    private func resumeTimer() {
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerMode == 0 {
                if remainingSeconds > 0 { remainingSeconds -= 1 }
                else { completeSession() }
            } else {
                stopwatchSeconds += 1
            }
        }
    }

    private func stopTimer() {
        let elapsed = timerMode == 0
            ? (selectedMinutes * 60 + selectedSeconds) - remainingSeconds
            : stopwatchSeconds
        totalFocusSeconds += elapsed
        if let task = selectedTask, elapsed > 0 {
            appState.addTimeToTask(taskId: task.id, seconds: elapsed)
        }
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingSeconds = selectedMinutes * 60 + selectedSeconds
        stopwatchSeconds = 0
    }

    private func completeSession() {
        let elapsed = selectedMinutes * 60 + selectedSeconds
        totalFocusSeconds += elapsed
        sessionsCompleted += 1
        if let task = selectedTask {
            appState.addTimeToTask(taskId: task.id, seconds: elapsed)
        }
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingSeconds = selectedMinutes * 60 + selectedSeconds
    }
}
