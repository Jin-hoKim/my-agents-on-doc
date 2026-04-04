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

        // 메인 스레드 블로킹 방지: 백그라운드에서 ps + lsof 실행
        let projectPath = projectURL.path
        let agentModels = configService.agents.map { ($0.id, $0.model) }
        Task.detached { [weak self] in
            let runningPids = Self.getClaudeProcesses(projectPath: projectPath, agentModels: agentModels)
            await MainActor.run {
                guard let self else { return }
                for agent in self.configService.agents {
                    let matchResult = runningPids.first { $0.roles.contains(agent.id) }
                    self.configService.updateAgentActivity(
                        id: agent.id,
                        isActive: matchResult != nil,
                        pid: matchResult.map { String($0.pid) }
                    )
                }
            }
        }
    }

    // ps aux + lsof CWD로 Claude CLI 프로세스 목록 조회 (백그라운드 스레드에서 실행)
    nonisolated private static func getClaudeProcesses(projectPath: String, agentModels: [(id: String, model: String)]) -> [ClaudeProcessInfo] {
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

        return parseProcessOutput(output, projectPath: projectPath, agentModels: agentModels)
    }

    // 특정 PID의 작업 디렉토리(CWD) 조회
    nonisolated private static func getProcessCwd(pid: Int) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-a", "-d", "cwd", "-p", String(pid), "-Fn"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        // lsof -Fn 출력에서 "n/path" 행 찾기
        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("n/") {
                return String(line.dropFirst(1))
            }
        }
        return nil
    }

    // ps aux 출력 파싱하여 Claude 관련 프로세스 추출
    nonisolated private static func parseProcessOutput(_ output: String, projectPath: String, agentModels: [(id: String, model: String)]) -> [ClaudeProcessInfo] {
        var results: [ClaudeProcessInfo] = []

        let lines = output.components(separatedBy: "\n").dropFirst() // 헤더 제거
        for line in lines {
            let parts = line.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: true)
            guard parts.count >= 11 else { continue }

            let command = String(parts[10...].joined(separator: " "))

            // claude CLI 메인 프로세스만 감지 (하위 프로세스 제외)
            let isClaudeProcess = command.contains("/claude ") ||
                                  command.contains("/claude\t") ||
                                  command.hasPrefix("claude ") ||
                                  command.contains("bin/claude")
            guard isClaudeProcess else { continue }
            // 플러그인, 훅, 보조 프로세스 제외
            guard !command.contains("claude-hook") &&
                  !command.contains("plugins/") &&
                  !command.contains("chrome-native") else { continue }

            guard let pid = Int(parts[1]) else { continue }

            // 1단계: 명령줄에서 역할 추출
            var roles: [String] = []

            // --agent leader (멀티 에이전트 모드)
            if let agentMatch = command.range(of: #"--agent[=\s]+(\w+)"#, options: .regularExpression) {
                let agentStr = String(command[agentMatch])
                    .replacingOccurrences(of: "--agent=", with: "")
                    .replacingOccurrences(of: "--agent ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                roles.append(agentStr)
            }

            // --role=frontend 패턴
            if let roleMatch = command.range(of: #"--role[=\s]+(\w+)"#, options: .regularExpression) {
                let roleStr = String(command[roleMatch])
                    .replacingOccurrences(of: "--role=", with: "")
                    .replacingOccurrences(of: "--role ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !roles.contains(roleStr) {
                    roles.append(roleStr)
                }
            }

            // 2단계: 역할 미매핑 시 CWD 기반으로 프로젝트 소속 확인
            if roles.isEmpty {
                if let cwd = getProcessCwd(pid: pid) {
                    // CWD가 프로젝트 경로 또는 하위 디렉토리인 경우
                    if cwd == projectPath || cwd.hasPrefix(projectPath + "/") {
                        // --model 플래그로 역할 추론
                        let inferredRole = inferRoleFromCommand(command, agentModels: agentModels)
                        if let role = inferredRole {
                            roles.append(role)
                        } else {
                            // 역할 추론 불가 시 leader(기본 오케스트레이터)로 매핑
                            roles.append("leader")
                        }
                    }
                }
            }

            if !roles.isEmpty {
                results.append(ClaudeProcessInfo(pid: pid, roles: roles, command: command))
            }
        }

        return results
    }

    // 명령줄에서 모델 정보로 역할 추론 (명시적 플래그만 사용)
    nonisolated private static func inferRoleFromCommand(_ command: String, agentModels: [(id: String, model: String)]) -> String? {
        // --model 플래그 추출
        guard let modelMatch = command.range(of: #"--model[=\s]+(\S+)"#, options: .regularExpression) else {
            return nil
        }
        let modelStr = String(command[modelMatch])
            .replacingOccurrences(of: "--model=", with: "")
            .replacingOccurrences(of: "--model ", with: "")
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        // 해당 모델을 사용하는 에이전트가 하나뿐이면 확정
        let matchingAgents = agentModels.filter { $0.model.lowercased() == modelStr }
        if matchingAgents.count == 1 {
            return matchingAgents[0].id
        }

        // opus 모델은 보통 leader
        if modelStr.contains("opus") {
            return "leader"
        }

        return nil
    }
}

// 프로세스 정보 구조체
struct ClaudeProcessInfo {
    let pid: Int
    let roles: [String]
    let command: String
}
