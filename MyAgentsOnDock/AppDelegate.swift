import AppKit
import SwiftUI

// 앱 생명주기 관리
class AppDelegate: NSObject, NSApplicationDelegate {
    // 메뉴바 아이콘 (NSStatusItem)
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    private var setupWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var setupObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 아이콘 숨기기 (메뉴바 앱)
        NSApp.setActivationPolicy(.accessory)

        // NSStatusItem + NSPopover 메뉴바 설정
        setupStatusItem()

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

    // MARK: - 메뉴바 아이콘 설정 (NSStatusItem + NSPopover)

    private func setupStatusItem() {
        // NSStatusItem 생성
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "person.3.fill", accessibilityDescription: "My Agents on Dock")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // NSPopover 생성 - MenuBarView를 SwiftUI 콘텐츠로 포함
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 480)
        popover.behavior = .transient  // 팝오버 밖 클릭 시 자동 닫힘
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        self.popover = popover
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            // 팝오버 표시
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // 앱 활성화하여 팝오버가 키 포커스를 받도록
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - 종료

    func applicationWillTerminate(_ notification: Notification) {
        ProcessMonitorService.shared.stopMonitoring()
        TeamPanelManager.shared.teardown()
        BookmarkService.shared.stopAccessing()
        popover?.performClose(nil)
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
