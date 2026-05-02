//
//  MenuBarView.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

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
        if searchText.isEmpty {
            return Array(clipboardEntries.prefix(10))
        }
        return clipboardEntries.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return Array(snippets.prefix(5))
        }
        return snippets.filter { 
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("History").tag(0)
                Text("Snippets").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Content
            TabView(selection: $selectedTab) {
                clipboardList.tag(0)
                snippetsList.tag(1)
            }
            .tabViewStyle(.automatic)
            .frame(height: 300)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Footer buttons
            HStack {
                Button("Open Main Window") {
                    openWindow(id: "main-window")
                }
                .buttonStyle(.link)
                
                Spacer()
                
                Button("Settings") {
                    openSettings()
                }
                .buttonStyle(.link)
                
                Divider()
                    .frame(height: 12)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320)
    }
    
    private var clipboardList: some View {
        List {
            if filteredEntries.isEmpty {
                ContentUnavailableView("No Items", systemImage: "clipboard")
            } else {
                ForEach(filteredEntries) { entry in
                    ClipboardEntryRow(entry: entry)
                        .contextMenu {
                            Button("Copy") {
                                copyToClipboard(entry.content)
                            }
                            Button(entry.pinned ? "Unpin" : "Pin") {
                                togglePin(entry)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteEntry(entry)
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var snippetsList: some View {
        List {
            if filteredSnippets.isEmpty {
                ContentUnavailableView("No Snippets", systemImage: "doc.text")
            } else {
                ForEach(filteredSnippets) { snippet in
                    SnippetRow(snippet: snippet)
                        .contextMenu {
                            Button("Copy") {
                                copyToClipboard(snippet.body)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deleteSnippet(snippet)
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
    private func togglePin(_ entry: ClipboardEntry) {
        entry.pinned.toggle()
    }
    
    private func deleteEntry(_ entry: ClipboardEntry) {
        modelContext.delete(entry)
    }
    
    private func deleteSnippet(_ snippet: Snippet) {
        modelContext.delete(snippet)
    }
}

struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForType(entry.contentType))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(2)
                    .font(.system(size: 13))
                
                HStack {
                    Text(entry.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if let sourceApp = entry.sourceApp {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(sourceApp)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if entry.pinned {
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
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

struct SnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(snippet.body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
