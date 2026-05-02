//
//  ClipboardApp.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import SwiftUI
import SwiftData

// Global model container reference
var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        ClipboardEntry.self,
        Snippet.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Main window
        WindowGroup("Clipboard Manager", id: "main-window") {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 900, height: 600)
        
        #if os(macOS)
        // Menu Bar Extra
        MenuBarExtra("Clipboard", systemImage: "scissors") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
        
        // Settings/Preferences
        Settings {
            SettingsView()
        }
        
        // Quick Search Window - Using standard window
        Window("Quick Search", id: "quick-search") {
            QuickSearchView()
                .modelContainer(sharedModelContainer)
                .frame(minWidth: 500, maxWidth: 500, minHeight: 300, maxHeight: 600)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 400)
        #endif
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var clipboardMonitor: ClipboardMonitor?
    private var hotKeyManager: HotKeyManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize clipboard monitor with global container
        clipboardMonitor = ClipboardMonitor(modelContainer: sharedModelContainer)
        clipboardMonitor?.startMonitoring()
        
        // Setup hotkeys
        hotKeyManager = HotKeyManager()
        hotKeyManager?.onQuickSearch = { [weak self] in
            self?.toggleQuickSearch()
        }
        hotKeyManager?.registerHotKeys()
        
        // Show accessibility permission alert if needed
        checkAccessibilityPermissions()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
        hotKeyManager?.unregisterHotKeys()
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            // Show alert to user
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "Clipboard Manager needs Accessibility permissions to detect global keyboard shortcuts (Command+Shift+V). Please grant permission in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Later")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Open Privacy & Security settings
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    private func toggleQuickSearch() {
        DispatchQueue.main.async {
            // Open quick search window
            if let window = NSApplication.shared.windows.first(where: { $0.title == "Quick Search" }) {
                if window.isVisible && window.isKeyWindow {
                    window.close()
                } else {
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                // Try to open using openWindow
                NotificationCenter.default.post(name: .toggleQuickSearch, object: nil)
            }
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let toggleQuickSearch = Notification.Name("toggleQuickSearch")
}
