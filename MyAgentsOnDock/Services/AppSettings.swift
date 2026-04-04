import SwiftUI
import Combine

// 캐릭터 배치 레이아웃
// 캐릭터 배치 레이아웃
enum LayoutMode: String, CaseIterable {
    case singleRow = "1열"       // 가로 1줄
    case singleColumn = "1횡"    // 세로 1줄
    case doubleRow = "2열"       // 가로 2줄
    case doubleColumn = "2횡"    // 세로 2줄
    case freeform = "자유 배치"   // 개별 드래그 이동
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

    // 캐릭터 사이즈 범위
    static let minSize: Double = 60.0
    static let maxSize: Double = 300.0
}
