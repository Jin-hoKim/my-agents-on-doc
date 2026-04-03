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

### Phase 6: 배포 준비 (예정)
- Xcode 프로젝트 변환 (SPM → Xcode)
- 코드 서명 및 프로비저닝
- App Store Connect 등록

## 주요 설계 결정

1. **Sandbox + 프로세스 감지**: Process()로 ps aux 실행 → Sandbox에서 차단 시 빈 배열 반환 (graceful degradation)
2. **Security-Scoped Bookmarks**: 프로젝트 폴더 영구 접근 권한 유지
3. **FSEvents 감시**: agents.json 변경 시 debounce 0.5초 후 자동 리로드
4. **동적 패널 크기**: 에이전트 수에 따라 1행/2행 자동 전환
