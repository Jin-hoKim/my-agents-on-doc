import SwiftUI

// 멀티 캐릭터 Dock 뷰 (HStack으로 에이전트 나열)
struct TeamDockView: View {
    @ObservedObject private var configService = AgentsConfigService.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Group {
            if configService.agents.isEmpty {
                // 에이전트 없을 때 플레이스홀더
                emptyStateView
            } else {
                // 에이전트 목록
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(configService.agents) { agent in
                            AgentCharacterView(
                                agent: agent,
                                size: settings.characterSize
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
            }
        }
        .background(Color.clear)
    }

    private var emptyStateView: some View {
        VStack(spacing: 4) {
            Text("🤖")
                .font(.system(size: 28))
                .opacity(0.4)
            Text("팀 미연결")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 70)
    }
}
