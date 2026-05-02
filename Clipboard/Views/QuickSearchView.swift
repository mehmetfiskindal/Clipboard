//
//  QuickSearchView.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

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
        
        if searchText.isEmpty {
            return items
        }
        
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
            // Search field
            HStack(spacing: AppLayout.spacingMedium) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.appSecondaryText)
                
                TextField("Search clipboard history and snippets...", text: $searchText)
                    .font(.title3)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        selectCurrentItem()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.appSecondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppLayout.paddingLarge)
            .padding(.vertical, AppLayout.paddingMedium)
            
            Divider()
            
            // Results list
            ScrollViewReader { proxy in
                List(Array(allItems.enumerated()), id: \.element.id) { index, item in
                    itemRow(for: item, isSelected: index == selectedIndex)
                        .id(item.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIndex = index
                            selectCurrentItem()
                        }
                        .appRowSelected(index == selectedIndex)
                }
                .listStyle(.plain)
                .onChange(of: searchText) { _, _ in
                    selectedIndex = 0
                }
                .onChange(of: selectedIndex) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .frame(height: min(CGFloat(allItems.count) * 60 + 20, 400))
            
            Divider()
            
            // Footer
            HStack {
                HStack(spacing: AppLayout.spacingSmall / 2) {
                    Text("↑↓")
                        .keyboardHint()
                    Text("Navigate")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                
                HStack(spacing: AppLayout.spacingSmall / 2) {
                    Text("↵")
                        .keyboardHint()
                    Text("Copy")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                
                HStack(spacing: AppLayout.spacingSmall / 2) {
                    Text("⌘↵")
                        .keyboardHint()
                    Text("Paste")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
                
                Spacer()
                
                Text("\(allItems.count) items")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            .padding(.horizontal, AppLayout.paddingLarge)
            .padding(.vertical, AppLayout.paddingSmall)
        }
        .frame(width: AppLayout.quickSearchWidth)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleQuickSearch)) { _ in
            // Reset search when opened
            searchText = ""
            selectedIndex = 0
            isSearchFocused = true
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < allItems.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }
    
    @ViewBuilder
    private func itemRow(for item: SearchItem, isSelected: Bool) -> some View {
        switch item {
        case .entry(let entry):
            QuickSearchEntryRow(entry: entry)
        case .snippet(let snippet):
            QuickSearchSnippetRow(snippet: snippet)
        }
    }
    
    private func selectCurrentItem() {
        guard selectedIndex < allItems.count else { return }
        
        let item = allItems[selectedIndex]
        var contentToCopy = ""
        
        switch item {
        case .entry(let entry):
            contentToCopy = entry.content
        case .snippet(let snippet):
            contentToCopy = snippet.body
        }
        
        if !contentToCopy.isEmpty {
            copyToClipboard(contentToCopy)
        }
        
        dismiss()
    }
    
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}

struct QuickSearchEntryRow: View {
    let entry: ClipboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ContentType(entry.contentType).icon)
                .font(.title3)
                .foregroundStyle(ContentType(entry.contentType).semanticColor)
                .frame(width: AppLayout.iconSizeMedium)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(1)
                    .font(.appBody)
                
                HStack(spacing: 6) {
                    Label(entry.createdAt.formatted(.relative(presentation: .named)), systemImage: "clock")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                    
                    if let sourceApp = entry.sourceApp {
                        Text("•")
                            .font(.appCaption)
                            .foregroundStyle(.appSecondaryText)
                        Text(sourceApp)
                            .font(.appCaption)
                            .foregroundStyle(.appSecondaryText)
                    }
                }
            }
            
            Spacer()
            
            if entry.pinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.semanticFile)
            }
            
            Text("History")
                .badge(Color.accentColor)
        }
        .padding(.vertical, AppLayout.listRowVertical + 2)
    }
}

struct QuickSearchSnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .font(.title3)
                .foregroundStyle(.appSecondaryText)
                .frame(width: AppLayout.iconSizeMedium)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.appBodyMedium)
                
                Text(snippet.body)
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
                    .lineLimit(1)
                
                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.appCaption)
                        .foregroundStyle(.semanticText)
                }
            }
            
            Spacer()
            
            Text("Snippet")
                .badge(.appSuccess)
        }
        .padding(.vertical, AppLayout.listRowVertical + 2)
    }
}

#Preview {
    QuickSearchView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
