# HISTORY.md — My Agents on Dock

## 2026-04-03 (버그 수정 #2)

### 메뉴바 아이콘 클릭 시 메뉴창 안 열리는 버그 수정

- **원인**: `MenuBarExtra(.window)` + `NSApp.setActivationPolicy(.accessory)` 조합이 SPM 빌드에서 충돌
  - SwiftUI `MenuBarExtra` 의 `.window` 스타일은 앱 활성화(activate)를 필요로 하는데, `.accessory` 정책으로 인해 윈도우 표시 차단
  - SPM 빌드에서 Info.plist가 앱 번들 루트에 올바르게 임베딩되지 않아 `LSUIElement = YES` 미적용

- **수정**: `NSStatusItem + NSPopover` 직접 구현으로 교체 (AppKit 네이티브 방식)
  - **main.swift** 생성: SwiftUI `@main` 대신 `NSApplication.shared.delegate = AppDelegate()` 직접 실행
  - **MyAgentsOnDockApp.swift** 수정: `@main` + `MenuBarExtra` 제거 (파일은 주석으로 대체)
  - **AppDelegate.swift** 수정:
    - `setupStatusItem()` 추가: `NSStatusBar.system.statusItem` + `NSPopover` 생성
    - `togglePopover(_:)` 추가: 클릭 시 팝오버 토글 (`popover.show` / `performClose`)
    - 팝오버 내 `NSHostingController(rootView: MenuBarView())` 로 SwiftUI 뷰 임베딩
    - `.transient` behavior로 팝오버 외부 클릭 시 자동 닫힘
    - 팝오버 표시 시 `NSApp.activate(ignoringOtherApps: true)` 호출

## 2026-04-03 (버그 수정)

### SetupView 버튼 반응 없음 수정

- **Views/SetupView.swift** 수정: `@Environment(\.dismiss)` → `NSApp.keyWindow?.close()` 직접 호출로 변경
  - 원인: SetupView가 NSWindow + NSHostingView로 임베딩되어 SwiftUI의 dismiss 환경값이 연결되지 않음
  - 수정: `closeWindow()` 헬퍼 메서드 추가, 닫기/팀연결 버튼에 적용
  - 연결 해제 버튼은 창을 닫지 않으므로 기존 로직 유지 (clearBookmark + reload)

### Phase 1: 프로젝트 기반 구축 및 모델 정의

- **Package.swift** 생성: macOS 14.0+, Lottie 의존성 설정
- **Models/TeamAgent.swift** 생성: 팀 에이전트 데이터 모델 (id, model, name, roleDescription, emoji, isActive, pid)
- **Models/AgentRole.swift** 생성: 역할별 이모지 매핑 (leader→📋, frontend→⌨️, backend→💻 등)
- **Models/AgentState.swift** 생성: idle/active/error 상태 enum
- **Models/TeamConfiguration.swift** 생성: agents.json 파싱 구조 (AgentDefinition, ConnectionStatus)

### Phase 2: 핵심 서비스 구현

- **Services/AppSettings.swift** 생성: UserDefaults 기반 설정 (characterSize, isPanelVisible, monitorInterval)
- **Services/BookmarkService.swift** 생성: Security-Scoped Bookmarks로 프로젝트 폴더 접근 권한 관리
  - NSOpenPanel 폴더 선택
  - 북마크 영구 저장/복원
  - startAccessingSecurityScopedResource() 관리
- **Services/AgentsConfigService.swift** 생성: agents.json 파싱 + FSEvents 감시
  - "이름 — 설명" 파싱 (em dash, en dash, " - " 구분자 지원)
  - DispatchSource.makeFileSystemObjectSource로 파일 변경 감지
  - debounce 0.5초 적용
  - 역할 순서: leader → frontend → backend → database → designer → qa → devops → 기타
- **Services/ProcessMonitorService.swift** 생성: Claude CLI 프로세스 감지
  - 3초 간격 폴링 (설정 변경 가능)
  - ps aux 실행하여 claude 프로세스 감지
  - --role 인자로 역할 매칭
- **Services/TeamPanelManager.swift** 생성: 멀티 캐릭터 NSPanel 관리
  - agents 수에 따른 동적 패널 너비 계산
  - Dock 위치 감지 (하단/왼쪽/오른쪽)
  - 화면 변경 자동 위치 조정

### Phase 3: 캐릭터 뷰 구현

- **Views/AgentCharacterView.swift** 생성: 개별 에이전트 캐릭터 뷰
  - 이모지 + 원형 배경 그래디언트
  - 활성 시 초록색 계열, 대기 시 회색 계열
  - 활성 상태 인디케이터 (초록 점)
  - 모델 뱃지 (OP/SN/HK, 색상 구분)
  - 이름 라벨 + 상태 텍스트
  - active 시 스케일 애니메이션 (1.0→1.1)
- **Views/TeamDockView.swift** 생성: 멀티 캐릭터 Dock 뷰
  - HStack + ScrollView로 에이전트 나열
  - 빈 상태 플레이스홀더 표시

### Phase 4: 설정 UI 구현

- **Views/SetupView.swift** 생성: 초기 설정 / 프로젝트 연결 뷰
  - 프로젝트 폴더 선택 (NSOpenPanel)
  - agents.json 상태 표시 (✅/❌/⚠️)
  - 팀 구성 미리보기 테이블 (이모지|역할명|이름|모델|설명)
  - agents.json 형식 가이드 (오류 시)
  - 팀 연결/해제 버튼
- **Views/SettingsView.swift** 생성: 설정 뷰
  - 팀 프로젝트 연결 상태
  - 캐릭터 크기 슬라이더
  - 프로세스 감시 간격 조정
  - 팀 구성원 목록 + 활성 상태
- **Views/MenuBarView.swift** 생성: 메뉴바 드롭다운
  - 활성 에이전트 수/전체 수 표시
  - 에이전트별 상태 리스트 (이모지, 이름, 모델 뱃지, 활성 표시)
  - 팀 프로젝트 연결 / 설정 / 종료

### Phase 5: 앱 통합

- **AppDelegate.swift** 생성: 앱 생명주기 관리
  - BookmarkService → AgentsConfigService → ProcessMonitorService 초기화 체인
  - 저장된 프로젝트 없으면 SetupView 자동 표시
  - openSetup / openSettings 알림 처리
  - 앱 종료 시 리소스 정리
- **MyAgentsOnDockApp.swift** 생성: 메인 앱 구조체
  - MenuBarExtra (person.3.fill 아이콘)
  - NSApplicationDelegateAdaptor로 AppDelegate 연결
- **Info.plist** 생성: 번들 설정 (LSUIElement=true, com.jhkim.MyAgentsOnDock)
- **MyAgentsOnDock.entitlements** 생성: App Sandbox 설정
  - app-sandbox, network.client, files.user-selected.read-only, files.bookmarks.app-scope
