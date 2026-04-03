import Foundation
import Combine

// agents.json 연결 상태
enum ConnectionStatus: Equatable {
    case notConnected           // 프로젝트 미선택
    case fileNotFound           // agents.json 없음
    case connected              // 정상 연결
    case error(String)          // 파싱 오류

    var displayText: String {
        switch self {
        case .notConnected: return "프로젝트 미선택"
        case .fileNotFound: return "agents.json 없음"
        case .connected: return "연결됨"
        case .error(let msg): return "오류: \(msg)"
        }
    }

    var icon: String {
        switch self {
        case .notConnected: return "circle"
        case .fileNotFound: return "xmark.circle"
        case .connected: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// agents.json 파싱 + FSEvents 파일 감시 서비스
@MainActor
class AgentsConfigService: ObservableObject {
    static let shared = AgentsConfigService()

    @Published var agents: [TeamAgent] = []
    @Published var connectionStatus: ConnectionStatus = .notConnected

    private var bookmarkService: BookmarkService { BookmarkService.shared }
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var debounceTask: Task<Void, Never>?

    // agents.json 로드 및 파싱
    func loadAgents() {
        guard let configURL = bookmarkService.agentsConfigURL else {
            connectionStatus = .notConnected
            agents = []
            return
        }

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            connectionStatus = .fileNotFound
            agents = []
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(TeamConfiguration.self, from: data)
            agents = buildAgents(from: config)
            connectionStatus = .connected
            startWatching(url: configURL)
        } catch {
            connectionStatus = .error(error.localizedDescription)
            agents = []
        }
    }

    // TeamConfiguration → [TeamAgent] 변환
    private func buildAgents(from config: TeamConfiguration) -> [TeamAgent] {
        // 역할 순서: leader 우선, 나머지 알파벳 순
        let sortedKeys = config.keys.sorted { a, b in
            if a == "leader" { return true }
            if b == "leader" { return false }
            return a < b
        }

        return sortedKeys.compactMap { key in
            guard let def = config[key] else { return nil }
            return TeamAgent(
                id: key,
                model: def.model,
                name: def.parseName(),
                roleDescription: def.parseRoleDescription(),
                emoji: AgentRole.emoji(for: key)
            )
        }
    }

    // FSEvents로 agents.json 변경 감시
    private func startWatching(url: URL) {
        stopWatching()

        let fd = open(url.path, O_EVTONLY)
        guard fd != -1 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            self?.debounceReload()
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileWatchSource = source
    }

    // debounce 0.5초 후 리로드
    private func debounceReload() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !Task.isCancelled {
                loadAgents()
            }
        }
    }

    func stopWatching() {
        fileWatchSource?.cancel()
        fileWatchSource = nil
        debounceTask?.cancel()
    }

    // 특정 에이전트 활성 상태 업데이트
    func updateAgentStatus(id: String, isActive: Bool, pid: String?) {
        if let index = agents.firstIndex(where: { $0.id == id }) {
            agents[index].isActive = isActive
            agents[index].pid = pid
        }
    }

    // 모든 에이전트 비활성화
    func deactivateAll() {
        for index in agents.indices {
            agents[index].isActive = false
            agents[index].pid = nil
        }
    }
}
