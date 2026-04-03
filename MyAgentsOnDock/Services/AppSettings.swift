import SwiftUI
import Combine

// 앱 설정 관리 (UserDefaults 기반)
@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // 캐릭터 크기
    @AppStorage("characterSize") var characterSize: Double = 60.0

    // 패널 표시 여부
    @AppStorage("characterPanelVisible") var isPanelVisible: Bool = true

    // 프로세스 감시 간격 (초)
    @AppStorage("monitorInterval") var monitorInterval: Double = 3.0

    // 캐릭터 크기 범위
    static let minSize: Double = 40.0
    static let maxSize: Double = 100.0
    static let minInterval: Double = 1.0
    static let maxInterval: Double = 10.0
}
