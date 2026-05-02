import SwiftUI
import SwiftData

// MARK: - Search Item Type
enum SearchItem: Identifiable {
    case entry(ClipboardEntry)
    case snippet(Snippet)

    var id: PersistentIdentifier {
        switch self {
        case .entry(let entry): return entry.id
        case .snippet(let snippet): return snippet.id
        }
    }

    var isPinned: Bool {
        switch self {
        case .entry(let entry): return entry.pinned
        case .snippet(let snippet): return snippet.pinned
        }
    }

    var sortDate: Date {
        switch self {
        case .entry(let entry): return entry.createdAt
        case .snippet(let snippet): return snippet.updatedAt
        }
    }
}

struct QuickSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ClipboardEntry.createdAt, order: .reverse) private var clipboardEntries: [ClipboardEntry]
    @Query(sort: \Snippet.updatedAt, order: .reverse) private var snippets: [Snippet]

    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var allItems: [SearchItem] {
        let pinnedEntries = clipboardEntries.filter { $0.pinned }.map { SearchItem.entry($0) }
        let recentEntries = clipboardEntries.filter { !$0.pinned }.prefix(20).map { SearchItem.entry($0) }
        let pinnedSnippets = snippets.filter { $0.pinned }.map { SearchItem.snippet($0) }
        let recentSnippets = snippets.filter { !$0.pinned }.prefix(10).map { SearchItem.snippet($0) }

        var items: [SearchItem] = []
        items.append(contentsOf: pinnedEntries)
        items.append(contentsOf: recentEntries)
        items.append(contentsOf: pinnedSnippets)
        items.append(contentsOf: recentSnippets)

        if searchText.isEmpty { return items }

        return items.filter { item in
            switch item {
            case .entry(let entry):
                return entry.content.localizedCaseInsensitiveContains(searchText)
            case .snippet(let snippet):
                return snippet.title.localizedCaseInsensitiveContains(searchText) ||
                       snippet.body.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            AppDivider()
            resultsList
            AppDivider()
            footer
        }
        .frame(width: AppLayout.quickSearchWidth)
        .background(.ultraThinMaterial)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleQuickSearch)) { _ in
            searchText = ""
            selectedIndex = 0
            isSearchFocused = true
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 { selectedIndex -= 1 }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < allItems.count - 1 { selectedIndex += 1 }
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    // MARK: - Search Field
    private var searchField: some View {
        HStack(spacing: AppLayout.spacingMedium) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.appTextSecondary)

            TextField("Search clipboard history and snippets...", text: $searchText)
                .font(.title3)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit { selectCurrentItem() }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.appTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppLayout.paddingLarge)
        .padding(.vertical, AppLayout.paddingMedium)
    }

    // MARK: - Results List
    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if allItems.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(allItems.enumerated()), id: \.element.id) { index, item in
                            QuickSearchRow(item: item, isSelected: index == selectedIndex)
                                .id(item.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedIndex = index
                                    selectCurrentItem()
                                }
                                .padding(.horizontal, AppLayout.paddingSmall)
                        }
                    }
                    .padding(.vertical, AppLayout.paddingSmall)
                }
            }
            .onChange(of: searchText) { _, _ in
                selectedIndex = 0
                if !allItems.isEmpty {
                    proxy.scrollTo(allItems[0].id, anchor: .top)
                }
            }
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation(.easeOut(duration: AppAnimation.fast)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .frame(height: min(CGFloat(allItems.count) * 56 + 16, 360))
    }

    private var emptyState: some View {
        VStack(spacing: AppLayout.spacingSmall) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.appTextTertiary)
            Text("No results found")
                .font(.appBody)
                .foregroundStyle(.appTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: AppLayout.spacingMedium) {
            HStack(spacing: 4) {
                Text("↑↓")
                    .keyboardHint()
                Text("Navigate")
                    .font(.appCaption)
                    .foregroundStyle(.appTextSecondary)
            }

            HStack(spacing: 4) {
                Text("↵")
                    .keyboardHint()
                Text("Copy")
                    .font(.appCaption)
                    .foregroundStyle(.appTextSecondary)
            }

            HStack(spacing: 4) {
                Text("⌘↵")
                    .keyboardHint()
                Text("Paste")
                    .font(.appCaption)
                    .foregroundStyle(.appTextSecondary)
            }

            Spacer()

            Text("\(allItems.count) items")
                .font(.appCaption)
                .foregroundStyle(.appTextSecondary)
        }
        .padding(.horizontal, AppLayout.paddingLarge)
        .padding(.vertical, AppLayout.paddingSmall)
    }

    // MARK: - Actions
    private func selectCurrentItem() {
        guard selectedIndex < allItems.count else { return }
        let item = allItems[selectedIndex]
        let contentToCopy: String = {
            switch item {
            case .entry(let entry): return entry.content
            case .snippet(let snippet): return snippet.body
            }
        }()
        if !contentToCopy.isEmpty { copyToClipboard(contentToCopy) }
        dismiss()
    }

    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}

// MARK: - Quick Search Row
struct QuickSearchRow: View {
    let item: SearchItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppLayout.spacingMedium) {
            switch item {
            case .entry(let entry):
                iconView(systemName: ContentType(entry.contentType).icon,
                         color: ContentType(entry.contentType).semanticColor)
                contentBody(
                    primary: entry.content,
                    secondary: secondaryLine(
                        label: entry.createdAt.formatted(.relative(presentation: .named)),
                        secondary: entry.sourceApp
                    )
                )
                Spacer()
                typeBadge(text: "History", color: .accentColor)
                if entry.pinned { pinIcon }
            case .snippet(let snippet):
                iconView(systemName: snippet.pinned ? "pin.fill" : "doc.text",
                         color: .accentColor)
                contentBody(
                    primary: snippet.title,
                    secondary: snippet.body
                )
                Spacer()
                typeBadge(text: "Snippet", color: .appSuccess)
                if snippet.pinned { pinIcon }
            }
        }
        .padding(.horizontal, AppLayout.spacingSmall)
        .padding(.vertical, AppLayout.spacingSmall)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(AppLayout.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusLarge)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func iconView(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.callout)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color, in: RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium))
    }

    private func contentBody(primary: String, secondary: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(primary)
                .lineLimit(1)
                .font(.appBody)
                .foregroundStyle(.appTextPrimary)
            Text(secondary)
                .lineLimit(1)
                .font(.appCaption)
                .foregroundStyle(.appTextSecondary)
        }
    }

    private func secondaryLine(label: String, secondary: String?) -> String {
        guard let secondary else { return label }
        return "\(label) • \(secondary)"
    }

    private func typeBadge(text: String, color: Color) -> some View {
        Text(text)
            .badge(color)
    }

    private var pinIcon: some View {
        Image(systemName: "pin.fill")
            .font(.appCaption)
            .foregroundStyle(.semanticFile)
    }
}

#Preview {
    QuickSearchView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
