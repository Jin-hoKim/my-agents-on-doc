import AppKit
import SwiftUI

// App lifecycle management
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

    // MARK: - Menu Bar Setup

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

        // Show menu directly at button position
        let point = NSPoint(x: 0, y: button.bounds.height + 5)
        menu.popUp(positioning: nil, at: point, in: button)
    }

    // MARK: - Menu Construction

    private func buildMenu(_ menu: NSMenu) {
        let configService = AgentsConfigService.shared
        let activeCount = configService.agents.filter { $0.isActive }.count
        let statusText = configService.connectionStatus.isConnected
            ? "\(activeCount)/\(configService.agents.count) agents active"
            : configService.connectionStatus.displayText

        // Header
        let header = NSMenuItem()
        header.attributedTitle = NSAttributedString(
            string: "My Agents on Dock — \(statusText)",
            attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold)]
        )
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // Agent list
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

        // Show Dock characters
        let dockToggle = NSMenuItem(title: "Show Characters on Dock", action: #selector(toggleDockPanel), keyEquivalent: "")
        dockToggle.target = self
        dockToggle.state = AppSettings.shared.isPanelVisible ? .on : .off
        menu.addItem(dockToggle)
        menu.addItem(.separator())

        // Connect team project
        menu.addItem(makeItem("Connect Team Project", action: #selector(menuOpenSetup)))
        // Settings
        menu.addItem(makeItem("Settings", action: #selector(menuOpenSettings), key: ","))
        menu.addItem(.separator())
        // Quit
        menu.addItem(makeItem("Quit", action: #selector(menuQuit), key: "q"))
    }

    private func makeItem(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Menu Actions

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

    // MARK: - Termination

    func applicationWillTerminate(_ notification: Notification) {
        ProcessMonitorService.shared.stopMonitoring()
        TeamPanelManager.shared.teardown()
        BookmarkService.shared.stopAccessing()
        setupWindow?.close()
        settingsWindow?.close()
        if let obs = setupObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = settingsObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // Initialize services
    private func initializeServices() {
        _ = BookmarkService.shared
        AgentsConfigService.shared.reload()
        ProcessMonitorService.shared.startMonitoring()
    }

    // Notification observers
    private func setupObservers() {
        setupObserver = NotificationCenter.default.addObserver(
            forName: .openSetup, object: nil, queue: .main
        ) { [weak self] _ in self?.openSetupWindow() }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .openSettings, object: nil, queue: .main
        ) { [weak self] _ in self?.openSettingsWindow() }
    }

    // MARK: - Window Management

    func openSetupWindow() {
        if let window = setupWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = makeWindow(size: NSSize(width: 480, height: 520), title: "Connect Team Project")
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
        let window = makeWindow(size: NSSize(width: 400, height: 480), title: "Settings")
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
