import SwiftUI
import Lottie

// Settings view
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show characters on Dock", isOn: $settings.isPanelVisible)

                LabeledContent("Character Size") {
                    HStack {
                        Slider(
                            value: $settings.characterSize,
                            in: AppSettings.minSize...AppSettings.maxSize,
                            step: 4
                        )
                        .frame(width: 140)
                        Text("\(Int(settings.characterSize))pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 36)
                    }
                }
            }

            Section("Layout") {
                Picker("Layout", selection: Binding(
                    get: { settings.layoutMode },
                    set: { settings.layoutMode = $0 }
                )) {
                    ForEach(LayoutMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                if configService.agents.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("No team configured")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Connect a project folder\nor add team members below")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                } else {
                    ForEach(Array(configService.agents.enumerated()), id: \.element.id) { index, agent in
                        TeamAgentRow(agent: agent, onUpdate: { updated in
                            configService.updateAgent(at: index, with: updated)
                        })
                    }
                }
            } header: {
                HStack {
                    Text("Team (\(configService.agents.count) agents)")
                    Spacer()
                    Button {
                        openSetupWindow()
                    } label: {
                        Text("Connect Project")
                            .font(.caption)
                    }
                    .controlSize(.small)
                }
            }

            Section("Voice") {
                Toggle("Enable TTS", isOn: $settings.ttsEnabled)

                if settings.ttsEnabled {
                    Picker("Voice", selection: Binding(
                        get: { settings.ttsVoice },
                        set: { settings.ttsVoice = $0 }
                    )) {
                        ForEach(TTSVoice.allCases, id: \.self) { voice in
                            Text(voice.displayName).tag(voice)
                        }
                    }

                    Button("Preview") {
                        AgentTTSService.shared.speak("Hello! I am your agent.", force: true)
                    }
                    .controlSize(.small)
                }
            }

            Section("Process Monitor") {
                LabeledContent("Interval") {
                    HStack {
                        Slider(
                            value: $settings.monitorInterval,
                            in: 1...10,
                            step: 1
                        )
                        .frame(width: 140)
                        Text("\(Int(settings.monitorInterval))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                    }
                }

                Text("Periodically detects Claude CLI processes to update agent activity status.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 640)
        .navigationTitle("Settings")
    }

    private func openSetupWindow() {
        NotificationCenter.default.post(name: .openSetup, object: nil)
    }
}

// Team agent row (character selection + name editing)
struct TeamAgentRow: View {
    let agent: TeamAgent
    let onUpdate: (TeamAgent) -> Void

    @State private var showCharacterPicker = false
    @State private var editingName: String = ""
    @State private var isEditingName = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showCharacterPicker = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(characterBackground)
                        .frame(width: 48, height: 48)

                    if let character = agent.character {
                        LottieView(animation: .named(character.fileName, bundle: .module))
                            .playbackMode(.playing(.toProgress(0.5, loopMode: .playOnce)))
                            .frame(width: 40, height: 40)
                    } else {
                        Text(agent.emoji)
                            .font(.system(size: 24))
                    }

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .offset(x: 16, y: 16)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showCharacterPicker) {
                CharacterPickerView(
                    selected: agent.character,
                    onSelect: { character in
                        var updated = agent
                        updated.character = character
                        onUpdate(updated)
                        showCharacterPicker = false
                    }
                )
            }

            VStack(alignment: .leading, spacing: 3) {
                if isEditingName {
                    HStack(spacing: 4) {
                        TextField("Enter name", text: $editingName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: 130)
                            .onSubmit { saveName() }
                        Button { saveName() } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        Button { isEditingName = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    HStack(spacing: 4) {
                        Text(agent.name.isEmpty ? agent.id : agent.name)
                            .font(.system(size: 13, weight: .medium))
                        Button {
                            editingName = agent.name.isEmpty ? agent.id : agent.name
                            isEditingName = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 6) {
                    Text(agent.id)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())

                    Text(agent.modelBadge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(modelColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Circle()
                .fill(agent.isActive ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private func saveName() {
        var updated = agent
        updated.name = editingName.trimmingCharacters(in: .whitespaces)
        onUpdate(updated)
        isEditingName = false
    }

    private var characterBackground: Color {
        if let character = agent.character {
            return Color(hex: character.color).opacity(0.15)
        }
        return Color.secondary.opacity(0.08)
    }

    private var modelColor: Color {
        switch agent.model.lowercased() {
        case "opus":   return .purple
        case "sonnet": return .blue
        case "haiku":  return .teal
        default:       return .gray
        }
    }
}

// Character picker grid popup
struct CharacterPickerView: View {
    let selected: RobotCharacter?
    let onSelect: (RobotCharacter) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Character")
                .font(.headline)
                .padding(.top, 12)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(RobotCharacter.allCases, id: \.self) { character in
                    Button {
                        onSelect(character)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: character.color).opacity(0.15))
                                    .frame(width: 64, height: 64)

                                if selected == character {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.accentColor, lineWidth: 2.5)
                                        .frame(width: 64, height: 64)
                                }

                                LottieView(animation: .named(character.fileName, bundle: .module))
                                    .playbackMode(.playing(.toProgress(0.5, loopMode: .playOnce)))
                                    .frame(width: 50, height: 50)
                            }

                            Text(character.displayName)
                                .font(.system(size: 10))
                                .foregroundColor(selected == character ? .accentColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 260)
    }
}

// Hex color conversion
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

extension Notification.Name {
    static let openSetup = Notification.Name("openSetup")
    static let openSettings = Notification.Name("openSettings")
}
