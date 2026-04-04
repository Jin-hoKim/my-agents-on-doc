import SwiftUI
import Lottie

// 설정 뷰
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared

    var body: some View {
        Form {
            // 섹션 1: 표시 설정
            Section("표시 설정") {
                Toggle("Dock 위 캐릭터 표시", isOn: $settings.isPanelVisible)

                LabeledContent("캐릭터 크기") {
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

            // 섹션 2: 팀 구성 편집
            Section {
                if configService.agents.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("팀이 구성되지 않았습니다")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("프로젝트 폴더를 연결하거나\n아래에서 팀원을 추가하세요")
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
                    Text("팀 구성 (\(configService.agents.count)명)")
                    Spacer()
                    Button {
                        openSetupWindow()
                    } label: {
                        Text("프로젝트 연결")
                            .font(.caption)
                    }
                    .controlSize(.small)
                }
            }

            // 섹션 3: 프로세스 감시
            Section("프로세스 감시") {
                LabeledContent("감시 간격") {
                    HStack {
                        Slider(
                            value: $settings.monitorInterval,
                            in: 1...10,
                            step: 1
                        )
                        .frame(width: 140)
                        Text("\(Int(settings.monitorInterval))초")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                    }
                }

                Text("Claude CLI 프로세스를 주기적으로 감지하여 에이전트 활성 상태를 업데이트합니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 560)
        .navigationTitle("설정")
    }

    private func openSetupWindow() {
        NotificationCenter.default.post(name: .openSetup, object: nil)
    }
}

// 팀 에이전트 행 (캐릭터 선택 + 이름 편집)
struct TeamAgentRow: View {
    let agent: TeamAgent
    let onUpdate: (TeamAgent) -> Void

    @State private var showCharacterPicker = false
    @State private var editingName: String = ""
    @State private var isEditingName = false

    var body: some View {
        HStack(spacing: 12) {
            // 캐릭터 이미지 선택 버튼
            Button {
                showCharacterPicker = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(characterBackground)
                        .frame(width: 48, height: 48)

                    if let character = agent.character {
                        // Lottie 애니메이션 미리보기
                        LottieView(animation: .named(character.fileName, bundle: .main))
                            .playbackMode(.playing(.toProgress(0.5, loopMode: .playOnce)))
                            .frame(width: 40, height: 40)
                    } else {
                        Text(agent.emoji)
                            .font(.system(size: 24))
                    }

                    // 선택 힌트
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

            // 이름 + 역할 정보
            VStack(alignment: .leading, spacing: 3) {
                // 이름 편집
                if isEditingName {
                    TextField("이름 입력", text: $editingName, onCommit: {
                        var updated = agent
                        updated.name = editingName
                        onUpdate(updated)
                        isEditingName = false
                    })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: 150)
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

                // 역할 + 모델
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

            // 활성 상태
            Circle()
                .fill(agent.isActive ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
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

// 캐릭터 선택 그리드 팝업
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
            Text("캐릭터 선택")
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

                                LottieView(animation: .named(character.fileName, bundle: .main))
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

// Hex 색상 변환
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
