//
//  ContentView.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ClipboardHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(0)
            
            SnippetsView()
                .tabItem {
                    Label("Snippets", systemImage: "doc.text")
                }
                .tag(1)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

#Preview {
    ContentView()
}
