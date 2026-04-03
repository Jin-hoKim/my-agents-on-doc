import SwiftUI
import Combine

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

    // 캐릭터 사이즈 범위
    static let minSize: Double = 40.0
    static let maxSize: Double = 100.0
}
