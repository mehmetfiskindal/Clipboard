import SwiftUI
import SwiftData

// MARK: - Unified Selection
enum SidebarItem: Hashable {
    case entry(ClipboardEntry)
    case snippet(Snippet)
}

// MARK: - Content View
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardEntry.createdAt, order: .reverse) private var entries: [ClipboardEntry]
    @Query(sort: \Snippet.updatedAt, order: .reverse) private var snippets: [Snippet]

    @State private var searchText = ""
    @State private var selectedItem: SidebarItem?
    @State private var showingAddSheet = false

    private var filteredEntries: [ClipboardEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredSnippets: [Snippet] {
        guard !searchText.isEmpty else { return snippets }
        return snippets.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            detailView
        }
        .frame(minWidth: AppLayout.minWindowWidth, minHeight: AppLayout.minWindowHeight)
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        List(selection: $selectedItem) {
            pinnedSection
            historySection
            snippetsSection
        }
        .searchable(text: $searchText, prompt: "Search clipboard...")
        .navigationTitle("Clipboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Snippet", systemImage: "plus")
                    }
                    Menu {
                        Button("Clear History", action: clearHistory)
                        Button("Clear All", action: clearAll)
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSnippetSheet()
        }
        .background(.appBackground)
    }

    @ViewBuilder
    private var pinnedSection: some View {
        let pinnedEntries = filteredEntries.filter(\.pinned)
        let pinnedSnippets = filteredSnippets.filter(\.pinned)
        if !pinnedEntries.isEmpty || !pinnedSnippets.isEmpty {
            Section {
                ForEach(pinnedEntries) { entry in
                    NavigationLink(value: SidebarItem.entry(entry)) {
                        SidebarEntryRow(entry: entry)
                    }
                }
                ForEach(pinnedSnippets) { snippet in
                    NavigationLink(value: SidebarItem.snippet(snippet)) {
                        SidebarSnippetRow(snippet: snippet)
                    }
                }
            } header: {
                SidebarSectionHeader(icon: "pin.fill", title: "Pinned")
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let unpinnedEntries = filteredEntries.filter { !$0.pinned }
        if !unpinnedEntries.isEmpty {
            Section {
                ForEach(unpinnedEntries) { entry in
                    NavigationLink(value: SidebarItem.entry(entry)) {
                        SidebarEntryRow(entry: entry)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(unpinnedEntries[index])
                    }
                }
            } header: {
                SidebarSectionHeader(icon: "clock.arrow.circlepath", title: "History")
            }
        }
    }

    @ViewBuilder
    private var snippetsSection: some View {
        let unpinnedSnippets = filteredSnippets.filter { !$0.pinned }
        if !unpinnedSnippets.isEmpty {
            Section {
                ForEach(unpinnedSnippets) { snippet in
                    NavigationLink(value: SidebarItem.snippet(snippet)) {
                        SidebarSnippetRow(snippet: snippet)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(unpinnedSnippets[index])
                    }
                }
            } header: {
                SidebarSectionHeader(icon: "doc.text", title: "Snippets")
            }
        }
    }

    // MARK: - Detail
    @ViewBuilder
    private var detailView: some View {
        if let item = selectedItem {
            UnifiedDetailView(item: item)
        } else {
            emptySelection
        }
    }

    private var emptySelection: some View {
        VStack(spacing: AppLayout.spacingMedium) {
            Image(systemName: "scissors.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Clipboard Manager")
                .font(.appTitle)
                .foregroundStyle(.appTextPrimary)

            Text("Select an item from the sidebar to view details.")
                .font(.appBody)
                .foregroundStyle(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
    }

    // MARK: - Actions
    private func clearHistory() {
        for entry in entries where !entry.pinned {
            modelContext.delete(entry)
        }
    }

    private func clearAll() {
        for entry in entries { modelContext.delete(entry) }
        for snippet in snippets { modelContext.delete(snippet) }
    }
}

// MARK: - Sidebar Section Header
struct SidebarSectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(.appTextTertiary)
            Text(title)
                .font(.appCaptionBold)
                .foregroundStyle(.appTextTertiary)
                .textCase(.none)
        }
    }
}

// MARK: - Sidebar Row: Entry
struct SidebarEntryRow: View {
    let entry: ClipboardEntry

    var body: some View {
        HStack(spacing: AppLayout.spacingSmall) {
            Image(systemName: ContentType(entry.contentType).icon)
                .foregroundStyle(ContentType(entry.contentType).semanticColor)
                .frame(width: AppLayout.iconSizeSmall)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(1)
                    .font(.appBody)

                HStack(spacing: 4) {
                    Text(entry.createdAt, style: .relative)
                        .font(.appCaption)
                        .foregroundStyle(.appTextSecondary)

                    if let sourceApp = entry.sourceApp {
                        Text("•")
                            .font(.appCaption)
                            .foregroundStyle(.appTextTertiary)
                        Text(sourceApp)
                            .font(.appCaption)
                            .foregroundStyle(.appTextSecondary)
                    }
                }
            }

            if entry.pinned {
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.appCaption)
                    .foregroundStyle(.semanticFile)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sidebar Row: Snippet
struct SidebarSnippetRow: View {
    let snippet: Snippet

    var body: some View {
        HStack(spacing: AppLayout.spacingSmall) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .foregroundStyle(.appTextSecondary)
                .frame(width: AppLayout.iconSizeSmall)

            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.appBodyMedium)
                    .lineLimit(1)

                Text(snippet.body)
                    .font(.appCaption)
                    .foregroundStyle(.appTextSecondary)
                    .lineLimit(1)

                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.appCaption)
                        .foregroundStyle(.semanticText)
                        .lineLimit(1)
                }
            }

            if snippet.pinned {
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.appCaption)
                    .foregroundStyle(.semanticFile)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Unified Detail View
struct UnifiedDetailView: View {
    let item: SidebarItem
    @Environment(\.modelContext) private var modelContext

    @State private var copied = false

    private var accentColor: Color {
        switch item {
        case .entry(let entry): return ContentType(entry.contentType).semanticColor
        case .snippet: return .semanticText
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.spacingLarge) {
                headerCard
                contentCard
                metadataCard
            }
            .padding(AppLayout.spacingLarge)
        }
        .frame(minWidth: AppLayout.detailMinWidth, minHeight: AppLayout.detailMinHeight)
        .background(.appBackground)
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
            switch item {
            case .entry(let entry):
                HStack(spacing: AppLayout.spacingSmall) {
                    Image(systemName: ContentType(entry.contentType).icon)
                        .foregroundStyle(accentColor)
                        .font(.title3)
                    Text(entry.contentType.capitalized)
                        .font(.appCaptionBold)
                        .foregroundStyle(accentColor)

                    Spacer()

                    if entry.pinned {
                        Label("Pinned", systemImage: "pin.fill")
                            .font(.appCaption)
                            .foregroundStyle(.semanticFile)
                    }
                }

                Text(entry.content)
                    .font(.appBody)
                    .lineLimit(2)
                    .foregroundStyle(.appTextPrimary)
            case .snippet(let snippet):
                HStack {
                    HStack(spacing: AppLayout.spacingSmall) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(accentColor)
                            .font(.title3)
                        Text("Snippet")
                            .font(.appCaptionBold)
                            .foregroundStyle(accentColor)
                    }

                    Spacer()

                    if snippet.pinned {
                        Label("Pinned", systemImage: "pin.fill")
                            .font(.appCaption)
                            .foregroundStyle(.semanticFile)
                    }
                }

                Text(snippet.title)
                    .font(.appTitle)
                    .foregroundStyle(.appTextPrimary)

                if !snippet.tags.isEmpty {
                    HStack(spacing: AppLayout.spacingSmall) {
                        ForEach(snippet.tags, id: \.self) { tag in
                            Text(tag)
                                .badge(.semanticText)
                        }
                    }
                }
            }
        }
        .padding(AppLayout.spacingLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.appSurface)
        .cornerRadius(AppLayout.cornerRadiusXLarge)
        .shadow(color: .appShadow, radius: AppLayout.shadowRadiusSmall, y: AppLayout.shadowY)
        .overlay(
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .cornerRadius(1.5),
            alignment: .leading
        )
    }

    // MARK: - Content Card
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: AppLayout.spacingSmall) {
            HStack {
                Label("Content", systemImage: "text.alignleft")
                    .font(.appCaptionBold)
                    .foregroundStyle(.appTextTertiary)
                Spacer()
            }

            switch item {
            case .entry(let entry):
                Text(entry.content)
                    .font(.appMonospaced)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            case .snippet(let snippet):
                Text(snippet.body)
                    .font(.appMonospaced)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(AppLayout.spacingLarge)
        .background(.appSurface)
        .cornerRadius(AppLayout.cornerRadiusXLarge)
        .shadow(color: .appShadow, radius: AppLayout.shadowRadiusSmall, y: AppLayout.shadowY)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                switch item {
                case .entry(let entry): copyToClipboard(entry.content)
                case .snippet(let snippet): copyToClipboard(snippet.body)
                }
            }) {
                Label("Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.appCaptionBold)
                    .padding(.horizontal, AppLayout.paddingSmall)
                    .padding(.vertical, 4)
                    .background(.appSurface, in: RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                            .stroke(.appBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(AppLayout.paddingSmall)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Metadata Card
    private var metadataCard: some View {
        HStack {
            switch item {
            case .entry(let entry):
                metadataRow(icon: "clock", text: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                if let sourceApp = entry.sourceApp {
                    metadataDivider
                    metadataRow(icon: "app.badge", text: sourceApp)
                }
            case .snippet(let snippet):
                metadataRow(icon: "clock", text: snippet.createdAt.formatted(date: .abbreviated, time: .shortened))
                metadataDivider
                metadataRow(icon: "clock.arrow.circlepath", text: snippet.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            Spacer()

            // Inline actions in metadata card
            switch item {
            case .entry(let entry):
                actionButton(isPinned: entry.pinned,
                    togglePin: { entry.pinned.toggle() },
                    copyContent: entry.content)
            case .snippet(let snippet):
                actionButton(isPinned: snippet.pinned,
                    togglePin: { snippet.pinned.toggle(); snippet.updatedAt = Date() },
                    copyContent: snippet.body)
            }
        }
        .padding(AppLayout.spacingMedium)
        .background(.appSurface)
        .cornerRadius(AppLayout.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusLarge)
                .stroke(.appBorder, lineWidth: 1)
        )
    }

    private var metadataDivider: some View {
        Rectangle()
            .fill(.appBorder)
            .frame(width: 1, height: 12)
    }

    private func metadataRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.appCaption)
                .foregroundStyle(.appTextTertiary)
            Text(text)
                .font(.appCaption)
                .foregroundStyle(.appTextSecondary)
        }
    }

    private func actionButton(isPinned: Bool, togglePin: @escaping () -> Void, copyContent: String) -> some View {
        HStack(spacing: 4) {
            Button(action: togglePin) {
                Label(isPinned ? "Unpin" : "Pin",
                      systemImage: isPinned ? "pin.slash" : "pin")
                    .font(.appCaptionBold)
            }
            .buttonStyle(AppGhostButtonStyle())
            .controlSize(.small)

            Button(action: { copyToClipboard(copyContent) }) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.appCaptionBold)
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .controlSize(.small)
        }
    }

    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        withAnimation(.easeInOut(duration: AppAnimation.fast)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: AppAnimation.fast)) {
                copied = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
