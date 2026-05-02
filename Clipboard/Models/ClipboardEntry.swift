//
//  ClipboardEntry.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import Foundation
import SwiftData

@Model
final class ClipboardEntry {
    var content: String
    var createdAt: Date
    var pinned: Bool
    var contentType: String // text, url, email, etc.
    var sourceApp: String?
    
    init(content: String, contentType: String = "text", sourceApp: String? = nil) {
        self.content = content
        self.createdAt = Date()
        self.pinned = false
        self.contentType = contentType
        self.sourceApp = sourceApp
    }
}
