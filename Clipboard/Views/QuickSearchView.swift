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
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
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
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
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
                        .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
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
                HStack(spacing: 4) {
                    Text("↑↓")
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .cornerRadius(4)
                    Text("Navigate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text("↵")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .cornerRadius(4)
                    Text("Copy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text("⌘↵")
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .cornerRadius(4)
                    Text("Paste")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(allItems.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 500)
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
            Image(systemName: iconForType(entry.contentType))
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(1)
                    .font(.system(size: 14))
                
                HStack(spacing: 6) {
                    Label(entry.createdAt.formatted(.relative(presentation: .named)), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let sourceApp = entry.sourceApp {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(sourceApp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if entry.pinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
            }
            
            Text("History")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "url": return "link"
        case "email": return "envelope"
        case "code": return "chevron.left.forwardslash.chevron.right"
        default: return "doc.text"
        }
    }
}

struct QuickSearchSnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.system(size: 14, weight: .medium))
                
                Text(snippet.body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Text("Snippet")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    QuickSearchView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
