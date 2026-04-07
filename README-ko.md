# My Agents on Dock

macOS Dock 위에 AI 에이전트 캐릭터를 애니메이션으로 표시하는 메뉴바 앱. Claude Code 팀 구성을 자동 감지하여 각 에이전트를 고유한 Lottie 로봇 캐릭터로 표현합니다.

## 주요 기능

- **9종 애니메이션 캐릭터** — 다채로운 Lottie 로봇 애니메이션 (블랙, 블루, 그린, 마린, 핑크, 퍼플, 레드, 화이트, 옐로)
- **팀 구성** — `team/agents.json`을 읽어 팀 구조 자동 감지, 또는 설정에서 직접 구성
- **실시간 상태** — Claude CLI 프로세스 감지; 작업 중 에이전트는 3배속 애니메이션 + 초록 발광
- **말풍선** — 캐릭터 클릭 시 농담 (무료 API) 또는 작업 상태 표시; 9종 TTS 음성 지원
- **유연한 레이아웃** — 1열, 1횡, 2열, 2횡
- **드래그 정렬** — 캐릭터를 드래그하여 순서 변경; 재시작해도 유지
- **실시간 리로드** — FSEvents로 agents.json 변경 감지 및 자동 업데이트

## 요구사항

- macOS 14.0 (Sonoma) 이상
- Claude Code CLI (프로세스 감지용)

## 설치

### 소스에서 빌드

```bash
git clone https://github.com/Jin-hoKim/my-agents-on-doc.git
cd my-agents-on-dock
swift build
.build/debug/MyAgentsOnDock
```

## 시작하기

1. **앱 실행** — 메뉴바에서 👥 아이콘 확인
2. **프로젝트 연결** — 메뉴바 아이콘 클릭 → "Connect Team Project" → `team/agents.json`이 포함된 프로젝트 폴더 선택
3. **캐릭터 커스터마이징** — 설정에서 각 에이전트에 로봇 캐릭터와 이름 지정
4. **팀 모니터링** — 작업 중 에이전트는 초록색으로 빠르게 애니메이션; 클릭하면 상태 확인

## agents.json 형식

```json
{
  "leader": {
    "model": "opus",
    "description": "Nova — 팀 리더, 기획"
  },
  "frontend": {
    "model": "sonnet",
    "description": "Sprout — 프론트엔드 개발자"
  },
  "backend": {
    "model": "sonnet",
    "description": "Bolt — 백엔드 개발자"
  }
}
```

`description` 필드는 "이름 — 역할" 형식. 이름이 추출되어 캐릭터 아래에 표시됩니다.

## 캐릭터

| 캐릭터 | 색상 |
|--------|------|
| Black Robot | 다크 그레이 |
| Blue Robot | 블루 |
| Green Robot | 그린 |
| Marine Robot | 시안 |
| Pink Robot | 핑크 |
| Purple Robot | 퍼플 |
| Red Robot | 레드 |
| White Robot | 라이트 그레이 |
| Yellow Robot | 옐로 |

## 설정

| 설정 | 설명 |
|------|------|
| **캐릭터 크기** | 60pt – 300pt 슬라이더 |
| **레이아웃** | 1열 / 1횡 / 2열 / 2횡 |
| **팀 편집** | 에이전트별 캐릭터 지정, 이름 편집 |
| **TTS 음성** | 9종 음성 (Yuna, Rocko, Grandma, Eddy 등) |
| **음성 토글** | 클릭 시 음성 켜기/끄기 |
| **프로세스 감시** | 1~10초 폴링 간격 |

## 기술 스택

- Swift 5.9+ / SwiftUI / AppKit (NSPanel, NSStatusItem)
- Lottie for iOS (캐릭터 애니메이션)
- AVSpeechSynthesizer (TTS)
- FSEvents (파일 변경 감지)
- 무료 농담 API (icanhazdadjoke.com, JokeAPI)

## 관련 프로젝트

- [Docklings](https://github.com/Jin-hoKim/my-agent-on-doc) — Solo 모드 (단일 AI 컴패니언)

## 라이선스

Copyright 2026 김진호. All rights reserved.

---

[English](README.md)
