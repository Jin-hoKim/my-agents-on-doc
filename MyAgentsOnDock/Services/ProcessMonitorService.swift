import Foundation
import AppKit

// Claude CLI 프로세스 감지 서비스 (3초 간격 폴링)
@MainActor
class ProcessMonitorService: ObservableObject {
    static let shared = ProcessMonitorService()

    private var timer: Timer?
    private var configService: AgentsConfigService { AgentsConfigService.shared }
    private var bookmarkService: BookmarkService { BookmarkService.shared }

    func startMonitoring() {
        stopMonitoring()
        timer = Timer.scheduledTimer(
            withTimeInterval: AppSettings.shared.monitorInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkProcesses()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // 실행 중인 Claude CLI 프로세스 감지
    private func checkProcesses() {
        guard configService.connectionStatus.isConnected else { return }
        guard let projectURL = bookmarkService.projectURL else { return }

        let runningPids = getClaudeProcesses(projectPath: projectURL.path)

        // 모든 에이전트 상태 초기화 후 감지된 것만 활성화
        for agent in configService.agents {
            let matchResult = runningPids.first { $0.roles.contains(agent.id) }
            configService.updateAgentActivity(
                id: agent.id,
                isActive: matchResult != nil,
                pid: matchResult.map { String($0.pid) }
            )
        }
    }

    // ps aux 실행하여 Claude CLI 프로세스 목록 조회
    private func getClaudeProcesses(projectPath: String) -> [ProcessInfo] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["aux"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return parseProcessOutput(output, projectPath: projectPath)
    }

    // ps aux 출력 파싱하여 Claude 관련 프로세스 추출
    private func parseProcessOutput(_ output: String, projectPath: String) -> [ProcessInfo] {
        var results: [ProcessInfo] = []

        let lines = output.components(separatedBy: "\n").dropFirst() // 헤더 제거
        for line in lines {
            let parts = line.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: true)
            guard parts.count >= 11 else { continue }

            let command = String(parts[10...].joined(separator: " "))

            // claude 또는 claude-code 프로세스 감지
            guard command.contains("claude") else { continue }

            guard let pid = Int(parts[1]) else { continue }

            // 역할 추출: --role=frontend 또는 ROLE=frontend 패턴
            var roles: [String] = []
            if let roleMatch = command.range(of: #"--role[=\s](\w+)"#, options: .regularExpression) {
                let roleStr = String(command[roleMatch])
                    .replacingOccurrences(of: "--role=", with: "")
                    .replacingOccurrences(of: "--role ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                roles.append(roleStr)
            }

            // 역할 미매핑 시 projectPath 기반으로 모든 역할에 활성 표시
            results.append(ProcessInfo(pid: pid, roles: roles, command: command))
        }

        return results
    }
}

// 프로세스 정보 구조체
struct ProcessInfo {
    let pid: Int
    let roles: [String]
    let command: String
}
