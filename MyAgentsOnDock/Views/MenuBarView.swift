import SwiftUI

// 메뉴바 드롭다운 뷰
struct MenuBarView: View {
    @ObservedObject private var configService = AgentsConfigService.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var bookmarkService = BookmarkService.shared

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("👥")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Agents on Dock")
                        .font(.headline)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(configService.connectionStatus.isConnected ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(configService.connectionStatus.displayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // 팀 상태 요약
            if !configService.agents.isEmpty {
                HStack {
                    let activeCount = configService.agents.filter { $0.isActive }.count
                    Text("활성: \(activeCount) / \(configService.agents.count)명")
                        .font(.caption.weight(.medium))
                        .foregroundColor(activeCount > 0 ? .green : .secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

                Divider()

                // 에이전트 목록
                ForEach(configService.agents) { agent in
                    HStack(spacing: 8) {
                        Text(agent.emoji)
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(agent.name)
                                .font(.caption.weight(.medium))
                            Text(agent.id)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                                .frame(width: 6, height: 6)
                            Text(agent.isActive ? "작업 중" : "대기")
                                .font(.caption2)
                                .foregroundColor(agent.isActive ? .green : .secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                }

                Divider()
            }

            // 메뉴 항목
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

                Divider().padding(.vertical, 4)

                // 프로젝트 연결 설정
                MenuBarButton(
                    icon: "folder.badge.gearshape",
                    title: "팀 프로젝트 설정"
                ) {
                    NotificationCenter.default.post(name: .openSetup, object: nil)
                }

                // 설정
                MenuBarButton(icon: "gearshape.fill", title: "환경설정") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }

                Divider().padding(.vertical, 4)

                // 종료
                MenuBarButton(icon: "power", title: "종료") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 300)
    }
}

// 메뉴바 버튼 컴포넌트
struct MenuBarButton: View {
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

extension Notification.Name {
    static let openSetup = Notification.Name("openSetup")
    static let openSettings = Notification.Name("openSettings")
}
