import SwiftUI

// Menu bar dropdown view
struct MenuBarView: View {
    @ObservedObject private var configService = AgentsConfigService.shared
    @ObservedObject private var settings = AppSettings.shared

    private var activeCount: Int {
        configService.agents.filter { $0.isActive }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🤖")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Agents on Dock")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(configService.connectionStatus.isConnected ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(configService.connectionStatus.isConnected
                            ? "\(activeCount)/\(configService.agents.count) agents active"
                            : configService.connectionStatus.displayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Agent list
            if !configService.agents.isEmpty {
                VStack(spacing: 0) {
                    ForEach(configService.agents) { agent in
                        HStack {
                            Text(agent.emoji)
                                .font(.subheadline)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(agent.name.isEmpty ? agent.id : agent.name)
                                    .font(.subheadline)
                                Text(agent.id)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            // Model badge
                            Text(agent.modelBadge)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(modelBadgeColor(agent.model))
                                .clipShape(Capsule())

                            // Active state indicator
                            Circle()
                                .fill(agent.isActive ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 7, height: 7)
                                .shadow(color: agent.isActive ? .green : .clear, radius: 2)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                }

                Divider()
            }

            // Menu items
            VStack(spacing: 0) {
                // Toggle Dock character display
                Toggle(isOn: $settings.isPanelVisible) {
                    HStack {
                        Image(systemName: "dock.rectangle")
                            .font(.subheadline)
                            .frame(width: 20)
                        Text("Show Characters on Dock")
                            .font(.subheadline)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

                Divider().padding(.vertical, 2)

                // Team project setup
                MenuButton(icon: "folder.badge.plus", title: "Connect Team Project") {
                    closePopoverAndRun {
                        NotificationCenter.default.post(name: .openSetup, object: nil)
                    }
                }

                // Settings
                MenuButton(icon: "gearshape.fill", title: "Settings") {
                    closePopoverAndRun {
                        NotificationCenter.default.post(name: .openSettings, object: nil)
                    }
                }

                Divider().padding(.vertical, 2)

                // Quit
                MenuButton(icon: "power", title: "Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }

    // Close popover then execute action
    private func closePopoverAndRun(_ action: @escaping () -> Void) {
        // Close the current view's window (popover) and execute action on next run loop
        NSApp.windows.first(where: { $0.className.contains("Popover") })?.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
        }
    }

    private func modelBadgeColor(_ model: String) -> Color {
        switch model.lowercased() {
        case "opus":   return .purple
        case "sonnet": return .blue
        case "haiku":  return .teal
        default:       return .gray
        }
    }
}

// Menu button component
struct MenuButton: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                Spacer()
                if let shortcut {
                    Text(shortcut)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
