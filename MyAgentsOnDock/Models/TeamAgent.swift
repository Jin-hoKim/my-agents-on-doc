import Foundation

// 9종 캐릭터 타입
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

    // Lottie JSON 파일명
    var fileName: String { rawValue }

    // 표시명
    var displayName: String {
        switch self {
        case .black:  return "블랙"
        case .blue:   return "블루"
        case .green:  return "그린"
        case .marine: return "마린"
        case .pink:   return "핑크"
        case .purple: return "퍼플"
        case .red:    return "레드"
        case .white:  return "화이트"
        case .yellow: return "옐로"
        }
    }

    // 대표 색상
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

// 팀 에이전트 데이터 모델
struct TeamAgent: Identifiable, Codable, Equatable {
    let id: String              // 역할명 (agents.json key)
    let model: String           // opus/sonnet/haiku
    var name: String            // 사용자 지정 이름
    let roleDescription: String // 역할 설명
    let emoji: String           // 역할별 매핑 이모지
    var character: RobotCharacter? // 선택된 캐릭터 이미지
    var isActive: Bool = false  // 현재 실행 중 여부
    var pid: String? = nil      // 프로세스 ID

    // 모델 약어 (뱃지용)
    var modelBadge: String {
        switch model.lowercased() {
        case "opus":   return "OP"
        case "sonnet": return "SN"
        case "haiku":  return "HK"
        default:       return String(model.prefix(2)).uppercased()
        }
    }

    // 모델 표시명
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
