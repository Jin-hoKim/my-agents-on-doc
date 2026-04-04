import SwiftUI
import Combine

// Character layout mode
enum LayoutMode: String, CaseIterable {
    case singleRow = "1 Row"
    case singleColumn = "1 Col"
    case doubleRow = "2 Rows"
    case doubleColumn = "2 Cols"
}

// TTS voice type
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
        case .yuna:    return "Yuna (Female, Default)"
        case .rocko:   return "Rocko (Robot)"
        case .grandma: return "Grandma"
        case .grandpa: return "Grandpa"
        case .eddy:    return "Eddy (Male)"
        case .sandy:   return "Sandy (Female)"
        case .reed:    return "Reed (Male)"
        case .flo:     return "Flo (Female)"
        case .shelley: return "Shelley (Female)"
        }
    }
}

// App settings (UserDefaults-based)
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("characterSize") var characterSize: Double = 60.0
    @AppStorage("characterPanelVisible") var isPanelVisible: Bool = true
    @AppStorage("monitorInterval") var monitorInterval: Double = 3.0
    @AppStorage("lastProjectPath") var lastProjectPath: String = ""

    @AppStorage("layoutMode") var layoutModeRaw: String = LayoutMode.singleRow.rawValue
    var layoutMode: LayoutMode {
        get { LayoutMode(rawValue: layoutModeRaw) ?? .singleRow }
        set { layoutModeRaw = newValue.rawValue }
    }

    @AppStorage("ttsEnabled") var ttsEnabled: Bool = true
    @AppStorage("ttsVoice") var ttsVoiceRaw: String = TTSVoice.yuna.rawValue
    var ttsVoice: TTSVoice {
        get { TTSVoice(rawValue: ttsVoiceRaw) ?? .yuna }
        set { ttsVoiceRaw = newValue.rawValue }
    }

    static let minSize: Double = 60.0
    static let maxSize: Double = 300.0
}
