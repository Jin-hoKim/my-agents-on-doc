import Foundation

// Individual agent definition from agents.json
struct AgentDefinition: Codable {
    let model: String
    let description: String
    let prompt: String?
}

// Full agents.json structure (key → AgentDefinition)
typealias TeamConfiguration = [String: AgentDefinition]

// agents.json parsing result status
enum ConnectionStatus: Equatable {
    case notConnected           // No project selected
    case connected              // agents.json parsed successfully
    case fileNotFound           // agents.json not found
    case parseError(String)     // JSON parse error

    var displayText: String {
        switch self {
        case .notConnected:         return "Please select a project folder"
        case .connected:            return "Team detected"
        case .fileNotFound:         return "agents.json file not found"
        case .parseError(let msg):  return "Parse error: \(msg)"
        }
    }

    var statusEmoji: String {
        switch self {
        case .notConnected:  return "⚪"
        case .connected:     return "✅"
        case .fileNotFound:  return "❌"
        case .parseError:    return "⚠️"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
