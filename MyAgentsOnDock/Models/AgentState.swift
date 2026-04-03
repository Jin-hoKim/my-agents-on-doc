import Foundation

// 에이전트 현재 상태
enum AgentState: Equatable {
    case idle           // 대기 중
    case active         // 실행 중 (프로세스 감지됨)
    case error(String)  // 에러 발생

    var isWorking: Bool {
        if case .active = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .idle: return "대기 중"
        case .active: return "작업 중"
        case .error(let msg): return "오류: \(msg)"
        }
    }
}
