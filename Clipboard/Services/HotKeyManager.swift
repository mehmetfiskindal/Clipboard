//
//  HotKeyManager.swift
//  Clipboard
//
//  Created by Mehmet Fışkındal on 2.05.2026.
//

import Foundation
import AppKit
import Carbon

@Observable
@MainActor
final class HotKeyManager {
    var onQuickSearch: (() -> Void)?
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    func registerHotKeys() {
        // Check accessibility permissions first
        checkAndRequestAccessibilityPermissions()
        
        // Register Command + Shift + V for quick search
        registerQuickSearchHotKey()
    }
    
    func unregisterHotKeys() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
    
    private func checkAndRequestAccessibilityPermissions() {
        // Check if we have accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessibilityEnabled {
            print("Accessibility permissions not granted. Hotkeys may not work.")
            print("Please grant accessibility permissions in System Settings > Privacy & Security > Accessibility")
        }
    }
    
    private func registerQuickSearchHotKey() {
        // Create event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        // Install event handler
        let handler: EventHandlerUPP = { _, eventRef, userData -> OSStatus in
            guard let eventRef = eventRef else { return noErr }
            
            var hotKeyID = EventHotKeyID()
            let result = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if result == noErr {
                Task { @MainActor in
                    if let userData = userData {
                        let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                        if hotKeyID.id == 1 {
                            manager.onQuickSearch?()
                        }
                    }
                }
            }
            
            return noErr
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let installResult = InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
        
        guard installResult == noErr else {
            print("Failed to install event handler: \(installResult)")
            return
        }
        
        // Register the hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(fourCharCode("CLIP")), id: 1)
        let keyCode = UInt32(kVK_ANSI_V) // 'v' key
        let modifiers = UInt32(cmdKey | shiftKey) // Command + Shift
        
        let registerResult = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if registerResult != noErr {
            print("Failed to register hotkey: \(registerResult)")
            // Fallback to NSEvent global monitor
            registerFallbackMonitor()
        } else {
            print("Hotkey registered successfully: Cmd+Shift+V")
        }
    }
    
    private func registerFallbackMonitor() {
        // Fallback: Use NSEvent global monitor
        // Note: This requires accessibility permissions
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Check for Command + Shift + V
            if event.modifierFlags.contains(.command) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == UInt16(kVK_ANSI_V) {
                Task { @MainActor in
                    self?.onQuickSearch?()
                }
            }
        }
    }
}

// MARK: - Key Codes
private let kVK_ANSI_V: UInt32 = 9

// MARK: - Four Char Code Helper
private func fourCharCode(_ string: String) -> UInt32 {
    guard string.count == 4 else { return 0 }
    var result: UInt32 = 0
    for char in string.utf8 {
        result = (result << 8) + UInt32(char)
    }
    return result
}
