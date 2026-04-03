import Foundation

// agents.json 개별 에이전트 정의
struct AgentDefinition: Codable {
    let model: String
    let description: String
    let prompt: String?

    // description에서 이름과 역할 설명 파싱
    // 형식: "이름 — 설명" 또는 "이름 - 설명"
    func parseName() -> String {
        let separators = [" — ", " - ", "—", "—"]
        for sep in separators {
            if let range = description.range(of: sep) {
                let name = String(description[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }
        // 구분자 없으면 전체를 이름으로 사용
        return description.trimmingCharacters(in: .whitespaces)
    }

    func parseRoleDescription() -> String {
        let separators = [" — ", " - ", "—", "—"]
        for sep in separators {
            if let range = description.range(of: sep) {
                let desc = String(description[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !desc.isEmpty { return desc }
            }
        }
        return ""
    }
}

// agents.json 전체 구조 (역할명 → 정의 딕셔너리)
typealias TeamConfiguration = [String: AgentDefinition]
