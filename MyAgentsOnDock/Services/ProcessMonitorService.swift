import Foundation
import AppKit

// Claude CLI process detection service (polling every 3 seconds)
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

    // Detect running Claude CLI processes
    private func checkProcesses() {
        guard configService.connectionStatus.isConnected else {
            print("[ProcessMonitor] Skip: not connected (\(configService.connectionStatus))")
            return
        }
        guard let projectURL = bookmarkService.projectURL else {
            print("[ProcessMonitor] Skip: no project URL")
            return
        }

        // Prevent blocking main thread: run ps + lsof in background
        let projectPath = projectURL.path
        let agentModels = configService.agents.map { ($0.id, $0.model) }
        Task.detached { [weak self] in
            let runningPids = Self.getClaudeProcesses(projectPath: projectPath, agentModels: agentModels)
            if !runningPids.isEmpty {
                print("[ProcessMonitor] Detected \(runningPids.count) process(es): \(runningPids.map { "PID=\($0.pid) roles=\($0.roles)" })")
            }
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

    // Get Claude CLI process list via pgrep + ps (runs on background thread)
    nonisolated private static func getClaudeProcesses(projectPath: String, agentModels: [(id: String, model: String)]) -> [ClaudeProcessInfo] {
        // Step 1: Get claude process PIDs via pgrep
        let pgrepTask = Process()
        pgrepTask.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        pgrepTask.arguments = ["-f", "claude"]

        let pgrepPipe = Pipe()
        pgrepTask.standardOutput = pgrepPipe
        pgrepTask.standardError = Pipe()

        do {
            try pgrepTask.run()
            pgrepTask.waitUntilExit()
        } catch {
            return []
        }

        let pgrepData = pgrepPipe.fileHandleForReading.readDataToEndOfFile()
        guard let pgrepOutput = String(data: pgrepData, encoding: .utf8) else { return [] }

        let pids = pgrepOutput.components(separatedBy: "\n")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        if pids.isEmpty { return [] }

        // Step 2: For each PID, get command via ps -p PID -o command=
        var results: [ClaudeProcessInfo] = []

        for pid in pids {
            let psTask = Process()
            psTask.executableURL = URL(fileURLWithPath: "/bin/ps")
            psTask.arguments = ["-p", String(pid), "-o", "command="]

            let psPipe = Pipe()
            psTask.standardOutput = psPipe
            psTask.standardError = Pipe()

            do {
                try psTask.run()
                psTask.waitUntilExit()
            } catch {
                continue
            }

            let psData = psPipe.fileHandleForReading.readDataToEndOfFile()
            guard let command = String(data: psData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !command.isEmpty else { continue }

            // Only claude CLI main process (exclude plugins, hooks)
            let isClaudeMain = command.contains("/claude ") ||
                               command.contains("/claude\t") ||
                               command.hasPrefix("claude ") ||
                               command.contains("bin/claude") ||
                               command.contains("/claude -") ||
                               command.hasSuffix("/claude")
            guard isClaudeMain else { continue }
            guard !command.contains("claude-hook") &&
                  !command.contains("plugins/") &&
                  !command.contains("chrome-native") &&
                  !command.contains("cmux") else { continue }

            // Extract roles
            var roles: [String] = []

            // --agent or --role flags
            if let agentMatch = command.range(of: #"--agent[=\s]+(\w+)"#, options: .regularExpression) {
                let agentStr = String(command[agentMatch])
                    .replacingOccurrences(of: "--agent=", with: "")
                    .replacingOccurrences(of: "--agent ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                roles.append(agentStr)
            }
            if let roleMatch = command.range(of: #"--role[=\s]+(\w+)"#, options: .regularExpression) {
                let roleStr = String(command[roleMatch])
                    .replacingOccurrences(of: "--role=", with: "")
                    .replacingOccurrences(of: "--role ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !roles.contains(roleStr) { roles.append(roleStr) }
            }

            // CWD-based matching
            if roles.isEmpty {
                if let cwd = getProcessCwd(pid: pid) {
                    if cwd == projectPath || cwd.hasPrefix(projectPath + "/") {
                        let inferredRole = inferRoleFromCommand(command, agentModels: agentModels)
                        roles.append(inferredRole ?? "leader")
                    }
                }
            }

            if !roles.isEmpty {
                results.append(ClaudeProcessInfo(pid: pid, roles: roles, command: command))
            }
        }

        return results
    }

    // Get the working directory (CWD) for a specific PID
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

        // Find "n/path" line in lsof -Fn output
        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("n/") {
                return String(line.dropFirst(1))
            }
        }
        return nil
    }

    // Infer role from command line model info (explicit flags only)
    nonisolated private static func inferRoleFromCommand(_ command: String, agentModels: [(id: String, model: String)]) -> String? {
        // Extract --model flag
        guard let modelMatch = command.range(of: #"--model[=\s]+(\S+)"#, options: .regularExpression) else {
            return nil
        }
        let modelStr = String(command[modelMatch])
            .replacingOccurrences(of: "--model=", with: "")
            .replacingOccurrences(of: "--model ", with: "")
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        // If only one agent uses this model, it's a definitive match
        let matchingAgents = agentModels.filter { $0.model.lowercased() == modelStr }
        if matchingAgents.count == 1 {
            return matchingAgents[0].id
        }

        // opus model is usually leader
        if modelStr.contains("opus") {
            return "leader"
        }

        return nil
    }
}

// Process information struct
struct ClaudeProcessInfo {
    let pid: Int
    let roles: [String]
    let command: String
}
