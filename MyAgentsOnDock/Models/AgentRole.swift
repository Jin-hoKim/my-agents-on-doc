import Foundation

// 역할별 이모지 매핑
enum AgentRole {
    static let emojiMap: [String: String] = [
        "leader":   "📋",
        "frontend": "⌨️",
        "backend":  "💻",
        "database": "🗄️",
        "designer": "🎨",
        "qa":       "🔍",
        "devops":   "🔧"
    ]
    static let defaultEmoji = "🤖"

    static func emoji(for role: String) -> String {
        emojiMap[role.lowercased()] ?? defaultEmoji
    }
}
