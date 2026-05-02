//
//  SettingsView.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100
    @AppStorage("showSourceApp") private var showSourceApp = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hotKeyEnabled") private var hotKeyEnabled = true
    
    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            shortcutsSettings
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            aboutSettings
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: AppLayout.settingsWidth, height: AppLayout.settingsHeight)
        .scenePadding()
    }
    
    private var generalSettings: some View {
        Form {
            Section("History") {
                Stepper(value: $maxHistoryItems, in: 10...500, step: 10) {
                    Text("Maximum items: \(maxHistoryItems)")
                }
                
                Toggle("Show source application", isOn: $showSourceApp)
            }
            
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Enable quick search hotkey", isOn: $hotKeyEnabled)
            }
        }
        .formStyle(.grouped)
    }
    
    private var shortcutsSettings: some View {
        Form {
            Section("Quick Search") {
                HStack {
                    Text("Open Quick Search")
                    Spacer()
                    ShortcutRecorder(hotkey: "⌘⇧V")
                }
                
                Text("Press this shortcut anywhere to open the quick search window.")
                    .font(.appCaption)
                    .foregroundStyle(.appSecondaryText)
            }
            
            Section("Navigation") {
                HStack {
                    Text("Navigate up")
                    Spacer()
                    ShortcutRecorder(hotkey: "↑")
                }
                
                HStack {
                    Text("Navigate down")
                    Spacer()
                    ShortcutRecorder(hotkey: "↓")
                }
                
                HStack {
                    Text("Select and copy")
                    Spacer()
                    ShortcutRecorder(hotkey: "↵")
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private var aboutSettings: some View {
        VStack(spacing: 16) {
            Image(systemName: "scissors")
                .font(.appLargeTitle)
                .foregroundStyle(Color.accentColor)
            
            Text("Clipboard Manager")
                .font(.appTitle)
            
            Text("Version 1.0.0")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
            
            Text("A powerful clipboard manager for macOS")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
            
            Spacer()
            
            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com")!)
                Link("Support", destination: URL(string: "https://support.example.com")!)
            }
        }
        .padding()
    }
}

struct ShortcutRecorder: View {
    let hotkey: String
    
    var body: some View {
        Text(hotkey)
            .font(.appBodyMedium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.3))
            .cornerRadius(6)
    }
}

#Preview {
    SettingsView()
}
