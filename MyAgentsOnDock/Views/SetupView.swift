import SwiftUI
import AppKit

// Initial setup / project connection view
struct SetupView: View {
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared

    // Embedded in NSHostingView — find and close the hosting window directly
    private func closeWindow() {
        DispatchQueue.main.async {
            // Find the window hosting this view
            if let window = NSApp.windows.first(where: { $0.title == "Connect Team Project" }) {
                window.close()
            } else {
                NSApp.keyWindow?.close()
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Section 1: Project folder selection
                    projectFolderSection

                    Divider()

                    // Section 2: agents.json status
                    agentsFileStatusSection

                    // Section 3: Team preview
                    if !configService.agents.isEmpty {
                        Divider()
                        teamPreviewSection
                    }
                }
                .padding(20)
            }

            Divider()

            // Bottom buttons
            bottomButtons
        }
        .frame(width: 480, height: 520)
        .onAppear {
            configService.reload()
        }
    }

    // Header
    private var headerSection: some View {
        HStack {
            Text("🤖")
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text("My Agents on Dock")
                    .font(.headline)
                Text("Connect your Claude Code team project")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    // Section 1: Project folder selection
    private var projectFolderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Project Folder", systemImage: "folder")
                .font(.subheadline.weight(.semibold))

            HStack {
                if let url = bookmarkService.projectURL {
                    Text(url.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("No folder selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }

                Button("Choose...") {
                    bookmarkService.selectProjectFolder()
                    // Auto-reload after folder selection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: .projectURLChanged, object: nil)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // Section 2: agents.json status
    private var agentsFileStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("agents.json Status", systemImage: "doc.text")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                Text(configService.connectionStatus.statusEmoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(configService.connectionStatus.displayText)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                    if let url = bookmarkService.projectURL {
                        Text(url.appendingPathComponent("team/agents.json").path)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()

                // Refresh button
                Button(action: { configService.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(statusBackground)
            .cornerRadius(8)

            // agents.json format guide (shown on error)
            if case .parseError = configService.connectionStatus {
                agentsJsonGuide
            }
            if case .fileNotFound = configService.connectionStatus {
                agentsJsonGuide
            }
        }
    }

    // Section 3: Team preview
    private var teamPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Team (\(configService.agents.count) members)", systemImage: "person.3")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 1) {
                // Header row
                HStack {
                    Text("Role").frame(width: 80, alignment: .leading)
                    Text("Name").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Model").frame(width: 80, alignment: .leading)
                    Text("Description").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))

                // Agent rows
                ForEach(configService.agents) { agent in
                    HStack {
                        HStack(spacing: 4) {
                            Text(agent.emoji)
                            Text(agent.id)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .frame(width: 80, alignment: .leading)

                        Text(agent.name.isEmpty ? "-" : agent.name)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(agent.model)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(modelColor(agent.model))
                            .frame(width: 80, alignment: .leading)

                        Text(agent.roleDescription.isEmpty ? "-" : agent.roleDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.clear)

                    Divider()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // agents.json format guide
    private var agentsJsonGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("agents.json format example:")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Text("""
{
  "leader": {
    "model": "opus",
    "description": "PM Alex — requirements analysis",
    "prompt": "You are a PM..."
  },
  "frontend": {
    "model": "sonnet",
    "description": "Dev Sam — Vue 3 specialist",
    "prompt": "..."
  }
}
""")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
        }
    }

    // Bottom buttons
    private var bottomButtons: some View {
        HStack {
            if bookmarkService.projectURL != nil {
                Button("Disconnect") {
                    DispatchQueue.main.async {
                        bookmarkService.clearBookmark()
                        configService.reload()
                    }
                }
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }

            Spacer()

            Button("Close") {
                closeWindow()
            }

            Button("Connect Team") {
                AppSettings.shared.isPanelVisible = true
                closeWindow()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!configService.connectionStatus.isConnected)
        }
        .padding(16)
    }

    private var statusColor: Color {
        switch configService.connectionStatus {
        case .connected:    return .green
        case .fileNotFound, .parseError: return .red
        default:            return .secondary
        }
    }

    private var statusBackground: Color {
        switch configService.connectionStatus {
        case .connected:    return .green.opacity(0.08)
        case .fileNotFound, .parseError: return .red.opacity(0.08)
        default:            return .secondary.opacity(0.06)
        }
    }

    private func modelColor(_ model: String) -> Color {
        switch model.lowercased() {
        case "opus":   return .purple
        case "sonnet": return .blue
        case "haiku":  return .teal
        default:       return .secondary
        }
    }
}
