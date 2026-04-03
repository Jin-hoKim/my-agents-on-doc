import Foundation

// agents.json에서 개별 에이전트 정의
struct AgentDefinition: Codable {
    let model: String
    let description: String
    let prompt: String?
}

// agents.json 전체 구조 (key → AgentDefinition)
typealias TeamConfiguration = [String: AgentDefinition]

// agents.json 파싱 결과 상태
enum ConnectionStatus: Equatable {
    case notConnected           // 프로젝트 미선택
    case connected              // agents.json 정상 파싱
    case fileNotFound           // agents.json 없음
    case parseError(String)     // JSON 파싱 오류

    var displayText: String {
        switch self {
        case .notConnected:         return "프로젝트 폴더를 선택해 주세요"
        case .connected:            return "팀 감지됨"
        case .fileNotFound:         return "agents.json 파일이 없습니다"
        case .parseError(let msg):  return "파싱 오류: \(msg)"
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
