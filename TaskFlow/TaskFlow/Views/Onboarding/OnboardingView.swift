import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userAge = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil

    private let totalPages = 7

    private let tips: [(icon: String, title: String, subtitle: String)] = [
        ("hand.wave.fill",
         "Добро пожаловать\nв TaskFlow",
         "Ваш персональный помощник для управления задачами, целями и привычками. Организуйте свою жизнь и станьте лучшей версией себя за год."),
        ("person.crop.circle.fill.badge.plus",
         "Расскажите о себе",
         "Введите ваше имя и возраст. По желанию добавьте фото профиля."),
        ("checklist",
         "Создавайте задачи",
         "Добавляйте задачи с описанием, этапами выполнения и приоритетами. Встроенный таймер отслеживает затраченное время на каждую задачу."),
        ("target",
         "Ставьте цели на год",
         "Определите что вы хотите изменить в себе за год. Добавьте вехи и каждый день делайте хотя бы один шаг к вашей мечте."),
        ("repeat.circle.fill",
         "Закрепляйте привычки",
         "Создайте привычки которые хотите выработать. Отмечайте их выполнение каждый день и наблюдайте за ростом серии."),
        ("timer",
         "Используйте таймер",
         "Таймер обратного отсчёта и секундомер для фокусировки на задачах. Привяжите таймер к задаче и время запишется автоматически."),
        ("sparkles",
         "Всё готово!",
         "Вы готовы начать свой путь к лучшей версии себя. Помните: каждый день — это новый шанс стать лучше!")
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Spacer()

            Group {
                if currentPage == 1 {
                    profileSetupPage
                } else {
                    tipPage
                }
            }
            .id(currentPage)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            Spacer()
            pageIndicator
                .padding(.bottom, 28)
            navigationButtons
                .padding(.bottom, 44)
        }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 10) {
                LogoView(size: 34)
                Text("TaskFlow")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            Spacer()
            if currentPage != 1 && currentPage < totalPages - 1 {
                Button("Пропустить") {
                    appState.hasCompletedOnboarding = true
                }
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var tipPage: some View {
        VStack(spacing: 28) {
            if currentPage == 0 {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .primary.opacity(0.1), radius: 20, y: 10)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentPage)
            } else {
                Image(systemName: tips[currentPage].icon)
                    .font(.system(size: 52))
                    .foregroundStyle(.primary)
                    .frame(width: 120, height: 120)
                    .background(.regularMaterial, in: Circle())
            }

            VStack(spacing: 14) {
                Text(tips[currentPage].title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(tips[currentPage].subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }
        }
    }

    private var profileSetupPage: some View {
        VStack(spacing: 24) {
            ZStack {
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.separator, lineWidth: 1))
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .frame(width: 100, height: 100)
                        .background(.regularMaterial, in: Circle())
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text(avatarImage == nil ? "Добавить фото" : "Изменить фото")
                    .font(.system(size: 14, weight: .medium))
            }
            .onChange(of: selectedPhoto) { _, newVal in
                if let newVal {
                    Task {
                        if let data = try? await newVal.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            avatarImage = img
                        }
                    }
                }
            }

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Как вас зовут?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("Введите имя", text: $userName)
                        .font(.system(size: 17))
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Сколько вам лет?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("Введите возраст", text: $userAge)
                        .font(.system(size: 17))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal, 36)

            Text("Фото необязательно — можно добавить позже")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.primary : Color.secondary.opacity(0.25))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 14) {
            if currentPage > 0 {
                Button {
                    withAnimation { currentPage -= 1 }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 50, height: 50)
                        .background(.regularMaterial, in: Circle())
                }
            }

            Button {
                withAnimation {
                    if currentPage == 1 {
                        if !userName.isEmpty { appState.userName = userName }
                        if let age = Int(userAge) { appState.userAge = age }
                        if let img = avatarImage {
                            appState.saveAvatar(img.jpegData(compressionQuality: 0.8))
                        }
                    }
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    } else {
                        appState.hasCompletedOnboarding = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < totalPages - 1 ? "Далее" : "Начать")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: currentPage < totalPages - 1 ? "arrow.right" : "checkmark")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(.primary, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(currentPage == 1 && userName.isEmpty)
            .opacity(currentPage == 1 && userName.isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, 24)
    }
}
