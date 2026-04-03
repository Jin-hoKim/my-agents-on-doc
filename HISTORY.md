# 변경 이력

## 2026-04-03

### 초기 구현 — Team 모드 agents.json 기반 동적 팀 캐릭터 구성

Solo 모드(my-agent-on-dock)를 참고하여 Team 모드 별도 프로젝트 신규 생성.

#### 생성된 파일

**프로젝트 기반**
- `Package.swift` — macOS 14.0+, Lottie 의존성
- `MyAgentsOnDock/Info.plist` — LSUIElement=true, 번들 ID: com.jhkim.MyAgentsOnDock
- `MyAgentsOnDock/MyAgentsOnDock.entitlements` — App Sandbox + Security-Scoped Bookmarks

**Models/**
- `TeamAgent.swift` — 팀 에이전트 모델 (id, model, name, roleDescription, emoji, isActive, pid)
- `AgentRole.swift` — 역할별 이모지 매핑 (leader/frontend/backend/database/designer/qa/devops 등)
- `AgentState.swift` — idle/active/error 상태 머신
- `TeamConfiguration.swift` — agents.json 디코딩 구조 + description 파싱 로직

**Services/**
- `AppSettings.swift` — characterSize, isPanelVisible, monitorInterval 설정
- `BookmarkService.swift` — NSOpenPanel + Security-Scoped Bookmark 저장/복원
- `AgentsConfigService.swift` — agents.json 파싱 + FSEvents 감시 (debounce 0.5초)
- `ProcessMonitorService.swift` — Claude CLI 프로세스 감지 (ps aux + 3초 폴링)
- `TeamPanelManager.swift` — 동적 너비 NSPanel (에이전트 수에 따라 1행/2행)

**Views/**
- `AgentCharacterView.swift` — 개별 에이전트 캐릭터 (이모지 + 상태 인디케이터 + 모델 뱃지)
- `TeamDockView.swift` — HStack 다중 캐릭터 배치 (자동 2행 전환)
- `SetupView.swift` — 프로젝트 연결 + agents.json 미리보기 + 형식 가이드
- `MenuBarView.swift` — 팀 상태 요약 + 에이전트 목록
- `SettingsView.swift` — 캐릭터 크기 / 모니터 간격 / 프로젝트 변경

**앱 진입점**
- `AppDelegate.swift` — 서비스 초기화 체인 (bookmark → agents → panel → monitor)
- `MyAgentsOnDockApp.swift` — MenuBarExtra (person.3.fill 아이콘)
- `main.swift` — MyAgentsOnDockApp.main()
