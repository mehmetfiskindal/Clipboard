//
//  ClipboardHistoryView.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import SwiftUI
import SwiftData

struct ClipboardHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardEntry.createdAt, order: .reverse) private var clipboardEntries: [ClipboardEntry]
    
    @State private var searchText = ""
    @State private var selectedEntry: ClipboardEntry?
    
    private var filteredEntries: [ClipboardEntry] {
        if searchText.isEmpty {
            return clipboardEntries
        }
        return clipboardEntries.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var pinnedEntries: [ClipboardEntry] {
        filteredEntries.filter { $0.pinned }
    }
    
    private var unpinnedEntries: [ClipboardEntry] {
        filteredEntries.filter { !$0.pinned }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedEntry) {
                if !pinnedEntries.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedEntries) { entry in
                            NavigationLink(value: entry) {
                                EntryListRow(entry: entry)
                            }
                        }
                    }
                }
                
                Section("History") {
                    ForEach(unpinnedEntries) { entry in
                        NavigationLink(value: entry) {
                            EntryListRow(entry: entry)
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
            .navigationTitle("Clipboard History")
            .searchable(text: $searchText, prompt: "Search clipboard history...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: clearAllHistory) {
                        Label("Clear All", systemImage: "trash")
                    }
                }
            }
        } detail: {
            if let entry = selectedEntry {
                EntryDetailView(entry: entry)
            } else {
                ContentUnavailableView("Select an Item", systemImage: "doc.text")
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        let entriesToDelete = offsets.map { unpinnedEntries[$0] }
        for entry in entriesToDelete {
            modelContext.delete(entry)
        }
    }
    
    private func clearAllHistory() {
        for entry in clipboardEntries where !entry.pinned {
            modelContext.delete(entry)
        }
    }
}

struct EntryListRow: View {
    let entry: ClipboardEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: ContentType(entry.contentType).icon)
                .foregroundStyle(ContentType(entry.contentType).semanticColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .lineLimit(1)
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
        }
        .padding(.vertical, 2)
    }
}

struct EntryDetailView: View {
    let entry: ClipboardEntry
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Type: \(entry.contentType.capitalized)", systemImage: ContentType(entry.contentType).icon)
                    .font(.appTitle)
                
                Spacer()
                
                if entry.pinned {
                    Label("Pinned", systemImage: "pin.fill")
                        .foregroundStyle(.semanticFile)
                }
            }
            
            Divider()
            
            ScrollView {
                Text(entry.content)
                    .codeBlock()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created: \(entry.createdAt.formatted())")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                    
                    if let sourceApp = entry.sourceApp {
                        Text("Source: \(sourceApp)")
                            .font(.appCaption)
                            .foregroundStyle(.appSecondaryText)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { togglePin(entry) }) {
                        Label(entry.pinned ? "Unpin" : "Pin", 
                              systemImage: entry.pinned ? "pin.slash" : "pin")
                    }
                    
                    Button(action: { copyToClipboard(entry.content) }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: AppLayout.detailMinWidth, minHeight: AppLayout.detailMinHeight)
    }
    
    private func togglePin(_ entry: ClipboardEntry) {
        entry.pinned.toggle()
    }
    
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
    
}

#Preview {
    ClipboardHistoryView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
