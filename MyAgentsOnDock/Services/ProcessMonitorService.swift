import Foundation
import Combine

// Claude CLI 프로세스 감지 서비스
// App Sandbox에서 ps aux가 제한될 수 있으므로 sysctl 기반 구현
@MainActor
class ProcessMonitorService: ObservableObject {
    static let shared = ProcessMonitorService()

    private var timer: Timer?
    private var configService: AgentsConfigService { AgentsConfigService.shared }
    private var bookmarkService: BookmarkService { BookmarkService.shared }

    // 모니터링 시작
    func start() {
        stop()
        let interval = AppSettings.shared.monitorInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkProcesses()
            }
        }
        // 즉시 한 번 실행
        checkProcesses()
    }

    // 모니터링 중지
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // 프로세스 감지 실행
    private func checkProcesses() {
        guard !configService.agents.isEmpty,
              let projectPath = bookmarkService.projectURL?.path else {
            configService.deactivateAll()
            return
        }

        let runningProcesses = getClaudeProcesses(projectPath: projectPath)

        // 모든 에이전트 우선 비활성화 후 매칭 업데이트
        for agent in configService.agents {
            let matchedProcess = runningProcesses.first { process in
                process.roles.contains(agent.id)
            }
            configService.updateAgentStatus(
                id: agent.id,
                isActive: matchedProcess != nil,
                pid: matchedProcess.map { String($0.pid) }
            )
        }
    }

    // Claude CLI 프로세스 목록 수집
    private func getClaudeProcesses(projectPath: String) -> [ClaudeProcess] {
        // ps aux를 통해 프로세스 목록 획득 (Sandbox 밖에서 실행 시)
        // Sandbox 환경에서는 제한될 수 있음 → 빈 배열 반환
        let output = runPS()
        guard !output.isEmpty else { return [] }

        var processes: [ClaudeProcess] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            // claude 프로세스 찾기
            guard line.contains("claude") || line.contains("Claude") else { continue }
            guard !line.contains("grep") else { continue }

            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count > 1, let pid = Int(parts[1]) else { continue }

            // 커맨드라인에서 역할 추출
            // 예: ./team/run.sh frontend myproject "task"
            // 또는 claude --role=frontend
            let commandLine = parts.dropFirst(10).joined(separator: " ")
            let roles = extractRoles(from: commandLine, projectPath: projectPath)

            if !roles.isEmpty {
                processes.append(ClaudeProcess(pid: pid, roles: roles, commandLine: commandLine))
            }
        }

        return processes
    }

    // ps aux 실행 (Sandbox 환경 제약 고려)
    private func runPS() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["aux"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            // Sandbox에서 Process() 차단 시 빈 문자열 반환
            return ""
        }
    }

    // 커맨드라인에서 역할명 추출
    private func extractRoles(from commandLine: String, projectPath: String) -> [String] {
        var roles: [String] = []

        // team/run.sh <role> <project> 패턴
        let knownRoles = ["leader", "frontend", "backend", "database", "designer", "qa", "devops"]
        for role in knownRoles {
            if commandLine.contains(role) {
                roles.append(role)
            }
        }

        // --role=<role> 패턴
        if let range = commandLine.range(of: "--role=") {
            let afterRole = commandLine[range.upperBound...]
            let role = afterRole.prefix(while: { !$0.isWhitespace && $0 != "," })
            if !role.isEmpty {
                roles.append(String(role))
            }
        }

        return roles
    }
}

// 감지된 Claude 프로세스 정보
struct ClaudeProcess {
    let pid: Int
    let roles: [String]
    let commandLine: String
}
