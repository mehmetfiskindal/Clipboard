//
//  ClipboardMonitor.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import Foundation
import AppKit
import SwiftData
import Combine

@Observable
@MainActor
final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    var isMonitoring = false
    var maxHistoryItems: Int = 100
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // Get string content
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty else { return }
        
        // Avoid duplicates - check if identical content was added in last minute
        let fetchDescriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let recentEntries = try modelContext.fetch(fetchDescriptor)
            
            // Skip if identical content exists from last 60 seconds
            if let lastEntry = recentEntries.first,
               lastEntry.content == content,
               Date().timeIntervalSince(lastEntry.createdAt) < 60 {
                return
            }
            
            // Determine content type
            let contentType = detectContentType(content)
            
            // Get source app if available
            let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
            
            // Create new entry
            let entry = ClipboardEntry(
                content: content,
                contentType: contentType,
                sourceApp: sourceApp
            )
            
            modelContext.insert(entry)
            
            // Cleanup old entries (keep only maxHistoryItems unpinned)
            cleanupOldEntries()
            
            try modelContext.save()
            
        } catch {
            print("Failed to save clipboard entry: \(error)")
        }
    }
    
    private func detectContentType(_ content: String) -> String {
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return "url"
        } else if content.contains("@") && content.contains(".") {
            let emailRegex = try? NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", options: .caseInsensitive)
            let range = NSRange(location: 0, length: content.utf16.count)
            if emailRegex?.firstMatch(in: content, options: [], range: range) != nil {
                return "email"
            }
        } else if content.hasPrefix("#") || content.hasPrefix("//") {
            return "code"
        }
        return "text"
    }
    
    private func cleanupOldEntries() {
        let fetchDescriptor = FetchDescriptor<ClipboardEntry>(
            predicate: #Predicate { $0.pinned == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let entries = try modelContext.fetch(fetchDescriptor)
            if entries.count > maxHistoryItems {
                let entriesToDelete = entries[maxHistoryItems...]
                for entry in entriesToDelete {
                    modelContext.delete(entry)
                }
            }
        } catch {
            print("Failed to cleanup old entries: \(error)")
        }
    }
    
    func copyToClipboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount // Prevent re-saving what we just copied
    }
}
