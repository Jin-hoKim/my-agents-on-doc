import AppKit
import SwiftUI

// 멀티 캐릭터 NSPanel 관리
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
        // 패널 가시성 및 캐릭터 크기 변경 감지
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
                // 캐릭터 크기 변경 시 패널 리사이즈
                let agentCount = AgentsConfigService.shared.agents.count
                self?.panel?.updateForAgents(count: agentCount)
            }
        }

        // agents 변경 시 패널 크기 업데이트
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
    private let characterSpacing: CGFloat = 8.0
    private let horizontalPadding: CGFloat = 16.0
    private let verticalPadding: CGFloat = 8.0

    // 설정에서 캐릭터 크기 가져오기
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

        // SwiftUI 뷰 연결
        let hostingView = NSHostingView(rootView: TeamDockView())
        contentView = hostingView

        positionAboveDock()
        setupObservers()
    }

    private func setupObservers() {
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

    // agents 수에 따른 패널 크기 업데이트
    func updateForAgents(count: Int) {
        let agentCount = max(count, 1)
        let charSize = currentCharacterSize
        let totalWidth = calculateWidth(agentCount: agentCount, charSize: charSize)
        // 캐릭터 뷰 높이: size + 38 (AgentCharacterView) + 상하 패딩
        let totalHeight = charSize + 38 + verticalPadding * 2 + 12
        setContentSize(NSSize(width: totalWidth, height: totalHeight))
        positionAboveDock()
    }

    // 패널 너비 계산
    private func calculateWidth(agentCount: Int, charSize: CGFloat) -> CGFloat {
        guard let screen = NSScreen.main else { return 200 }
        let maxWidth = screen.frame.width * 0.95
        // 각 캐릭터 영역: 캐릭터 크기 + 여유 공간
        let perAgent: CGFloat = max(charSize + 10, 80)
        let calculated = perAgent * CGFloat(agentCount) + 40  // 좌우 여백
        return min(calculated, maxWidth)
    }

    // Dock 위 위치 조정
    func positionAboveDock() {
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame

        let dockHeight = visibleFrame.origin.y - fullFrame.origin.y
        let dockWidth = fullFrame.width - visibleFrame.width

        let panelFrame = frame

        if dockHeight > 0 {
            // Dock 하단
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + dockHeight + 5
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 && visibleFrame.origin.x > fullFrame.origin.x {
            // Dock 왼쪽
            let x = fullFrame.origin.x + dockWidth + 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 {
            // Dock 오른쪽
            let x = fullFrame.origin.x + fullFrame.width - dockWidth - panelFrame.width - 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Dock 자동 숨김
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + 10
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Combine을 위한 import
import Combine
