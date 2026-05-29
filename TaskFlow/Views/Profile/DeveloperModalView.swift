import SwiftUI

struct DeveloperModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedService: ServiceItem? = nil

    private let services: [ServiceItem] = [
        ServiceItem(
            icon: "iphone",
            title: "Мобильное приложение",
            shortDesc: "iOS и Android",
            description: "Разработка нативных мобильных приложений для iOS (Swift/SwiftUI) и Android (Kotlin). Создаю приложения любой сложности — от простых утилит до комплексных бизнес-решений с серверной частью, push-уведомлениями, интеграцией платёжных систем и аналитикой. Каждое приложение проходит тестирование и оптимизацию производительности перед публикацией в App Store и Google Play. Использую современные архитектуры MVVM и Clean Architecture для поддерживаемого и масштабируемого кода."
        ),
        ServiceItem(
            icon: "globe",
            title: "Веб-сайт",
            shortDesc: "Лендинги и веб-приложения",
            description: "Проектирование и разработка современных веб-сайтов и веб-приложений. Использую актуальные технологии: React, Next.js, Vue.js, Node.js. Создаю адаптивные лендинги, корпоративные сайты, интернет-магазины и SaaS-платформы. Все проекты оптимизированы для SEO, быстрой загрузки и удобства пользователей на любых устройствах. Применяю TypeScript для надёжности и TailwindCSS для быстрой стилизации."
        ),
        ServiceItem(
            icon: "paperplane.fill",
            title: "Telegram бот",
            shortDesc: "Автоматизация и сервисы",
            description: "Разработка Telegram-ботов для автоматизации бизнес-процессов, обслуживания клиентов и развлечений. Реализую inline-режимы, платёжные системы, интеграцию с внешними API, базы данных и админ-панели. Боты работают надёжно 24/7 на облачных серверах с мониторингом и автоматическим перезапуском при сбоях. Использую Python (aiogram) и Node.js для максимальной производительности."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    aboutSection
                    servicesSection
                    contactSection
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Заказать разработку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .sheet(item: $selectedService) { service in
                serviceDetail(service)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var aboutSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                    LogoView(size: 60)


                VStack(alignment: .leading, spacing: 4) {
                    Text("jutsodev")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Fullstack разработчик")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text("Привет! Я — разработчик с более чем 3-летним опытом создания цифровых продуктов. Специализируюсь на мобильных приложениях для iOS и Android, современных веб-сайтах и Telegram-ботах. За время работы реализовал множество проектов: от персональных задачников и трекеров привычек до сложных бизнес-приложений с интеграцией API. Использую современные технологии — Swift, SwiftUI, Kotlin, React, Node.js, Python. Главные принципы: чистый код, красивый дизайн и внимание к деталям. TaskFlow — один из моих проектов, демонстрирующий подход к разработке.")
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Услуги")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            ForEach(services) { service in
                Button { selectedService = service } label: {
                    HStack(spacing: 14) {
                        Image(systemName: service.icon)
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(service.title)
                                .font(.system(size: 15, weight: .semibold))
                            Text(service.shortDesc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                }
                .cardStyle()
            }
        }
    }

    private var contactSection: some View {
        VStack(spacing: 14) {
            Text("Связаться")
                .font(.system(size: 18, weight: .semibold, design: .rounded))

            contactButton("paperplane.fill", "Написать в Telegram", "https://t.me/slehes")
            contactButton("chevron.left.forwardslash.chevron.right", "GitHub", "https://github.com/jutsodev")
            contactButton("megaphone.fill", "Telegram Канал", "https://t.me/slehesQ")
        }
    }

    private func contactButton(_ icon: String, _ title: String, _ url: String) -> some View {
        Button {
            if let link = URL(string: url) { UIApplication.shared.open(link) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 34, height: 34)
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func serviceDetail(_ service: ServiceItem) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Image(systemName: service.icon)
                        .font(.system(size: 44))
                        .frame(width: 100, height: 100)
                        .background(.secondary.opacity(0.1), in: Circle())

                    VStack(spacing: 8) {
                        Text(service.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(service.shortDesc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(service.description)
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .foregroundStyle(.secondary)
                        .cardStyle()

                    Button {
                        if let url = URL(string: "https://t.me/slehes") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("Обсудить проект")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                    .controlSize(.large)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { selectedService = nil }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

struct ServiceItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let shortDesc: String
    let description: String
}
