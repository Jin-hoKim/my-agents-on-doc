import SwiftUI
import Combine

// 캐릭터 배치 레이아웃
enum LayoutMode: String, CaseIterable {
    case singleRow = "1열"       // 가로 1줄
    case singleColumn = "1횡"    // 세로 1줄
    case doubleRow = "2열"       // 가로 2줄
    case doubleColumn = "2횡"    // 세로 2줄
}

// TTS 음성 종류
enum TTSVoice: String, CaseIterable {
    case yuna = "com.apple.voice.compact.ko-KR.Yuna"
    case rocko = "com.apple.eloquence.ko-KR.Rocko"
    case grandma = "com.apple.eloquence.ko-KR.Grandma"
    case grandpa = "com.apple.eloquence.ko-KR.Grandpa"
    case eddy = "com.apple.eloquence.ko-KR.Eddy"
    case sandy = "com.apple.eloquence.ko-KR.Sandy"
    case reed = "com.apple.eloquence.ko-KR.Reed"
    case flo = "com.apple.eloquence.ko-KR.Flo"
    case shelley = "com.apple.eloquence.ko-KR.Shelley"

    var displayName: String {
        switch self {
        case .yuna:    return "유나 (여성, 기본)"
        case .rocko:   return "Rocko (로봇)"
        case .grandma: return "Grandma (할머니)"
        case .grandpa: return "Grandpa (할아버지)"
        case .eddy:    return "Eddy (남성)"
        case .sandy:   return "Sandy (여성)"
        case .reed:    return "Reed (남성)"
        case .flo:     return "Flo (여성)"
        case .shelley: return "Shelley (여성)"
        }
    }
}

// 앱 설정 관리 (UserDefaults 기반)
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // 캐릭터 크기 설정
    @AppStorage("characterSize") var characterSize: Double = 60.0

    // 패널 표시 여부
    @AppStorage("characterPanelVisible") var isPanelVisible: Bool = true

    // 프로세스 감시 간격 (초)
    @AppStorage("monitorInterval") var monitorInterval: Double = 3.0

    // 마지막 선택 프로젝트 경로 (표시용)
    @AppStorage("lastProjectPath") var lastProjectPath: String = ""

    // 캐릭터 배치 레이아웃
    @AppStorage("layoutMode") var layoutModeRaw: String = LayoutMode.singleRow.rawValue

    var layoutMode: LayoutMode {
        get { LayoutMode(rawValue: layoutModeRaw) ?? .singleRow }
        set { layoutModeRaw = newValue.rawValue }
    }

    // TTS 음성 사용 여부
    @AppStorage("ttsEnabled") var ttsEnabled: Bool = true

    // TTS 음성 종류
    @AppStorage("ttsVoice") var ttsVoiceRaw: String = TTSVoice.yuna.rawValue

    var ttsVoice: TTSVoice {
        get { TTSVoice(rawValue: ttsVoiceRaw) ?? .yuna }
        set { ttsVoiceRaw = newValue.rawValue }
    }

    // 캐릭터 사이즈 범위
    static let minSize: Double = 60.0
    static let maxSize: Double = 300.0
}
