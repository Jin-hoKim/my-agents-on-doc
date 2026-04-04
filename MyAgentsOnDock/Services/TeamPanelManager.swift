import AppKit
import SwiftUI
import Combine

// 멀티 캐릭터 패널 관리
@MainActor
class TeamPanelManager {
    static let shared = TeamPanelManager()

    private var panel: TeamDockPanel?
    private var settingsObserver: NSObjectProtocol?
    private var agentsObserver: AnyCancellable?

    func setup() {
        createPanel()
        setupObservers()
    }

    private func createPanel() {
        let newPanel = TeamDockPanel()
        panel = newPanel
        if AppSettings.shared.isPanelVisible {
            newPanel.orderFront(nil)
        }
    }

    private func setupObservers() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                let settings = AppSettings.shared
                if settings.isPanelVisible {
                    self?.panel?.orderFront(nil)
                } else {
                    self?.panel?.orderOut(nil)
                }
                let agentCount = AgentsConfigService.shared.agents.count
                self?.panel?.updateForAgents(count: agentCount)
            }
        }

        agentsObserver = AgentsConfigService.shared.$agents
            .receive(on: RunLoop.main)
            .sink { [weak self] agents in
                self?.panel?.updateForAgents(count: agents.count)
            }
    }

    func teardown() {
        panel?.close()
        panel = nil
        if let obs = settingsObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        agentsObserver?.cancel()
    }
}

// Dock 위 팀 캐릭터 패널 (NSPanel)
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
