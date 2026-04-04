import AppKit
import SwiftUI
import Combine

// 멀티 캐릭터 패널 관리 (그룹 모드 + 개별 이동 모드)
@MainActor
class TeamPanelManager {
    static let shared = TeamPanelManager()

    // 그룹 패널 (1열/1횡/2열/2횡 모드)
    private var groupPanel: TeamDockPanel?
    // 개별 패널 (개별 이동 모드)
    private var individualPanels: [String: AgentDockPanel] = [:]

    private var settingsObserver: NSObjectProtocol?
    private var agentsObserver: AnyCancellable?

    func setup() {
        updatePanels()
        setupObservers()
    }

    private func setupObservers() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updatePanels()
            }
        }

        agentsObserver = AgentsConfigService.shared.$agents
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updatePanels()
            }
    }

    private func updatePanels() {
        let settings = AppSettings.shared
        let agents = AgentsConfigService.shared.agents

        if settings.layoutMode == .freeform {
            // 개별 이동 모드
            groupPanel?.close()
            groupPanel = nil
            updateIndividualPanels(agents: agents, settings: settings)
        } else {
            // 그룹 모드
            closeIndividualPanels()
            updateGroupPanel(agents: agents, settings: settings)
        }
    }

    // MARK: - 그룹 패널

    private func updateGroupPanel(agents: [TeamAgent], settings: AppSettings) {
        if groupPanel == nil {
            let panel = TeamDockPanel()
            groupPanel = panel
        }

        if settings.isPanelVisible {
            groupPanel?.updateForAgents(count: agents.count)
            groupPanel?.orderFront(nil)
        } else {
            groupPanel?.orderOut(nil)
        }
    }

    // MARK: - 개별 패널

    private func updateIndividualPanels(agents: [TeamAgent], settings: AppSettings) {
        // 삭제된 에이전트 패널 제거
        let agentIds = Set(agents.map { $0.id })
        for (id, panel) in individualPanels where !agentIds.contains(id) {
            panel.close()
            individualPanels.removeValue(forKey: id)
        }

        // 에이전트별 패널 생성/업데이트
        for (index, agent) in agents.enumerated() {
            if let panel = individualPanels[agent.id] {
                // 기존 패널 업데이트
                panel.updateContent(agent: agent, size: settings.characterSize)
                if settings.isPanelVisible {
                    panel.orderFront(nil)
                } else {
                    panel.orderOut(nil)
                }
            } else {
                // 새 패널 생성
                let panel = AgentDockPanel(agent: agent, size: settings.characterSize, index: index)
                individualPanels[agent.id] = panel
                if settings.isPanelVisible {
                    panel.orderFront(nil)
                }
            }
        }
    }

    private func closeIndividualPanels() {
        for (_, panel) in individualPanels {
            panel.close()
        }
        individualPanels.removeAll()
    }

    func teardown() {
        groupPanel?.close()
        groupPanel = nil
        closeIndividualPanels()
        if let obs = settingsObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        agentsObserver?.cancel()
    }
}

// MARK: - 개별 에이전트 패널

class AgentDockPanel: NSPanel {
    private var agentId: String

    init(agent: TeamAgent, size: CGFloat, index: Int) {
        self.agentId = agent.id
        let panelSize = NSSize(width: size + 28, height: size + max(30, size * 0.25) + 16)
        super.init(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: AgentCharacterView(agent: agent, size: size))
        contentView = hostingView

        // 저장된 위치 복원 또는 기본 위치
        if let saved = loadPosition() {
            setFrameOrigin(saved)
        } else {
            positionDefault(index: index, size: size)
        }
    }

    func updateContent(agent: TeamAgent, size: CGFloat) {
        let panelSize = NSSize(width: size + 28, height: size + max(30, size * 0.25) + 16)
        setContentSize(panelSize)
        contentView = NSHostingView(rootView: AgentCharacterView(agent: agent, size: size))
    }

    // 기본 위치 (Dock 위에 나란히)
    private func positionDefault(index: Int, size: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let dockHeight = visibleFrame.origin.y - fullFrame.origin.y
        let spacing = size + 36
        let totalWidth = spacing * CGFloat(AgentsConfigService.shared.agents.count)
        let startX = (fullFrame.width - totalWidth) / 2 + fullFrame.origin.x
        let x = startX + spacing * CGFloat(index)
        let y = fullFrame.origin.y + max(dockHeight, 5) + 5
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    // 위치 저장
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        savePosition()
    }

    private func savePosition() {
        let key = "agentPosition_\(agentId)"
        let point = frame.origin
        UserDefaults.standard.set(["x": point.x, "y": point.y], forKey: key)
    }

    private func loadPosition() -> NSPoint? {
        let key = "agentPosition_\(agentId)"
        guard let dict = UserDefaults.standard.dictionary(forKey: key),
              let x = dict["x"] as? CGFloat,
              let y = dict["y"] as? CGFloat else { return nil }
        return NSPoint(x: x, y: y)
    }
}

// MARK: - 그룹 Dock 패널

class TeamDockPanel: NSPanel {
    private let horizontalPadding: CGFloat = 16.0
    private let verticalPadding: CGFloat = 8.0

    private var currentCharacterSize: CGFloat {
        CGFloat(AppSettings.shared.characterSize)
    }

    init() {
        let charSize = CGFloat(AppSettings.shared.characterSize)
        let initialSize = NSSize(width: 100, height: charSize + 50)
        super.init(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        contentView = NSHostingView(rootView: TeamDockView())
        positionAboveDock()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenChanged() {
        positionAboveDock()
    }

    func updateForAgents(count: Int) {
        let agentCount = max(count, 1)
        let charSize = currentCharacterSize
        let layout = AppSettings.shared.layoutMode
        let panelSize = calculatePanelSize(agentCount: agentCount, charSize: charSize, layout: layout)
        setContentSize(panelSize)
        positionAboveDock()
    }

    private func calculatePanelSize(agentCount: Int, charSize: CGFloat, layout: LayoutMode) -> NSSize {
        guard let screen = NSScreen.main else { return NSSize(width: 200, height: 200) }
        let maxWidth = screen.frame.width * 0.95
        let maxHeight = screen.frame.height * 0.8

        let perAgentW: CGFloat = charSize + 28
        let perAgentH: CGFloat = charSize + max(30, charSize * 0.25) + 16

        var width: CGFloat
        var height: CGFloat

        switch layout {
        case .singleRow:
            width = perAgentW * CGFloat(agentCount) + 40
            height = perAgentH + verticalPadding * 2
        case .singleColumn:
            width = perAgentW + horizontalPadding * 2
            height = perAgentH * CGFloat(agentCount) + 20
        case .doubleRow:
            let perRow = Int(ceil(Double(agentCount) / 2.0))
            width = perAgentW * CGFloat(perRow) + 40
            height = perAgentH * 2 + verticalPadding * 2
        case .doubleColumn:
            let perCol = Int(ceil(Double(agentCount) / 2.0))
            width = perAgentW * 2 + horizontalPadding * 2
            height = perAgentH * CGFloat(perCol) + 20
        case .freeform:
            // 개별 모드에서는 그룹 패널 사용 안함
            width = 0
            height = 0
        }

        return NSSize(width: min(width, maxWidth), height: min(height, maxHeight))
    }

    func positionAboveDock() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame
        let dockHeight = visibleFrame.origin.y - fullFrame.origin.y
        let dockWidth = fullFrame.width - visibleFrame.width
        let panelFrame = frame

        if dockHeight > 0 {
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + dockHeight + 5
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 && visibleFrame.origin.x > fullFrame.origin.x {
            let x = fullFrame.origin.x + dockWidth + 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 {
            let x = fullFrame.origin.x + fullFrame.width - dockWidth - panelFrame.width - 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + 10
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
