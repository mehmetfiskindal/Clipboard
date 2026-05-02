//
//  Snippet.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import Foundation
import SwiftData

@Model
final class Snippet {
    var title: String
    var body: String
    var tags: [String]
    var pinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(title: String, body: String, tags: [String] = []) {
        self.title = title
        self.body = body
        self.tags = tags
        self.pinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
