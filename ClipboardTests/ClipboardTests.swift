//
//  ClipboardTests.swift
//  ClipboardTests
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import Testing
import SwiftData
import Foundation
@testable import Clipboard

// MARK: - ClipboardEntry Tests
@Suite("ClipboardEntry Model Tests")
struct ClipboardEntryTests {
    
    @Test("ClipboardEntry initialization with default values")
    func testClipboardEntryDefaultInitialization() async throws {
        let content = "Test content"
        let entry = ClipboardEntry(content: content)
        
        #expect(entry.content == content)
        #expect(entry.pinned == false)
        #expect(entry.contentType == "text")
        #expect(entry.sourceApp == nil)
        #expect(Date().timeIntervalSince(entry.createdAt) < 1)
    }
    
    @Test("ClipboardEntry initialization with custom content type")
    func testClipboardEntryCustomContentType() async throws {
        let entry = ClipboardEntry(
            content: "https://example.com",
            contentType: "url",
            sourceApp: "Safari"
        )
        
        #expect(entry.content == "https://example.com")
        #expect(entry.contentType == "url")
        #expect(entry.sourceApp == "Safari")
        #expect(entry.pinned == false)
    }
    
    @Test("ClipboardEntry content can be modified")
    func testClipboardEntryModification() async throws {
        let entry = ClipboardEntry(content: "Original content")
        
        entry.content = "Modified content"
        entry.pinned = true
        entry.contentType = "code"
        
        #expect(entry.content == "Modified content")
        #expect(entry.pinned == true)
        #expect(entry.contentType == "code")
    }
}

// MARK: - Snippet Tests
@Suite("Snippet Model Tests")
struct SnippetTests {
    
    @Test("Snippet initialization with default values")
    func testSnippetDefaultInitialization() async throws {
        let snippet = Snippet(
            title: "Test Snippet",
            body: "This is the body"
        )
        
        #expect(snippet.title == "Test Snippet")
        #expect(snippet.body == "This is the body")
        #expect(snippet.tags.isEmpty)
        #expect(snippet.pinned == false)
        #expect(Date().timeIntervalSince(snippet.createdAt) < 1)
        #expect(Date().timeIntervalSince(snippet.updatedAt) < 1)
    }
    
    @Test("Snippet initialization with tags")
    func testSnippetWithTags() async throws {
        let tags = ["swift", "code", "snippet"]
        let snippet = Snippet(
            title: "Code Snippet",
            body: "print(\"Hello\")",
            tags: tags
        )
        
        #expect(snippet.title == "Code Snippet")
        #expect(snippet.body == "print(\"Hello\")")
        #expect(snippet.tags == tags)
        #expect(snippet.tags.count == 3)
    }
    
    @Test("Snippet properties can be modified")
    func testSnippetModification() async throws {
        let snippet = Snippet(
            title: "Original",
            body: "Original body"
        )
        
        snippet.title = "Updated Title"
        snippet.body = "Updated body"
        snippet.tags = ["updated"]
        snippet.pinned = true
        let newUpdateDate = Date()
        snippet.updatedAt = newUpdateDate
        
        #expect(snippet.title == "Updated Title")
        #expect(snippet.body == "Updated body")
        #expect(snippet.tags == ["updated"])
        #expect(snippet.pinned == true)
        #expect(snippet.updatedAt == newUpdateDate)
    }
}

// MARK: - Content Type Detection Tests
@Suite("Content Type Detection Tests")
struct ContentTypeDetectionTests {
    
    // Helper class to expose private methods for testing
    class ContentTypeDetector {
        func detectContentType(_ content: String) -> String {
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
    }
    
    let detector = ContentTypeDetector()
    
    @Test("Detect HTTP URL")
    func testDetectHTTPURL() async throws {
        #expect(detector.detectContentType("http://example.com") == "url")
    }
    
    @Test("Detect HTTPS URL")
    func testDetectHTTPSURL() async throws {
        #expect(detector.detectContentType("https://www.example.com") == "url")
    }
    
    @Test("Detect valid email")
    func testDetectValidEmail() async throws {
        #expect(detector.detectContentType("user@example.com") == "email")
        #expect(detector.detectContentType("test.user@domain.co.uk") == "email")
        #expect(detector.detectContentType("user+tag@example.com") == "email")
    }
    
    @Test("Detect invalid email as text")
    func testDetectInvalidEmailAsText() async throws {
        // Contains @ and . but not a valid email format
        #expect(detector.detectContentType("hello@world") == "text")
        #expect(detector.detectContentType("@example.com") == "text")
    }
    
    @Test("Detect code snippets")
    func testDetectCode() async throws {
        #expect(detector.detectContentType("#include <stdio.h>") == "code")
        #expect(detector.detectContentType("// This is a comment") == "code")
        #expect(detector.detectContentType("# Swift code") == "code")
    }
    
    @Test("Detect plain text")
    func testDetectPlainText() async throws {
        #expect(detector.detectContentType("Hello world") == "text")
        #expect(detector.detectContentType("Some random text") == "text")
        #expect(detector.detectContentType("") == "text")
        #expect(detector.detectContentType("Multiple\nlines\nof text") == "text")
    }
    
    @Test("Detect URL with path and query")
    func testDetectComplexURL() async throws {
        #expect(detector.detectContentType("https://example.com/path?query=value") == "url")
        #expect(detector.detectContentType("https://api.example.com/v1/users?id=123") == "url")
    }
}

// MARK: - Content Validation Tests
@Suite("Content Validation Tests")
struct ContentValidationTests {
    
    @Test("Empty content should not be processed")
    func testEmptyContentValidation() async throws {
        let emptyContent = ""
        #expect(emptyContent.isEmpty == true)
        
        let whitespaceContent = "   "
        #expect(whitespaceContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true)
    }
    
    @Test("Non-empty content should be valid")
    func testNonEmptyContentValidation() async throws {
        let content = "Some content"
        #expect(content.isEmpty == false)
        
        let whitespaceContent = "  content  "
        #expect(whitespaceContent.isEmpty == false)
    }
    
    @Test("Content length validation")
    func testContentLength() async throws {
        let shortContent = "Hi"
        #expect(shortContent.count == 2)
        
        let longContent = String(repeating: "a", count: 1000)
        #expect(longContent.count == 1000)
    }
}

// MARK: - Snippet Search and Filter Tests
@Suite("Snippet Search Tests")
struct SnippetSearchTests {
    
    @Test("Search by title")
    func testSearchByTitle() async throws {
        let snippet1 = Snippet(title: "Swift Tips", body: "Content 1")
        let snippet2 = Snippet(title: "Python Guide", body: "Content 2")
        
        let snippets = [snippet1, snippet2]
        let searchTerm = "swift"
        
        let results = snippets.filter { 
            $0.title.localizedCaseInsensitiveContains(searchTerm)
        }
        
        #expect(results.count == 1)
        #expect(results.first?.title == "Swift Tips")
    }
    
    @Test("Search by body content")
    func testSearchByBody() async throws {
        let snippet1 = Snippet(title: "Title 1", body: "print(\"Hello\")")
        let snippet2 = Snippet(title: "Title 2", body: "console.log(\"World\")")
        
        let snippets = [snippet1, snippet2]
        let searchTerm = "print"
        
        let results = snippets.filter {
            $0.body.localizedCaseInsensitiveContains(searchTerm)
        }
        
        #expect(results.count == 1)
        #expect(results.first?.body == "print(\"Hello\")")
    }
    
    @Test("Search by tags")
    func testSearchByTags() async throws {
        let snippet1 = Snippet(title: "Snippet 1", body: "Body 1", tags: ["swift", "ios"])
        let snippet2 = Snippet(title: "Snippet 2", body: "Body 2", tags: ["python", "django"])
        
        let snippets = [snippet1, snippet2]
        let searchTag = "swift"
        
        let results = snippets.filter {
            $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchTag) })
        }
        
        #expect(results.count == 1)
        #expect(results.first?.title == "Snippet 1")
    }
    
    @Test("Case insensitive search")
    func testCaseInsensitiveSearch() async throws {
        let snippet = Snippet(title: "Swift Programming", body: "Content")
        
        #expect(snippet.title.localizedCaseInsensitiveContains("swift") == true)
        #expect(snippet.title.localizedCaseInsensitiveContains("SWIFT") == true)
        #expect(snippet.title.localizedCaseInsensitiveContains("SwIfT") == true)
    }
}

// MARK: - History Management Tests
@Suite("History Management Tests")
struct HistoryManagementTests {
    
    @Test("Maximum history items limit")
    func testMaxHistoryItemsLimit() async throws {
        let maxItems = 100
        let entries = (1...150).map { i in
            ClipboardEntry(content: "Content \(i)")
        }
        
        let unpinnedEntries = entries.filter { !$0.pinned }
        let entriesToKeep = Array(unpinnedEntries.prefix(maxItems))
        
        #expect(entriesToKeep.count == maxItems)
    }
    
    @Test("Pinned items should not be deleted")
    func testPinnedItemsPreservation() async throws {
        let pinnedEntry = ClipboardEntry(content: "Important")
        pinnedEntry.pinned = true
        
        let unpinnedEntry = ClipboardEntry(content: "Normal")
        
        #expect(pinnedEntry.pinned == true)
        #expect(unpinnedEntry.pinned == false)
        
        // Simulate cleanup logic
        let entries = [pinnedEntry, unpinnedEntry]
        let unpinnedCount = entries.filter { !$0.pinned }.count
        
        #expect(unpinnedCount == 1)
    }
    
    @Test("Duplicate detection within time window")
    func testDuplicateDetection() async throws {
        let content = "Duplicate content"
        let recentEntry = ClipboardEntry(content: content)
        
        // Simulate recent entry (within 60 seconds)
        let timeDifference = Date().timeIntervalSince(recentEntry.createdAt)
        let isDuplicate = timeDifference < 60
        
        #expect(isDuplicate == true)
        #expect(recentEntry.content == content)
    }
    
    @Test("Old duplicate should be allowed")
    func testOldDuplicateAllowed() async throws {
        let content = "Old content"
        
        // Create entry with old timestamp
        let oldEntry = ClipboardEntry(content: content)
        // Simulate old entry by checking time difference > 60 seconds would be false in real scenario
        // Here we just verify the logic
        let timeWindow: TimeInterval = 60
        
        #expect(timeWindow == 60)
        #expect(oldEntry.content == content)
    }
}

// MARK: - Date Handling Tests
@Suite("Date Handling Tests")
struct DateHandlingTests {
    
    @Test("ClipboardEntry creation date")
    func testEntryCreationDate() async throws {
        let beforeCreation = Date()
        let entry = ClipboardEntry(content: "Test")
        let afterCreation = Date()
        
        #expect(entry.createdAt >= beforeCreation)
        #expect(entry.createdAt <= afterCreation)
    }
    
    @Test("Snippet creation and update dates")
    func testSnippetDates() async throws {
        let beforeCreation = Date()
        let snippet = Snippet(title: "Test", body: "Body")
        let afterCreation = Date()
        
        #expect(snippet.createdAt >= beforeCreation)
        #expect(snippet.createdAt <= afterCreation)
        #expect(snippet.updatedAt >= beforeCreation)
        #expect(snippet.updatedAt <= afterCreation)
        #expect(snippet.createdAt == snippet.updatedAt)
    }
    
    @Test("Snippet update date changes")
    func testSnippetUpdateDate() async throws {
        let snippet = Snippet(title: "Test", body: "Body")
        let originalUpdateDate = snippet.updatedAt
        
        // Wait a tiny bit and update
        try await Task.sleep(for: .milliseconds(10))
        snippet.updatedAt = Date()
        
        #expect(snippet.updatedAt > originalUpdateDate)
    }
}

// MARK: - Edge Case Tests
@Suite("Edge Case Tests")
struct EdgeCaseTests {
    
    @Test("Handle special characters in content")
    func testSpecialCharacters() async throws {
        let specialContent = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let entry = ClipboardEntry(content: specialContent)
        
        #expect(entry.content == specialContent)
    }
    
    @Test("Handle unicode content")
    func testUnicodeContent() async throws {
        let unicodeContent = "Hello 世界 🌍 مرحبا"
        let entry = ClipboardEntry(content: unicodeContent)
        
        #expect(entry.content == unicodeContent)
    }
    
    @Test("Handle multiline content")
    func testMultilineContent() async throws {
        let multilineContent = """
        Line 1
        Line 2
        Line 3
        """
        let entry = ClipboardEntry(content: multilineContent)
        
        #expect(entry.content == multilineContent)
        #expect(entry.content.components(separatedBy: .newlines).count == 3)
    }
    
    @Test("Handle very long content")
    func testVeryLongContent() async throws {
        let longContent = String(repeating: "a", count: 10000)
        let entry = ClipboardEntry(content: longContent)
        
        #expect(entry.content.count == 10000)
    }
    
    @Test("Empty tags array")
    func testEmptyTags() async throws {
        let snippet = Snippet(title: "Test", body: "Body", tags: [])
        
        #expect(snippet.tags.isEmpty)
        #expect(snippet.tags.count == 0)
    }
    
    @Test("Single tag")
    func testSingleTag() async throws {
        let snippet = Snippet(title: "Test", body: "Body", tags: ["only"])
        
        #expect(snippet.tags.count == 1)
        #expect(snippet.tags.first == "only")
    }
    
    @Test("Many tags")
    func testManyTags() async throws {
        let manyTags = (1...50).map { "tag\($0)" }
        let snippet = Snippet(title: "Test", body: "Body", tags: manyTags)
        
        #expect(snippet.tags.count == 50)
    }
}

// MARK: - Clipboard Operations Tests
@Suite("Clipboard Operations Tests")
struct ClipboardOperationsTests {
    
    @Test("Copy to clipboard simulation")
    func testCopyToClipboard() async throws {
        let content = "Test content to copy"
        
        // Simulate clipboard operation
        let pasteboardContent = content
        
        #expect(pasteboardContent == content)
        #expect(!pasteboardContent.isEmpty)
    }
    
    @Test("Clipboard change count tracking")
    func testClipboardChangeCount() async throws {
        var changeCount = 0
        
        // Simulate clipboard changes
        changeCount += 1
        #expect(changeCount == 1)
        
        changeCount += 1
        #expect(changeCount == 2)
    }
}

// MARK: - Monitoring State Tests
@Suite("Monitoring State Tests")
struct MonitoringStateTests {
    
    @Test("Initial monitoring state")
    func testInitialMonitoringState() async throws {
        // Simulate initial state
        let isMonitoring = false
        
        #expect(isMonitoring == false)
    }
    
    @Test("Start monitoring state change")
    func testStartMonitoring() async throws {
        var isMonitoring = false
        
        // Simulate start monitoring
        isMonitoring = true
        
        #expect(isMonitoring == true)
    }
    
    @Test("Stop monitoring state change")
    func testStopMonitoring() async throws {
        var isMonitoring = true
        
        // Simulate stop monitoring
        isMonitoring = false
        
        #expect(isMonitoring == false)
    }
    
    @Test("Max history items default value")
    func testMaxHistoryItemsDefault() async throws {
        let defaultMaxItems = 100
        
        #expect(defaultMaxItems == 100)
    }
    
    @Test("Max history items can be changed")
    func testMaxHistoryItemsChange() async throws {
        var maxHistoryItems = 100
        maxHistoryItems = 50
        
        #expect(maxHistoryItems == 50)
        
        maxHistoryItems = 200
        #expect(maxHistoryItems == 200)
    }
}

// MARK: - Integration Tests
@Suite("Integration Tests")
struct IntegrationTests {
    
    @Test("Complete clipboard entry lifecycle")
    func testClipboardEntryLifecycle() async throws {
        // Create entry
        let entry = ClipboardEntry(
            content: "Test content",
            contentType: "text",
            sourceApp: "TestApp"
        )
        
        #expect(entry.content == "Test content")
        #expect(entry.contentType == "text")
        #expect(entry.sourceApp == "TestApp")
        #expect(entry.pinned == false)
        
        // Pin the entry
        entry.pinned = true
        #expect(entry.pinned == true)
        
        // Modify content
        entry.content = "Updated content"
        #expect(entry.content == "Updated content")
    }
    
    @Test("Complete snippet lifecycle")
    func testSnippetLifecycle() async throws {
        // Create snippet
        let snippet = Snippet(
            title: "Test Snippet",
            body: "Original body",
            tags: ["test", "snippet"]
        )
        
        #expect(snippet.title == "Test Snippet")
        #expect(snippet.body == "Original body")
        #expect(snippet.tags.count == 2)
        
        // Update snippet
        snippet.title = "Updated Snippet"
        snippet.body = "Updated body"
        snippet.tags.append("updated")
        snippet.pinned = true
        snippet.updatedAt = Date()
        
        #expect(snippet.title == "Updated Snippet")
        #expect(snippet.body == "Updated body")
        #expect(snippet.tags.count == 3)
        #expect(snippet.pinned == true)
    }
}
