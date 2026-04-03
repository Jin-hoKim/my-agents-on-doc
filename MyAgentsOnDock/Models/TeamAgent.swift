import Foundation

// 팀 에이전트 모델
struct TeamAgent: Identifiable, Codable, Equatable {
    let id: String              // 역할명 (agents.json key)
    let model: String           // opus/sonnet/haiku
    let name: String            // description에서 추출한 이름
    let roleDescription: String // — 뒤의 역할 설명
    let emoji: String           // 역할별 매핑 이모지
    var isActive: Bool          // 현재 실행 중 여부
    var pid: String?            // 프로세스 ID

    init(id: String, model: String, name: String, roleDescription: String, emoji: String, isActive: Bool = false, pid: String? = nil) {
        self.id = id
        self.model = model
        self.name = name
        self.roleDescription = roleDescription
        self.emoji = emoji
        self.isActive = isActive
        self.pid = pid
    }

    // 모델 약어 (뱃지 표시용)
    var modelBadge: String {
        switch model.lowercased() {
        case "opus": return "O"
        case "sonnet": return "S"
        case "haiku": return "H"
        default: return model.prefix(1).uppercased()
        }
    }

    // 모델 색상
    var modelColor: String {
        switch model.lowercased() {
        case "opus": return "purple"
        case "sonnet": return "blue"
        case "haiku": return "green"
        default: return "gray"
        }
    }
}
