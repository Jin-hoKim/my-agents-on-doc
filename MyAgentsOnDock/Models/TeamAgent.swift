import Foundation

// 9 character types
enum RobotCharacter: String, Codable, CaseIterable {
    case black = "Black robot"
    case blue = "Blue robot"
    case green = "Green robot"
    case marine = "Marine robot"
    case pink = "Pink robot"
    case purple = "Purple robot"
    case red = "Red robot"
    case white = "White robot"
    case yellow = "Yellow robot"

    // Lottie JSON file name
    var fileName: String { rawValue }

    // Display name
    var displayName: String {
        switch self {
        case .black:  return "Black"
        case .blue:   return "Blue"
        case .green:  return "Green"
        case .marine: return "Marine"
        case .pink:   return "Pink"
        case .purple: return "Purple"
        case .red:    return "Red"
        case .white:  return "White"
        case .yellow: return "Yellow"
        }
    }

    // Representative color
    var color: String {
        switch self {
        case .black:  return "#333333"
        case .blue:   return "#4A90D9"
        case .green:  return "#4CAF50"
        case .marine: return "#00BCD4"
        case .pink:   return "#E91E63"
        case .purple: return "#9C27B0"
        case .red:    return "#F44336"
        case .white:  return "#E0E0E0"
        case .yellow: return "#FFC107"
        }
    }
}

// Team agent data model
struct TeamAgent: Identifiable, Codable, Equatable {
    let id: String              // Role name (agents.json key)
    let model: String           // opus/sonnet/haiku
    var name: String            // User-defined name
    let roleDescription: String // Role description
    let emoji: String           // Role-mapped emoji
    var character: RobotCharacter? // Selected character image
    var isActive: Bool = false  // Currently running
    var pid: String? = nil      // Process ID

    // Model abbreviation (for badge)
    var modelBadge: String {
        switch model.lowercased() {
        case "opus":   return "OP"
        case "sonnet": return "SN"
        case "haiku":  return "HK"
        default:       return String(model.prefix(2)).uppercased()
        }
    }

    // Model display name
    var modelDisplayName: String {
        switch model.lowercased() {
        case "opus":   return "Claude Opus"
        case "sonnet": return "Claude Sonnet"
        case "haiku":  return "Claude Haiku"
        default:       return "Claude \(model.capitalized)"
        }
    }

    static func == (lhs: TeamAgent, rhs: TeamAgent) -> Bool {
        lhs.id == rhs.id &&
        lhs.model == rhs.model &&
        lhs.name == rhs.name &&
        lhs.roleDescription == rhs.roleDescription &&
        lhs.emoji == rhs.emoji &&
        lhs.character == rhs.character &&
        lhs.isActive == rhs.isActive &&
        lhs.pid == rhs.pid
    }
}
