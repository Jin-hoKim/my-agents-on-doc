import Foundation

// 팀 에이전트 데이터 모델
struct TeamAgent: Identifiable, Codable, Equatable {
    let id: String              // 역할명 (agents.json key)
    let model: String           // opus/sonnet/haiku
    let name: String            // description에서 추출한 이름
    let roleDescription: String // — 뒤의 역할 설명
    let emoji: String           // 역할별 매핑 이모지
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
        lhs.isActive == rhs.isActive &&
        lhs.pid == rhs.pid
    }
}
