//
//  Item.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
