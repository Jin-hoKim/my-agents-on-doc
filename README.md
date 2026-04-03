# My Agents on Dock

Claude Code 팀(agents.json)을 자동 감지하여 Dock 위에 여러 에이전트 캐릭터를 동적으로 표시하는 macOS 메뉴바 앱.

## 기능

- **자동 팀 감지**: `team/agents.json` 파일을 읽어 에이전트 캐릭터 자동 생성
- **동적 배치**: 에이전트 수에 따라 패널 너비 자동 조정 (1행/2행)
- **역할별 이모지**: leader(📋), frontend(⌨️), backend(💻), designer(🎨), qa(🔍), devops(🔧) 등
- **실시간 상태**: Claude CLI 프로세스 감지로 작업 중 에이전트 하이라이트
- **FSEvents 감시**: agents.json 변경 시 자동 리로드

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Xcode 15.0 이상 (빌드 시)

## 설치 및 실행

```bash
cd my-agents-on-dock
swift build
.build/debug/MyAgentsOnDock
```

## agents.json 형식

```json
{
  "leader": {
    "model": "opus",
    "description": "PM 재혁 — 요구사항 분석, 팀원 배정",
    "prompt": "당신은 PM입니다..."
  },
  "frontend": {
    "model": "sonnet",
    "description": "개발자 민지 — Vue 3 전문",
    "prompt": "..."
  }
}
```

## 역할별 이모지 매핑

| 역할 | 이모지 | 역할 | 이모지 |
|------|--------|------|--------|
| leader | 📋 | frontend | ⌨️ |
| backend | 💻 | database | 🗄️ |
| designer | 🎨 | qa | 🔍 |
| devops | 🔧 | 기타 | 🤖 |

## 프로젝트 구조

```
MyAgentsOnDock/
├── Package.swift
└── MyAgentsOnDock/
    ├── main.swift
    ├── MyAgentsOnDockApp.swift
    ├── AppDelegate.swift
    ├── Info.plist
    ├── MyAgentsOnDock.entitlements
    ├── Models/
    │   ├── TeamAgent.swift
    │   ├── AgentRole.swift
    │   ├── AgentState.swift
    │   └── TeamConfiguration.swift
    ├── Services/
    │   ├── AppSettings.swift
    │   ├── BookmarkService.swift
    │   ├── AgentsConfigService.swift
    │   ├── ProcessMonitorService.swift
    │   └── TeamPanelManager.swift
    └── Views/
        ├── AgentCharacterView.swift
        ├── TeamDockView.swift
        ├── SetupView.swift
        ├── MenuBarView.swift
        └── SettingsView.swift
```

## Solo 모드와의 차이점

| 항목 | Solo 모드 | Team 모드 |
|------|-----------|-----------|
| 에이전트 수 | 1개 (고정) | N개 (agents.json 기반) |
| 캐릭터 | 사용자 선택 이모지 | 역할별 자동 매핑 |
| 상태 감지 | API 호출 기반 | 프로세스 감지 기반 |
| 설정 | API 키 필요 | 프로젝트 폴더 선택 |
