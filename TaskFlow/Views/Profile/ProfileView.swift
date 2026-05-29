import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("selectedAppearance") private var selectedAppearance = 0
    @State private var showDeveloperModal = false
    @State private var showEditProfile = false
    @State private var animateProfile = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.bottom, 28)

                    VStack(spacing: 18) {
                        statsGrid
                        achievementsBanner
                        appearanceSection
                        menuSection
                        developerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showDeveloperModal) { DeveloperModalView() }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet().environmentObject(appState)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) { animateProfile = true }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 130, height: 130)
                    .scaleEffect(animateProfile ? 1 : 0.8)

                AvatarView(data: appState.avatarData, size: 100, initials: appState.userInitials)
                    .scaleEffect(animateProfile ? 1 : 0.6)
                    .opacity(animateProfile ? 1 : 0)

                Circle()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.3), location: 0.0),
                                .init(color: Color.white.opacity(0.05), location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 114, height: 114)
            }

            VStack(spacing: 5) {
                Text(appState.userName.isEmpty ? "Пользователь" : appState.userName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .opacity(animateProfile ? 1 : 0)
                    .offset(y: animateProfile ? 0 : 8)

                if appState.userAge > 0 {
                    Text("\(appState.userAge) лет")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    showEditProfile = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Редактировать")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if appState.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                        Text("\(appState.streak) дней")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .glassPillStyle(isSelected: true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ваша статистика")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statCard("checkmark.circle.fill", "\(appState.totalCompleted)", "Выполнено")
                statCard("list.bullet", "\(appState.tasks.count)", "Задач")
                statCard("flame.fill", "\(appState.streak)", "Серия")
                statCard("target", "\(appState.goals.count)", "Целей")
                statCard("repeat.circle.fill", "\(appState.habits.count)", "Привычек")
                statCard("calendar", "\(appState.todayTasks.count)", "Сегодня")
            }
        }
    }

    private func statCard(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.primary.opacity(0.7))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .glassStatCard()
    }

    private var achievementsBanner: some View {
        let achvs = appState.achievements()
        let unlocked = achvs.filter { $0.isUnlocked }.count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Достижения")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(unlocked)/\(achvs.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(achvs) { ach in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 52, height: 52)
                                Circle()
                                    .trim(from: 0, to: ach.progress)
                                    .stroke(.primary.opacity(ach.isUnlocked ? 0.8 : 0.15),
                                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: 52, height: 52)
                                    .rotationEffect(.degrees(-90))
                                Image(systemName: ach.icon)
                                    .font(.system(size: 19))
                                    .foregroundStyle(ach.isUnlocked ? .primary : .tertiary)
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    .frame(width: 52, height: 52)
                            )

                            Text(ach.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(ach.isUnlocked ? .primary : .tertiary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(width: 72)
                        .opacity(ach.isUnlocked ? 1 : 0.55)
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Оформление")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            HStack(spacing: 10) {
                themeButton(0, "sun.max", "Авто")
                themeButton(1, "sun.min", "Светлая")
                themeButton(2, "moon.fill", "Тёмная")
            }
        }
    }

    private func themeButton(_ tag: Int, _ icon: String, _ label: String) -> some View {
        let isSelected = selectedAppearance == tag
        return Button {
            withAnimation(.spring(response: 0.35)) { selectedAppearance = tag }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.ultraThinMaterial),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(Color.white.opacity(isSelected ? 0 : 0.15), lineWidth: 0.5))

                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                ? AnyShapeStyle(Color.primary.opacity(0.04))
                : AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.primary.opacity(0.15) : Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            NavigationLink {
                StatisticsView().environmentObject(appState)
            } label: {
                menuRowLabel("chart.bar.fill", "Статистика", .secondary)
            }
            Divider().padding(.leading, 50)
            NavigationLink {
                SearchView().environmentObject(appState)
            } label: {
                menuRowLabel("magnifyingglass", "Поиск", .secondary)
            }
            Divider().padding(.leading, 50)
            menuRow("questionmark.circle", "Показать подсказки", .secondary) {
                appState.hasCompletedOnboarding = false
            }
            Divider().padding(.leading, 50)
            menuRow("square.and.arrow.up", "Экспорт данных", .secondary) {
                let text = appState.exportData(format: .json)
                UIPasteboard.general.string = text
            }
            Divider().padding(.leading, 50)
            menuRow("trash", "Сбросить всё", .red) {
                appState.tasks.removeAll()
                appState.goals.removeAll()
                appState.habits.removeAll()
            }
        }
        .cardStyle()
    }

    private func menuRow(_ icon: String, _ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            menuRowLabel(icon, title, color)
        }
    }

    private func menuRowLabel(_ icon: String, _ title: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    }
                )
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(color == .red ? .red : .primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Разработчик")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    LogoView(size: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("TaskFlow")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("by jutsodev")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("v2.0")
                        .font(.system(size: 12, weight: .medium))
                        .glassPillStyle(isSelected: true)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }

                Divider()

                // Telegram with proper logo
                socialLink("paperplane.fill", "Telegram", "@slehes", "https://t.me/slehes", accentColor: Color(red: 0.24, green: 0.56, blue: 0.93))
                // GitHub with proper logo
                socialLink("chevron.left.forwardslash.chevron.right", "GitHub", "jutsodev", "https://github.com/jutsodev", accentColor: .primary)
                // Telegram Channel with proper logo
                socialLink("megaphone.fill", "Канал Telegram", "@slehesQ", "https://t.me/slehesQ", accentColor: Color(red: 0.24, green: 0.56, blue: 0.93))

                Divider()

                Button { showDeveloperModal = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 16))
                            .frame(width: 34, height: 34)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                }
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Заказать разработку")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Приложения, сайты, боты")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .cardStyle()
        }
    }

    private func socialLink(_ icon: String, _ title: String, _ subtitle: String, _ url: String, accentColor: Color = .primary) -> some View {
        Button {
            if let link = URL(string: url) { UIApplication.shared.open(link) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(accentColor)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color.white.opacity(0.2), location: 0.0),
                                            .init(color: Color.clear, location: 0.5),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 14, weight: .medium))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
        }
    }
}

struct EditProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var editedName = ""
    @State private var editedAge = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        ZStack {
                            AvatarView(data: appState.avatarData, size: 100, initials: appState.userInitials)
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                .frame(width: 110, height: 110)
                        }

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill").font(.system(size: 12))
                                Text(appState.avatarData == nil ? "Добавить фото" : "Изменить фото")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .onChange(of: selectedPhoto) { _, newVal in
                            if let newVal {
                                Task {
                                    if let data = try? await newVal.loadTransferable(type: Data.self) {
                                        appState.saveAvatar(data)
                                    }
                                }
                            }
                        }

                        if appState.avatarData != nil {
                            Button("Удалить фото") { appState.saveAvatar(nil) }
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Имя")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField("Введите имя", text: $editedName)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 16))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Возраст")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField("Введите возраст", text: $editedAge)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 16))
                        }
                    }

                    Button {
                        appState.userName = editedName
                        if let age = Int(editedAge) { appState.userAge = age }
                        dismiss()
                    } label: {
                        Text("Сохранить")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
                }
                .padding(24)
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            editedName = appState.userName
            editedAge = appState.userAge > 0 ? "\(appState.userAge)" : ""
        }
    }
}
