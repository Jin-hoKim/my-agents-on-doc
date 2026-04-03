import AppKit
import SwiftUI

// 앱 생명주기 관리
class AppDelegate: NSObject, NSApplicationDelegate {
    private var setupWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var setupObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기 (메뉴바 앱)
        NSApp.setActivationPolicy(.accessory)

        // 서비스 초기화 체인
        initializeServices()

        // 알림 옵저버 등록
        setupObservers()

        // Dock 위 팀 패널 생성
        TeamPanelManager.shared.setup()

        // 저장된 프로젝트 없으면 SetupView 자동 표시
        if BookmarkService.shared.projectURL == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openSetupWindow()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessMonitorService.shared.stopMonitoring()
        TeamPanelManager.shared.teardown()
        BookmarkService.shared.stopAccessing()
        setupWindow?.close()
        settingsWindow?.close()
        if let obs = setupObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = settingsObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // 서비스 초기화
    private func initializeServices() {
        Task { @MainActor in
            _ = BookmarkService.shared
            AgentsConfigService.shared.reload()
            ProcessMonitorService.shared.startMonitoring()
        }
    }

    // 알림 옵저버 등록
    private func setupObservers() {
        setupObserver = NotificationCenter.default.addObserver(
            forName: .openSetup,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSetupWindow()
        }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openSettingsWindow()
        }
    }

    // Setup 창 열기
    func openSetupWindow() {
        if let window = setupWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "팀 프로젝트 연결"
        window.contentView = NSHostingView(rootView: SetupView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.setupWindow = window
    }

    // 설정 창 열기
    private func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "설정"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow = window
    }
}
