# My Agents on Dock — 기획 및 구현 계획

## 프로젝트 개요

Claude Code 팀(agents.json)을 자동 감지하여 Dock 위에 여러 에이전트 캐릭터를 동적으로 표시하는 macOS 메뉴바 앱.

## 기술 스택

- Swift 5.9+ / SwiftUI / AppKit (NSPanel)
- Lottie (애니메이션, 향후 확장)
- 최소 지원: macOS 14.0 (Sonoma)

## 구현 단계

### Phase 1: 프로젝트 기반 + 모델 ✅
- Package.swift
- Models: TeamAgent, AgentRole, AgentState, TeamConfiguration

### Phase 2: 핵심 서비스 ✅
- BookmarkService: Security-Scoped Bookmarks
- AgentsConfigService: agents.json 파싱 + FSEvents 감시
- ProcessMonitorService: Claude CLI 프로세스 감지 (3초 폴링)
- AppSettings: 사용자 설정

### Phase 3: 멀티 캐릭터 패널 ✅
- TeamPanelManager: 동적 너비 NSPanel
- TeamDockView: HStack 다중 캐릭터
- AgentCharacterView: 이모지 + 상태 인디케이터 + 모델 뱃지

### Phase 4: 설정 UI ✅
- SetupView: 프로젝트 연결 + 미리보기
- SettingsView: 캐릭터 크기, 모니터 간격, 프로젝트 변경
- MenuBarView: 팀 상태 요약

### Phase 5: 앱 통합 ✅
- AppDelegate: 서비스 초기화 체인
- MyAgentsOnDockApp: MenuBarExtra

### Phase 6: 팀 편집 설정창 + 앱 내 구성 (태스크 #101)

#### 목표
일반 App Store 사용자가 agents.json을 직접 편집하지 않고, 앱 설정창에서 팀을 구성할 수 있도록 한다.

#### 6-1: 에이전트 캐릭터 이미지 (8종)
- 8개 Lottie 애니메이션 캐릭터 번들 제공
- 각 캐릭터는 20가지 표정 상태 지원 (Solo 모드와 동일)
- Resources/Animations/ 에 캐릭터별 JSON 파일 배치

#### 6-2: 팀 편집 설정창 (TeamEditorView)
- 에이전트 추가/삭제/순서 변경
- 에이전트별 설정 항목:
  - **캐릭터 이미지**: 8종 중 선택 (그리드 팝업)
  - **이름**: 자유 입력 (예: Nova, Sprout, Bolt)
  - **모델**: Haiku / Sonnet / Opus 드롭다운
  - **역할**: 자유 입력 (예: 리더, 프론트엔드, 백엔드)
- 저장 시 앱 내부 JSON으로 저장 + Dock 캐릭터 즉시 반영
- 최대 에이전트 수: 8개 (이미지 수에 맞춤)

#### 6-3: 데이터 저장 구조
- 앱 내부 저장: Application Support/team-config.json
- 구조:
  ```json
  {
    "agents": [
      {
        "id": "uuid",
        "name": "Nova",
        "character": "blue_robot",
        "model": "opus",
        "role": "리더"
      }
    ]
  }
  ```
- agents.json 연동은 고급 모드(선택사항)로 분리

#### 6-4: 설정창 UI 구성

```
┌─────────────────────────────────────────┐
│  팀 구성                         [+추가] │
├─────────────────────────────────────────┤
│  ┌──────┐  이름: [Nova          ]       │
│  │(캐릭터)│  모델: [Opus    ▼]           │
│  │ 선택  │  역할: [리더/PM       ]  [🗑️] │
│  └──────┘                               │
│  ┌──────┐  이름: [Sprout        ]       │
│  │(캐릭터)│  모델: [Sonnet  ▼]           │
│  │ 선택  │  역할: [프론트엔드    ]  [🗑️] │
│  └──────┘                               │
├─────────────────────────────────────────┤
│         [초기화]           [저장]         │
└─────────────────────────────────────────┘
```

- 캐릭터 이미지 클릭 시 8종 그리드 팝업으로 선택
- 드래그로 순서 변경 가능
- 저장 즉시 Dock 패널에 반영

#### 6-5: 기존 agents.json 연동 (고급 모드)
- 설정창 하단에 "고급: 프로젝트 폴더 연결" 토글
- 활성화 시 기존 BookmarkService + AgentsConfigService 동작
- 비활성화 시 앱 내부 team-config.json만 사용
- 일반 사용자는 고급 모드를 몰라도 사용 가능

#### 구현 순서
1. TeamEditorView 설정창 UI 구성
2. TeamConfigStore 서비스 (앱 내부 JSON 저장/로드)
3. 캐릭터 선택 그리드 팝업 (CharacterPickerView)
4. Dock 패널 연동 (TeamConfigStore → TeamPanelManager)
5. 기존 AgentsConfigService와 모드 분기 처리
6. 8종 Lottie 캐릭터 이미지 리소스 추가

### Phase 7: 배포 준비 (예정)
- Xcode 프로젝트 변환 (SPM → Xcode)
- 코드 서명 및 프로비저닝
- App Store Connect 등록

## 주요 설계 결정

1. **Sandbox + 프로세스 감지**: Process()로 ps aux 실행 → Sandbox에서 차단 시 빈 배열 반환 (graceful degradation)
2. **Security-Scoped Bookmarks**: 프로젝트 폴더 영구 접근 권한 유지
3. **FSEvents 감시**: agents.json 변경 시 debounce 0.5초 후 자동 리로드
4. **동적 패널 크기**: 에이전트 수에 따라 1행/2행 자동 전환
