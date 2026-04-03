import AppKit
import SwiftUI
import Combine

// 멀티 캐릭터 Dock 패널 관리
class TeamDockPanel: NSPanel {
    private var cancellables = Set<AnyCancellable>()
    private var defaultsObserver: NSObjectProtocol?

    init() {
        let size = AppSettings.shared.characterSize
        let (width, height) = TeamDockPanel.calculatePanelSize(
            agentCount: max(1, AgentsConfigService.shared.agents.count),
            characterSize: size
        )

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
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

        // SwiftUI 뷰 연결
        let hostingView = NSHostingView(rootView: TeamDockView())
        contentView = hostingView

        positionAboveDock()
        setupObservers()
    }

    // 패널 크기 계산
    static func calculatePanelSize(agentCount: Int, characterSize: Double) -> (width: CGFloat, height: CGFloat) {
        let itemWidth = characterSize + 16   // 캐릭터 + 간격
        let padding: CGFloat = 20
        let nameHeight: CGFloat = 30        // 이름 라벨 공간

        guard let screen = NSScreen.main else {
            let width = itemWidth * CGFloat(agentCount) + padding
            let height = characterSize + nameHeight + padding
            return (width, height)
        }

        let maxWidth = screen.frame.width * 0.85
        let totalWidth = itemWidth * CGFloat(agentCount) + padding

        if totalWidth <= maxWidth {
            // 1행 배치
            return (totalWidth, characterSize + nameHeight + padding)
        } else {
            // 2행 배치
            let columns = Int(maxWidth / itemWidth)
            let rows = Int(ceil(Double(agentCount) / Double(max(1, columns))))
            let actualWidth = itemWidth * CGFloat(min(agentCount, columns)) + padding
            let actualHeight = (characterSize + nameHeight) * CGFloat(rows) + padding
            return (actualWidth, actualHeight)
        }
    }

    private func setupObservers() {
        // 화면 변경 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // 에이전트 목록 변경 감지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(agentsChanged),
            name: .agentsDidChange,
            object: nil
        )

        // 패널 표시 토글 감지
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let visible = UserDefaults.standard.bool(forKey: "characterPanelVisible")
            if visible {
                self?.orderFront(nil)
            } else {
                self?.orderOut(nil)
            }
        }
    }

    @objc private func screenChanged() {
        positionAboveDock()
    }

    @objc private func agentsChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updatePanelSize()
        }
    }

    // 에이전트 수 변경 시 패널 크기 업데이트
    func updatePanelSize() {
        let agentCount = max(1, AgentsConfigService.shared.agents.count)
        let size = AppSettings.shared.characterSize
        let (width, height) = TeamDockPanel.calculatePanelSize(agentCount: agentCount, characterSize: size)
        setContentSize(NSSize(width: width, height: height))
        positionAboveDock()
    }

    // Dock 위에 패널 위치 조정
    func positionAboveDock() {
        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let fullFrame = screen.frame

        let dockHeight = visibleFrame.origin.y - fullFrame.origin.y
        let dockWidth = fullFrame.width - visibleFrame.width

        let panelFrame = frame

        if dockHeight > 0 {
            // Dock이 하단에 위치
            let x = (fullFrame.width - panelFrame.width) / 2 + fullFrame.origin.x
            let y = fullFrame.origin.y + dockHeight + 5
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 && visibleFrame.origin.x > fullFrame.origin.x {
            // Dock이 왼쪽에 위치
            let x = fullFrame.origin.x + dockWidth + 5
            let y = fullFrame.origin.y + 80
            setFrameOrigin(NSPoint(x: x, y: y))
        } else if dockWidth > 0 {
            // Dock이 오른쪽에 위치
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
        if let observer = defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension Notification.Name {
    static let agentsDidChange = Notification.Name("agentsDidChange")
}
