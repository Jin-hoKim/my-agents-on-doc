import SwiftUI

// 멀티 캐릭터 Dock 뷰 (HStack으로 에이전트 배치)
struct TeamDockView: View {
    @ObservedObject private var configService = AgentsConfigService.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        let agents = configService.agents
        let size = settings.characterSize

        if agents.isEmpty {
            // 에이전트 없음 — 기본 플레이스홀더
            placeholderView(size: size)
        } else if agents.count <= columnsPerRow(size: size) {
            // 1행 배치
            HStack(spacing: 8) {
                ForEach(agents) { agent in
                    AgentCharacterView(agent: agent, characterSize: size)
                }
            }
            .padding(10)
        } else {
            // 2행 배치 (에이전트 수가 많을 때)
            let columns = columnsPerRow(size: size)
            let rows = chunked(agents, by: columns)
            VStack(spacing: 6) {
                ForEach(rows.indices, id: \.self) { rowIdx in
                    HStack(spacing: 8) {
                        ForEach(rows[rowIdx]) { agent in
                            AgentCharacterView(agent: agent, characterSize: size)
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    // 플레이스홀더 (에이전트 미연결 상태)
    private func placeholderView(size: Double) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.1), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: size * 0.85, height: size * 0.85)

                Text("👥")
                    .font(.system(size: size * 0.4))
            }
            Text("팀 미연결")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(width: size + 16, height: size + 34)
        .padding(10)
    }

    // 화면 너비 기준 한 행에 배치 가능한 에이전트 수
    private func columnsPerRow(size: Double) -> Int {
        guard let screen = NSScreen.main else { return 7 }
        let maxWidth = screen.frame.width * 0.85
        let itemWidth = size + 16 + 8 // 캐릭터 + 패딩 + 간격
        return max(1, Int(maxWidth / itemWidth))
    }

    // 배열을 n개씩 분할
    private func chunked(_ array: [TeamAgent], by size: Int) -> [[TeamAgent]] {
        stride(from: 0, to: array.count, by: size).map {
            Array(array[$0..<min($0 + size, array.count)])
        }
    }
}
