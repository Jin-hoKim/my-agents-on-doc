import SwiftUI

// 멀티 캐릭터 Dock 뷰 (레이아웃 모드 지원 + 드래그 배치)
struct TeamDockView: View {
    @ObservedObject private var configService = AgentsConfigService.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var draggingAgent: TeamAgent?

    var body: some View {
        Group {
            if configService.agents.isEmpty {
                emptyStateView
            } else {
                layoutView
            }
        }
        .background(Color.clear)
    }

    // 레이아웃 모드에 따른 뷰
    @ViewBuilder
    private var layoutView: some View {
        switch settings.layoutMode {
        case .singleRow:
            // 가로 1줄
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    agentViews
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        case .singleColumn:
            // 세로 1줄
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    agentViews
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 10)
            }
        case .doubleRow:
            // 가로 2줄
            ScrollView(.horizontal, showsIndicators: false) {
                let rows = splitIntoRows(configService.agents, count: 2)
                VStack(spacing: 4) {
                    ForEach(0..<rows.count, id: \.self) { rowIndex in
                        HStack(spacing: 8) {
                            ForEach(rows[rowIndex]) { agent in
                                draggableAgent(agent)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        case .doubleColumn:
            // 세로 2줄
            ScrollView(.vertical, showsIndicators: false) {
                let cols = splitIntoRows(configService.agents, count: 2)
                HStack(spacing: 4) {
                    ForEach(0..<cols.count, id: \.self) { colIndex in
                        VStack(spacing: 8) {
                            ForEach(cols[colIndex]) { agent in
                                draggableAgent(agent)
                            }
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 10)
            }
        }
    }

    // 에이전트 뷰 목록 (1열/1횡용)
    private var agentViews: some View {
        ForEach(configService.agents) { agent in
            draggableAgent(agent)
        }
    }

    // 드래그 가능한 에이전트
    private func draggableAgent(_ agent: TeamAgent) -> some View {
        AgentCharacterView(
            agent: agent,
            size: settings.characterSize
        )
        .opacity(draggingAgent?.id == agent.id ? 0.4 : 1.0)
        .onDrag {
            draggingAgent = agent
            return NSItemProvider(object: agent.id as NSString)
        }
        .onDrop(of: [.text], delegate: AgentDropDelegate(
            agent: agent,
            agents: configService.agents,
            draggingAgent: $draggingAgent,
            onReorder: { from, to in
                configService.reorderAgent(from: from, to: to)
            }
        ))
    }

    // N줄로 분할
    private func splitIntoRows(_ agents: [TeamAgent], count: Int) -> [[TeamAgent]] {
        let perRow = Int(ceil(Double(agents.count) / Double(count)))
        var result: [[TeamAgent]] = []
        for i in 0..<count {
            let start = i * perRow
            let end = min(start + perRow, agents.count)
            if start < agents.count {
                result.append(Array(agents[start..<end]))
            }
        }
        return result
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

// 드래그앤드롭 델리게이트
struct AgentDropDelegate: DropDelegate {
    let agent: TeamAgent
    let agents: [TeamAgent]
    @Binding var draggingAgent: TeamAgent?
    let onReorder: (Int, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingAgent = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingAgent,
              dragging.id != agent.id,
              let fromIndex = agents.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = agents.firstIndex(where: { $0.id == agent.id }) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            onReorder(fromIndex, toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
    }
}
