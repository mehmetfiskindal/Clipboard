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
                    .foregroundStyle(.appSecondaryText)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.appSecondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchBarStyle()
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
                clipboardList.tag(0)
                snippetsList.tag(1)
            }
            .tabViewStyle(.automatic)
            .frame(height: 300)
            
            Divider()
                .padding(.horizontal, AppLayout.paddingMedium)
            
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
                    .frame(height: AppLayout.spacingMedium)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, AppLayout.paddingMedium)
            .padding(.vertical, AppLayout.paddingSmall)
        }
        .frame(width: AppLayout.menuBarWidth)
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
            Image(systemName: ContentType(entry.contentType).icon)
                .foregroundStyle(ContentType(entry.contentType).semanticColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(2)
                    .font(.appBody)
                
                HStack {
                    Text(entry.createdAt, style: .relative)
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

struct SnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .foregroundStyle(.appSecondaryText)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.appBodyMedium)
                
                Text(snippet.body)
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
                    .lineLimit(2)
                
                if !snippet.tags.isEmpty {
                    Text(snippet.tags.joined(separator: ", "))
                        .font(.appCaption)
                        .foregroundStyle(.semanticText)
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
