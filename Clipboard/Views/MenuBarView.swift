import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @Query(sort: \ClipboardEntry.createdAt, order: .reverse) private var clipboardEntries: [ClipboardEntry]
    @Query(sort: \Snippet.updatedAt, order: .reverse) private var snippets: [Snippet]

    @State private var searchText = ""
    @State private var selectedTab = 0

    private var filteredEntries: [ClipboardEntry] {
        if searchText.isEmpty { return Array(clipboardEntries.prefix(10)) }
        return clipboardEntries.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty { return Array(snippets.prefix(5)) }
        return snippets.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, AppLayout.paddingMedium)
                .padding(.top, AppLayout.paddingMedium)

            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("History").tag(0)
                Text("Snippets").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppLayout.paddingMedium)
            .padding(.top, AppLayout.paddingSmall)

            // Content
            TabView(selection: $selectedTab) {
                entryList.tag(0)
                snippetList.tag(1)
            }
            .tabViewStyle(.automatic)

            // Footer
            AppDivider()
                .padding(.horizontal, AppLayout.paddingMedium)

            footer
                .padding(.horizontal, AppLayout.paddingMedium)
                .padding(.vertical, AppLayout.paddingSmall)
        }
        .frame(width: AppLayout.menuBarWidth)
        .background(.appBackground)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.appTextSecondary)
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.appTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .searchBarStyle()
    }

    // MARK: - Entry List (Card Layout)
    private var entryList: some View {
        ScrollView {
            if filteredEntries.isEmpty {
                emptyState(icon: "clipboard", message: "No Items")
            } else {
                LazyVStack(spacing: AppLayout.spacingSmall) {
                    ForEach(filteredEntries) { entry in
                        MenuBarEntryCard(entry: entry)
                            .contextMenu {
                                Button("Copy") { copyToClipboard(entry.content) }
                                Button(entry.pinned ? "Unpin" : "Pin") { entry.pinned.toggle() }
                                Divider()
                                Button("Delete", role: .destructive) { modelContext.delete(entry) }
                            }
                    }
                }
                .padding(AppLayout.spacingMedium)
            }
        }
    }

    // MARK: - Snippet List (Card Layout)
    private var snippetList: some View {
        ScrollView {
            if filteredSnippets.isEmpty {
                emptyState(icon: "doc.text", message: "No Snippets")
            } else {
                LazyVStack(spacing: AppLayout.spacingSmall) {
                    ForEach(filteredSnippets) { snippet in
                        MenuBarSnippetCard(snippet: snippet)
                            .contextMenu {
                                Button("Copy") { copyToClipboard(snippet.body) }
                                Divider()
                                Button("Delete", role: .destructive) { modelContext.delete(snippet) }
                            }
                    }
                }
                .padding(AppLayout.spacingMedium)
            }
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: AppLayout.spacingSmall) {
            Spacer()
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.appTextTertiary)
            Text(message)
                .font(.appBody)
                .foregroundStyle(.appTextTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer
    private var footer: some View {
        HStack {
            Button("Open Window") { openWindow(id: "main-window") }
                .buttonStyle(.link)

            Spacer()

            Button("Settings") { openSettings() }
                .buttonStyle(.link)

            Rectangle()
                .fill(.appBorder)
                .frame(width: 1, height: AppLayout.spacingMedium)

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.link)
        }
    }

    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}

// MARK: - Entry Card
struct MenuBarEntryCard: View {
    let entry: ClipboardEntry

    var body: some View {
        HStack(spacing: AppLayout.spacingSmall) {
            Image(systemName: ContentType(entry.contentType).icon)
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(ContentType(entry.contentType).semanticColor, in: RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(2)
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
                Image(systemName: "pin.fill")
                    .font(.appCaption)
                    .foregroundStyle(.semanticFile)
            }
        }
        .padding(AppLayout.spacingMedium)
        .background(.appSurface)
        .cornerRadius(AppLayout.cornerRadiusLarge)
        .shadow(color: .appShadow, radius: AppLayout.shadowRadiusSmall, y: AppLayout.shadowY)
    }
}

// MARK: - Snippet Card
struct MenuBarSnippetCard: View {
    let snippet: Snippet

    var body: some View {
        HStack(spacing: AppLayout.spacingSmall) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium))

            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.appBodyMedium)

                Text(snippet.body)
                    .font(.appCaption)
                    .foregroundStyle(.appTextSecondary)
                    .lineLimit(2)

                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.appCaption)
                        .foregroundStyle(.semanticText)
                        .lineLimit(1)
                }
            }

            if snippet.pinned {
                Image(systemName: "pin.fill")
                    .font(.appCaption)
                    .foregroundStyle(.semanticFile)
            }
        }
        .padding(AppLayout.spacingMedium)
        .background(.appSurface)
        .cornerRadius(AppLayout.cornerRadiusLarge)
        .shadow(color: .appShadow, radius: AppLayout.shadowRadiusSmall, y: AppLayout.shadowY)
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
