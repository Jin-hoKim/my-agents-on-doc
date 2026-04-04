import Foundation

// Current agent state
enum AgentState: Equatable {
    case idle           // Waiting
    case active         // Running (Claude CLI process detected)
    case error(String)  // Error

    var isWorking: Bool {
        if case .active = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .idle:           return "Idle"
        case .active:         return "Working"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}
