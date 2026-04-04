import AppKit
import SwiftUI

// 앱 생명주기 관리
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    private var setupWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var setupObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        initializeServices()
        setupObservers()
        TeamPanelManager.shared.setup()

        if BookmarkService.shared.projectURL == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openSetupWindow()
            }
        }
    }

    // MARK: - 메뉴바 설정

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "person.3.fill", accessibilityDescription: "My Agents on Dock")
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()
        buildMenu(menu)

        // 버튼 위치에 메뉴 직접 표시
        let point = NSPoint(x: 0, y: button.bounds.height + 5)
        menu.popUp(positioning: nil, at: point, in: button)
    }

    // MARK: - 메뉴 구성

    private func buildMenu(_ menu: NSMenu) {
        let configService = AgentsConfigService.shared
        let activeCount = configService.agents.filter { $0.isActive }.count
        let statusText = configService.connectionStatus.isConnected
            ? "\(activeCount)/\(configService.agents.count) 에이전트 활성"
            : configService.connectionStatus.displayText

        // 헤더
        let header = NSMenuItem()
        header.attributedTitle = NSAttributedString(
            string: "My Agents on Dock — \(statusText)",
            attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold)]
        )
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // 에이전트 목록
        if !configService.agents.isEmpty {
            for agent in configService.agents {
                let dot = agent.isActive ? "🟢" : "⚫"
                let badge = agent.model.uppercased().prefix(2)
                let name = agent.name.isEmpty ? agent.id : agent.name

                let item = NSMenuItem()
                item.attributedTitle = NSAttributedString(
                    string: "\(dot) \(agent.emoji) \(name) [\(badge)] — \(agent.id)",
                    attributes: [.font: NSFont.systemFont(ofSize: 12)]
                )
                item.isEnabled = false
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }

        // Dock 캐릭터 표시
        let dockToggle = NSMenuItem(title: "Dock 위 캐릭터 표시", action: #selector(toggleDockPanel), keyEquivalent: "")
        dockToggle.target = self
        dockToggle.state = AppSettings.shared.isPanelVisible ? .on : .off
        menu.addItem(dockToggle)
        menu.addItem(.separator())

        // 팀 프로젝트 연결
        menu.addItem(makeItem("팀 프로젝트 연결", action: #selector(menuOpenSetup)))
        // 설정
        menu.addItem(makeItem("설정", action: #selector(menuOpenSettings), key: ","))
        menu.addItem(.separator())
        // 종료
        menu.addItem(makeItem("종료", action: #selector(menuQuit), key: "q"))
    }

    private func makeItem(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - 메뉴 액션

    @objc private func toggleDockPanel() {
        AppSettings.shared.isPanelVisible.toggle()
    }

    @objc private func menuOpenSetup() {
        openSetupWindow()
    }

    @objc private func menuOpenSettings() {
        openSettingsWindow()
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }

    // MARK: - 종료

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
        _ = BookmarkService.shared
        AgentsConfigService.shared.reload()
        ProcessMonitorService.shared.startMonitoring()
    }

    // 알림 옵저버
    private func setupObservers() {
        setupObserver = NotificationCenter.default.addObserver(
            forName: .openSetup, object: nil, queue: .main
        ) { [weak self] _ in self?.openSetupWindow() }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openSettings, object: nil, queue: .main
        ) { [weak self] _ in self?.openSettingsWindow() }
    }

    // MARK: - 창 관리

    func openSetupWindow() {
        if let window = setupWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = makeWindow(size: NSSize(width: 480, height: 520), title: "팀 프로젝트 연결")
        window.contentView = NSHostingView(rootView: SetupView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupWindow = window
    }

    private func openSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = makeWindow(size: NSSize(width: 400, height: 480), title: "설정")
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    private func makeWindow(size: NSSize, title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }
}
