import SwiftUI

// 설정 뷰
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared

    var body: some View {
        Form {
            // 섹션 1: 팀 프로젝트
            Section("팀 프로젝트") {
                LabeledContent("연결 상태") {
                    HStack(spacing: 6) {
                        Text(configService.connectionStatus.statusEmoji)
                        Text(configService.connectionStatus.displayText)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("변경...") {
                            openSetupWindow()
                        }
                        .controlSize(.small)
                    }
                }

                if let path = bookmarkService.projectURL?.path {
                    LabeledContent("프로젝트 경로") {
                        Text(path)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            // 섹션 2: 표시 설정
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

            // 섹션 4: 팀 정보
            if !configService.agents.isEmpty {
                Section("팀 구성 (\(configService.agents.count)명)") {
                    ForEach(configService.agents) { agent in
                        HStack {
                            Text(agent.emoji)
                            Text(agent.name.isEmpty ? agent.id : agent.name)
                                .font(.subheadline)
                            Spacer()
                            Text(agent.id)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Circle()
                                .fill(agent.isActive ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 480)
        .navigationTitle("설정")
    }

    private func openSetupWindow() {
        NotificationCenter.default.post(name: .openSetup, object: nil)
    }
}

extension Notification.Name {
    static let openSetup = Notification.Name("openSetup")
    static let openSettings = Notification.Name("openSettings")
}
