import Foundation
import Combine

// agents.json parsing and FSEvents file watch service
@MainActor
class AgentsConfigService: ObservableObject {
    static let shared = AgentsConfigService()

    @Published var agents: [TeamAgent] = []
    @Published var connectionStatus: ConnectionStatus = .notConnected

    private var fileMonitorSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var debounceWorkItem: DispatchWorkItem?
    private var bookmarkService: BookmarkService { BookmarkService.shared }

    init() {
        // Auto-load saved project on app start
        NotificationCenter.default.addObserver(
            forName: .projectURLChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reload()
            }
        }
    }

    // Load and parse agents.json
    func reload() {
        guard let projectURL = bookmarkService.projectURL else {
            connectionStatus = .notConnected
            agents = []
            return
        }

        let agentsFileURL = projectURL
            .appendingPathComponent("team")
            .appendingPathComponent("agents.json")

        guard FileManager.default.fileExists(atPath: agentsFileURL.path) else {
            connectionStatus = .fileNotFound
            agents = []
            stopMonitoring()
            return
        }

        do {
            let data = try Data(contentsOf: agentsFileURL)
            let config = try JSONDecoder().decode(TeamConfiguration.self, from: data)
            agents = buildAgents(from: config)
            applyCustomizations()
            connectionStatus = .connected
            startMonitoring(agentsFileURL: agentsFileURL)
            NotificationCenter.default.post(name: .agentsDidUpdate, object: nil)
        } catch {
            connectionStatus = .parseError(error.localizedDescription)
            agents = []
            NotificationCenter.default.post(name: .agentsDidUpdate, object: nil)
        }
    }

    // Convert TeamConfiguration → [TeamAgent]
    private func buildAgents(from config: TeamConfiguration) -> [TeamAgent] {
        // Sort by role name (leader first, rest alphabetically)
        let roleOrder = ["leader", "frontend", "backend", "database", "designer", "qa", "devops"]

        return config
            .sorted { a, b in
                let ai = roleOrder.firstIndex(of: a.key) ?? Int.max
                let bi = roleOrder.firstIndex(of: b.key) ?? Int.max
                return ai == bi ? a.key < b.key : ai < bi
            }
            .map { (role, definition) in
                let (name, roleDesc) = parseDescription(definition.description)
                return TeamAgent(
                    id: role,
                    model: definition.model,
                    name: name,
                    roleDescription: roleDesc,
                    emoji: AgentRole.emoji(for: role)
                )
            }
    }

    // Parse "name — description" or "name - description"
    private func parseDescription(_ description: String) -> (name: String, roleDescription: String) {
        // Split by em dash (—) or " - " separator
        let separators = ["—", " - ", "–"]
        for separator in separators {
            if let range = description.range(of: separator) {
                let name = String(description[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let desc = String(description[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    return (name, desc)
                }
            }
        }
        // No separator — use entire string as name
        return (description, "")
    }

    // Detect agents.json file changes via FSEvents
    private func startMonitoring(agentsFileURL: URL) {
        stopMonitoring()

        let fd = open(agentsFileURL.path, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.global(qos: .background)
        )

        source.setEventHandler { [weak self] in
            // debounce 0.5s
            self?.debounceWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                Task { @MainActor [weak self] in
                    self?.reload()
                }
            }
            self?.debounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileMonitorSource = source
    }

    private func stopMonitoring() {
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
        if fileDescriptor >= 0 {
            fileDescriptor = -1
        }
    }

    // Update agent info (character image, name, etc.)
    func updateAgent(at index: Int, with updated: TeamAgent) {
        guard index >= 0, index < agents.count else { return }
        agents[index].name = updated.name
        agents[index].character = updated.character
        // Save changes
        saveCustomizations()
    }

    // Save customization info locally
    private func saveCustomizations() {
        let customs = agents.map { agent in
            AgentCustomization(id: agent.id, name: agent.name, character: agent.character)
        }
        if let data = try? JSONEncoder().encode(customs) {
            UserDefaults.standard.set(data, forKey: "agentCustomizations")
        }
    }

    // Load and apply customization info (name, character, order restoration)
    private func applyCustomizations() {
        guard let data = UserDefaults.standard.data(forKey: "agentCustomizations"),
              let customs = try? JSONDecoder().decode([AgentCustomization].self, from: data) else { return }

        // Apply name and character
        for custom in customs {
            if let index = agents.firstIndex(where: { $0.id == custom.id }) {
                if let name = custom.name { agents[index].name = name }
                agents[index].character = custom.character
            }
        }

        // Sort by saved order
        let savedOrder = customs.map { $0.id }
        if !savedOrder.isEmpty {
            agents.sort { a, b in
                let ai = savedOrder.firstIndex(of: a.id) ?? Int.max
                let bi = savedOrder.firstIndex(of: b.id) ?? Int.max
                return ai < bi
            }
        }
    }

    // Reorder agents (drag-and-drop)
    func reorderAgent(from: Int, to: Int) {
        guard from != to,
              from >= 0, from < agents.count,
              to >= 0, to < agents.count else { return }
        let agent = agents.remove(at: from)
        agents.insert(agent, at: to)
        saveCustomizations()
    }

    // Update agent active state (triggers Published only on actual change)
    func updateAgentActivity(id: String, isActive: Bool, pid: String? = nil) {
        if let index = agents.firstIndex(where: { $0.id == id }) {
            let changed = agents[index].isActive != isActive || agents[index].pid != pid
            if changed {
                agents[index].isActive = isActive
                agents[index].pid = pid
            }
        }
    }

    // Singleton — OS cleans up file descriptors on app exit
}

// Model for saving agent customizations
struct AgentCustomization: Codable {
    let id: String
    let name: String?
    let character: RobotCharacter?
}

extension Notification.Name {
    static let projectURLChanged = Notification.Name("projectURLChanged")
    static let agentsDidUpdate = Notification.Name("agentsDidUpdate")
}
