# AGENTS.md — Clipboard

## Build & Test

- **Build + run**: open `Clipboard.xcodeproj` in Xcode, then `Cmd+B` / `Cmd+R`.
- **All tests**: `Cmd+U` in Xcode, or:
  ```
  xcodebuild test -project Clipboard.xcodeproj -scheme Clipboard -destination 'platform=macOS'
  ```
- **Unit tests** (`ClipboardTests/`) use the **Swift Testing framework** (`@Suite`, `@Test`, `#expect`) — do *not* use `XCTAssert` there.
- **UI tests** (`ClipboardUITests/`) use XCTest.
- No CI, no linter (`swiftlint` etc.), no formatter — just build + test.

## Architecture

- Single macOS app, **no monorepo**.
- Entrypoint: `ClipboardApp.swift` (`@main`). Uses `@NSApplicationDelegateAdaptor` for `AppDelegate`.
- Global `sharedModelContainer` (type `ModelContainer`) — any SwiftData access should use this.
- Views: `ContentView` (tabs: History/Snippets), `MenuBarView`, `QuickSearchView`, `SettingsView`.
- Models: `ClipboardEntry` and `Snippet` — both `@Model` SwiftData classes with `@Observable`.
- Services: `ClipboardMonitor` and `HotKeyManager` — both `@Observable`, `@MainActor`.
- `ClipboardMonitor` polls `NSPasteboard.general.changeCount` every 0.5s; deduplicates same content within 60s.
- Unpinned entries beyond `maxHistoryItems` (default 100) are auto-deleted.
- `HotKeyManager` registers **Cmd+Shift+V** via Carbon Event HotKey API with NSEvent fallback.

## Key Conventions

- Tests use `import Testing` + `@Suite`/`@Test`/`#expect` macros (not XCTest assertions).
- Services use `@Observable` macro, not `ObservableObject`/`@Published`.
- Requires **Accessibility** permission for global hotkeys.
- All data stored locally via SwiftData (`.sqlite` in app support — gitignored).
