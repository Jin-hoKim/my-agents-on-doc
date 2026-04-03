import SwiftUI

// 메뉴바 드롭다운 뷰
struct MenuBarView: View {
    @ObservedObject private var configService = AgentsConfigService.shared
    @ObservedObject private var settings = AppSettings.shared

    private var activeCount: Int {
        configService.agents.filter { $0.isActive }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
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
                            ? "\(activeCount)/\(configService.agents.count) 에이전트 활성"
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

            // 에이전트 목록
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
                            // 모델 뱃지
                            Text(agent.modelBadge)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(modelBadgeColor(agent.model))
                                .clipShape(Capsule())

                            // 활성 상태
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

            // 메뉴 항목들
            VStack(spacing: 0) {
                // Dock 캐릭터 표시 토글
                Toggle(isOn: $settings.isPanelVisible) {
                    HStack {
                        Image(systemName: "dock.rectangle")
                            .font(.subheadline)
                            .frame(width: 20)
                        Text("Dock 위 캐릭터 표시")
                            .font(.subheadline)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

                Divider().padding(.vertical, 2)

                // 팀 프로젝트 설정
                MenuButton(icon: "folder.badge.plus", title: "팀 프로젝트 연결") {
                    closePopoverAndRun {
                        NotificationCenter.default.post(name: .openSetup, object: nil)
                    }
                }

                // 설정
                MenuButton(icon: "gearshape.fill", title: "설정") {
                    closePopoverAndRun {
                        NotificationCenter.default.post(name: .openSettings, object: nil)
                    }
                }

                Divider().padding(.vertical, 2)

                // 종료
                MenuButton(icon: "power", title: "종료") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280)
    }

    // 팝오버 닫은 뒤 액션 실행
    private func closePopoverAndRun(_ action: @escaping () -> Void) {
        // 현재 뷰의 윈도우(팝오버)를 닫고 다음 런루프에서 액션 실행
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

// 메뉴 버튼 컴포넌트
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
