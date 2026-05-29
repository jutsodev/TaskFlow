import SwiftUI

struct NotesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateNote = false
    @State private var selectedNote: NoteItem? = nil
    @State private var searchText = ""
    @State private var sortNewest = true

    private var filtered: [NoteItem] {
        var result = appState.notes
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        let pinned = result.filter { $0.isPinned }
        let unpinned = result.filter { !$0.isPinned }
        let sortedUnpinned = sortNewest
            ? unpinned.sorted { $0.updatedAt > $1.updatedAt }
            : unpinned.sorted { $0.updatedAt < $1.updatedAt }
        return pinned.sorted { $0.updatedAt > $1.updatedAt } + sortedUnpinned
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if appState.notes.isEmpty && searchText.isEmpty {
                        EmptyStateView(
                            icon: "note.text",
                            title: "Нет заметок",
                            subtitle: "Записывайте идеи, планы и мысли",
                            actionTitle: "Создать заметку",
                            action: { showCreateNote = true }
                        )
                    } else {
                        if !filtered.isEmpty {
                            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filtered) { note in
                                    noteCard(note)
                                        .onTapGesture { selectedNote = note }
                                        .contextMenu {
                                            Button {
                                                withAnimation { appState.toggleNotePin(note) }
                                            } label: {
                                                Label(
                                                    note.isPinned ? "Открепить" : "Закрепить",
                                                    systemImage: note.isPinned ? "pin.slash" : "pin"
                                                )
                                            }
                                            Button(role: .destructive) {
                                                withAnimation { appState.deleteNote(note) }
                                            } label: { Label("Удалить", systemImage: "trash") }
                                        }
                                }
                            }
                        } else {
                            ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .searchable(text: $searchText, prompt: "Поиск заметок")
            .navigationTitle("Заметки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { sortNewest.toggle() }
                        } label: {
                            Image(systemName: sortNewest ? "arrow.down" : "arrow.up")
                        }
                        Button { showCreateNote = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateNote) {
                NoteEditorView(mode: .create).environmentObject(appState)
            }
            .sheet(item: $selectedNote) { note in
                NoteEditorView(mode: .edit(note)).environmentObject(appState)
            }
        }
    }

    private func noteCard(_ note: NoteItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if note.isPinned {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill").font(.system(size: 9))
                    Text("Закреплено").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
            }

            Text(note.title.isEmpty ? "Без названия" : note.title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(2)

            if !note.content.isEmpty {
                Text(note.content)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .lineSpacing(3)
            }

            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Text(shortRuDate(note.updatedAt))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 100)
        .cardStyle()
    }
}

enum NoteEditorMode {
    case create
    case edit(NoteItem)
}

struct NoteEditorView: View {
    let mode: NoteEditorMode
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isPinned = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Название", text: $title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Divider()

                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Начните писать...")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $content)
                            .font(.system(size: 16))
                            .frame(minHeight: 300)
                            .scrollContentBackground(.hidden)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Теги")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text("#\(tag)")
                                            .font(.system(size: 13, weight: .medium))
                                        Button {
                                            withAnimation { tags.removeAll { $0 == tag } }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.secondary.opacity(0.1), in: Capsule())
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("Новый тег", text: $newTag)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 14))
                            Button("Добавить") {
                                let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty && !tags.contains(trimmed) {
                                    withAnimation { tags.append(trimmed) }
                                    newTag = ""
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }

                    Toggle("Закрепить", isOn: $isPinned)
                        .tint(.primary)

                    if isEditing {
                        Button(role: .destructive) {
                            if case .edit(let note) = mode {
                                appState.deleteNote(note)
                            }
                            dismiss()
                        } label: {
                            Label("Удалить заметку", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(20)
            }
            .navigationTitle(isEditing ? "Редактировать" : "Новая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            if case .edit(let note) = mode {
                title = note.title
                content = note.content
                tags = note.tags
                isPinned = note.isPinned
            }
        }
    }

    private func save() {
        if case .edit(let note) = mode {
            var updated = note
            updated.title = title
            updated.content = content
            updated.tags = tags
            updated.isPinned = isPinned
            updated.updatedAt = Date()
            appState.updateNote(updated)
        } else {
            let note = NoteItem(
                title: title,
                content: content,
                isPinned: isPinned,
                tags: tags
            )
            appState.addNote(note)
        }
        dismiss()
    }
}
