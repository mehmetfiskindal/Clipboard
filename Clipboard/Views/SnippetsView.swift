//
//  SnippetsView.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import SwiftUI
import SwiftData

struct SnippetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Snippet.updatedAt, order: .reverse) private var snippets: [Snippet]
    
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var selectedSnippet: Snippet?
    
    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return snippets
        }
        return snippets.filter { 
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }
    
    private var pinnedSnippets: [Snippet] {
        filteredSnippets.filter { $0.pinned }
    }
    
    private var unpinnedSnippets: [Snippet] {
        filteredSnippets.filter { !$0.pinned }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSnippet) {
                if !pinnedSnippets.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedSnippets) { snippet in
                            NavigationLink(value: snippet) {
                                SnippetListRow(snippet: snippet)
                            }
                        }
                    }
                }
                
                Section("Snippets") {
                    ForEach(unpinnedSnippets) { snippet in
                        NavigationLink(value: snippet) {
                            SnippetListRow(snippet: snippet)
                        }
                    }
                    .onDelete(perform: deleteSnippets)
                }
            }
            .navigationTitle("Snippets")
            .searchable(text: $searchText, prompt: "Search snippets...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Snippet", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSnippetSheet()
            }
        } detail: {
            if let snippet = selectedSnippet {
                SnippetDetailView(snippet: snippet)
            } else {
                ContentUnavailableView("Select a Snippet", systemImage: "doc.text")
            }
        }
    }
    
    private func deleteSnippets(offsets: IndexSet) {
        let snippetsToDelete = offsets.map { unpinnedSnippets[$0] }
        for snippet in snippetsToDelete {
            modelContext.delete(snippet)
        }
    }
}

struct SnippetListRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: snippet.pinned ? "pin.fill" : "doc.text")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(snippet.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if !snippet.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(snippet.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct SnippetDetailView: View {
    let snippet: Snippet
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(snippet.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if snippet.pinned {
                    Label("Pinned", systemImage: "pin.fill")
                        .foregroundStyle(.orange)
                }
            }
            
            if !snippet.tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(snippet.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
            
            Divider()
            
            ScrollView {
                Text(snippet.body)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created: \(snippet.createdAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Updated: \(snippet.updatedAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { togglePin(snippet) }) {
                        Label(snippet.pinned ? "Unpin" : "Pin", 
                              systemImage: snippet.pinned ? "pin.slash" : "pin")
                    }
                    
                    Button(action: { copyToClipboard(snippet.body) }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func togglePin(_ snippet: Snippet) {
        snippet.pinned.toggle()
        snippet.updatedAt = Date()
    }
    
    private func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}

struct AddSnippetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var snippetBody = ""
    @State private var tags = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Add Snippet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $snippetBody)
                .font(.system(.body, design: .monospaced))
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                )
            
            TextField("Tags (comma separated)", text: $tags)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Spacer()
                Button("Save") {
                    addSnippet()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || snippetBody.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func addSnippet() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let snippet = Snippet(title: title, body: snippetBody, tags: tagArray)
        modelContext.insert(snippet)
        dismiss()
    }
}

#Preview {
    SnippetsView()
        .modelContainer(for: [ClipboardEntry.self, Snippet.self], inMemory: true)
}
