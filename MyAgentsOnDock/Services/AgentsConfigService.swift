import Foundation
import Combine

// agents.json 파싱 및 FSEvents 감시 서비스
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
        // 앱 시작 시 저장된 프로젝트로 자동 로드
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

    // agents.json 로드 및 파싱
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

    // TeamConfiguration → [TeamAgent] 변환
    private func buildAgents(from config: TeamConfiguration) -> [TeamAgent] {
        // 역할명 기준 정렬 (leader 우선, 나머지 알파벳 순)
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

    // "이름 — 설명" 또는 "이름 - 설명" 파싱
    private func parseDescription(_ description: String) -> (name: String, roleDescription: String) {
        // em dash(—) 또는 " - " 구분자로 분리
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
        // 구분자 없으면 전체를 이름으로
        return (description, "")
    }

    // FSEvents로 agents.json 파일 변경 감지
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
            // debounce 0.5초
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

    // 에이전트 정보 업데이트 (캐릭터 이미지, 이름 등)
    func updateAgent(at index: Int, with updated: TeamAgent) {
        guard index >= 0, index < agents.count else { return }
        agents[index].name = updated.name
        agents[index].character = updated.character
        // 변경사항 저장
        saveCustomizations()
    }

    // 커스터마이징 정보 로컬 저장
    private func saveCustomizations() {
        let customs = agents.map { agent in
            AgentCustomization(id: agent.id, name: agent.name, character: agent.character)
        }
        if let data = try? JSONEncoder().encode(customs) {
            UserDefaults.standard.set(data, forKey: "agentCustomizations")
        }
    }

    // 커스터마이징 정보 로드 및 적용
    private func applyCustomizations() {
        guard let data = UserDefaults.standard.data(forKey: "agentCustomizations"),
              let customs = try? JSONDecoder().decode([AgentCustomization].self, from: data) else { return }

        for custom in customs {
            if let index = agents.firstIndex(where: { $0.id == custom.id }) {
                if let name = custom.name { agents[index].name = name }
                agents[index].character = custom.character
            }
        }
    }

    // 에이전트 순서 변경 (드래그앤드롭)
    func reorderAgent(from: Int, to: Int) {
        guard from != to,
              from >= 0, from < agents.count,
              to >= 0, to < agents.count else { return }
        let agent = agents.remove(at: from)
        agents.insert(agent, at: to)
        saveCustomizations()
    }

    // 에이전트 활성 상태 업데이트
    func updateAgentActivity(id: String, isActive: Bool, pid: String? = nil) {
        if let index = agents.firstIndex(where: { $0.id == id }) {
            agents[index].isActive = isActive
            agents[index].pid = pid
        }
    }

    // 싱글톤이므로 앱 종료 시 OS가 파일 디스크립터 정리
}

// 에이전트 커스터마이징 저장용 모델
struct AgentCustomization: Codable {
    let id: String
    let name: String?
    let character: RobotCharacter?
}

extension Notification.Name {
    static let projectURLChanged = Notification.Name("projectURLChanged")
    static let agentsDidUpdate = Notification.Name("agentsDidUpdate")
}
