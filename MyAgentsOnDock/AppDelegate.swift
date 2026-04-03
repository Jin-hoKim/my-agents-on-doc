import AppKit
import SwiftUI
import Combine

// 앱 생명주기 관리
class AppDelegate: NSObject, NSApplicationDelegate {
    private var dockPanel: TeamDockPanel?
    private var setupWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var observers: [NSObjectProtocol] = []
    private var agentsCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기
        NSApp.setActivationPolicy(.accessory)

        // 서비스 초기화 체인
        Task { @MainActor in
            // 1. bookmark 복원
            BookmarkService.shared.restoreBookmark()

            // 2. agents.json 로드
            if BookmarkService.shared.projectURL != nil {
                AgentsConfigService.shared.loadAgents()
            }

            // 3. 팀 패널 생성
            let panel = TeamDockPanel()
            self.dockPanel = panel
            if AppSettings.shared.isPanelVisible {
                panel.orderFront(nil)
            }

            // 4. 에이전트 목록 변경 시 패널 크기 업데이트
            agentsCancellable = AgentsConfigService.shared.$agents
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.dockPanel?.updatePanelSize()
                    NotificationCenter.default.post(name: .agentsDidChange, object: nil)
                }

            // 5. 프로세스 모니터 시작 (에이전트가 있을 때만)
            if !AgentsConfigService.shared.agents.isEmpty {
                ProcessMonitorService.shared.start()
            }

            // bookmark 없으면 SetupView 자동 오픈
            if BookmarkService.shared.projectURL == nil {
                openSetupWindow()
            }
        }

        // 이벤트 옵저버 등록
        setupObservers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessMonitorService.shared.stop()
        AgentsConfigService.shared.stopWatching()
        BookmarkService.shared.stopAccessing()

        dockPanel?.close()
        setupWindow?.close()
        settingsWindow?.close()

        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    private func setupObservers() {
        let setupObs = NotificationCenter.default.addObserver(
            forName: .openSetup,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSetupWindow()
        }

        let settingsObs = NotificationCenter.default.addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSettingsWindow()
        }

        observers = [setupObs, settingsObs]
    }

    // 설정(Setup) 창 열기
    private func openSetupWindow() {
        if let window = setupWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 580),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "팀 프로젝트 설정"
        window.contentView = NSHostingView(rootView: SetupView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupWindow = window
    }

    // 환경설정 창 열기
    private func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "환경설정"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }
}
