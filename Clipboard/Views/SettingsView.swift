import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case shortcuts = "Shortcuts"
    case about = "About"

    var icon: String {
        switch self {
        case .general: return "gear"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @AppStorage("maxHistoryItems") private var maxHistoryItems = 100
    @AppStorage("showSourceApp") private var showSourceApp = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hotKeyEnabled") private var hotKeyEnabled = true

    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            detailContent
        }
        .background(.appBackground)
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        List(selection: $selectedTab) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.appBody)
                }
            }
        }
        .navigationTitle("Settings")
        .background(.appBackground)
    }

    // MARK: - Detail
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .general: generalPane
        case .shortcuts: shortcutsPane
        case .about: aboutPane
        }
    }

    // MARK: - General
    private var generalPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.spacingLarge) {
                settingsSection(icon: "clock.arrow.circlepath", title: "History") {
                    VStack(spacing: AppLayout.spacingMedium) {
                        settingRow {
                            Text("Maximum items")
                                .font(.appBody)
                            Spacer()
                            HStack(spacing: AppLayout.spacingSmall) {
                                Button(action: { if maxHistoryItems > 10 { maxHistoryItems -= 10 } }) {
                                    Image(systemName: "minus")
                                }
                                .buttonStyle(AppSecondaryButtonStyle())
                                .controlSize(.small)

                                Text("\(maxHistoryItems)")
                                    .font(.appBodyMedium)
                                    .frame(width: 40)
                                    .monospacedDigit()

                                Button(action: { if maxHistoryItems < 500 { maxHistoryItems += 10 } }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(AppPrimaryButtonStyle())
                                .controlSize(.small)
                            }
                        }

                        Toggle(isOn: $showSourceApp) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show source application")
                                    .font(.appBody)
                                Text("Display which app the clipboard entry came from")
                                    .font(.appCaption)
                                    .foregroundStyle(.appTextSecondary)
                            }
                        }
                    }
                }

                settingsSection(icon: "power", title: "Startup") {
                    VStack(spacing: AppLayout.spacingMedium) {
                        Toggle(isOn: $launchAtLogin) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch at login")
                                    .font(.appBody)
                                Text("Automatically start Clipboard Manager when you log in")
                                    .font(.appCaption)
                                    .foregroundStyle(.appTextSecondary)
                            }
                        }

                        Toggle(isOn: $hotKeyEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable quick search hotkey")
                                    .font(.appBody)
                                Text("Use ⌘⇧V to open quick search from anywhere")
                                    .font(.appCaption)
                                    .foregroundStyle(.appTextSecondary)
                            }
                        }
                    }
                }
            }
            .padding(AppLayout.spacingLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.appBackground)
    }

    // MARK: - Shortcuts
    private var shortcutsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.spacingLarge) {
                settingsSection(icon: "magnifyingglass", title: "Quick Search") {
                    VStack(spacing: AppLayout.spacingSmall) {
                        shortcutRow(label: "Open Quick Search", shortcut: "⌘⇧V")
                        Text("Press this shortcut anywhere to open the quick search window.")
                            .font(.appCaption)
                            .foregroundStyle(.appTextSecondary)
                    }
                }

                settingsSection(icon: "arrow.up.arrow.down", title: "Navigation") {
                    VStack(spacing: AppLayout.spacingSmall) {
                        shortcutRow(label: "Navigate up", shortcut: "↑")
                        shortcutRow(label: "Navigate down", shortcut: "↓")
                        shortcutRow(label: "Select and copy", shortcut: "↵")
                    }
                }
            }
            .padding(AppLayout.spacingLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.appBackground)
    }

    // MARK: - About
    private var aboutPane: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "scissors")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.accentColor.opacity(0.3), radius: AppLayout.shadowRadius, y: AppLayout.shadowY)

            Text("Clipboard Manager")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, AppLayout.spacingLarge)

            Text("Version 1.0.0")
                .font(.appBody)
                .foregroundStyle(.appTextSecondary)

            Text("A powerful clipboard manager for macOS")
                .font(.appBody)
                .foregroundStyle(.appTextSecondary)
                .padding(.top, 4)

            Spacer()

            HStack(spacing: AppLayout.spacingLarge) {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "star")
                        Text("GitHub")
                    }
                    .font(.appBodyMedium)
                }
                .buttonStyle(AppSecondaryButtonStyle())

                Link(destination: URL(string: "https://support.example.com")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                        Text("Support")
                    }
                    .font(.appBodyMedium)
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
            .padding(.bottom, AppLayout.spacingLarge)
        }
        .frame(maxWidth: .infinity)
        .background(.appBackground)
    }

    // MARK: - Reusable Components

    private func settingsSection(icon: String, title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.spacingMedium) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(.appTextTertiary)
                Text(title)
                    .font(.appCaptionBold)
                    .foregroundStyle(.appTextTertiary)
            }

            content()
                .padding(AppLayout.spacingMedium)
                .background(.appSurface)
                .cornerRadius(AppLayout.cornerRadiusXLarge)
                .shadow(color: .appShadow, radius: AppLayout.shadowRadiusSmall, y: AppLayout.shadowY)
        }
    }

    private func settingRow(@ViewBuilder content: () -> some View) -> some View {
        HStack(content: content)
            .padding(.vertical, 2)
    }

    private func shortcutRow(label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
                .font(.appBody)
            Spacer()
            ShortcutRecorder(hotkey: shortcut)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Shortcut Recorder
struct ShortcutRecorder: View {
    let hotkey: String

    var body: some View {
        Text(hotkey)
            .font(.appBodyMedium)
            .foregroundStyle(.appTextPrimary)
            .padding(.horizontal, AppLayout.paddingSmall)
            .padding(.vertical, 4)
            .background(.appSurfaceSecondary)
            .cornerRadius(AppLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                    .stroke(.appBorder, lineWidth: 1)
            )
    }
}

#Preview {
    SettingsView()
}
