import SwiftUI
import Lottie
import AVFoundation

// 개별 에이전트 캐릭터 뷰
struct AgentCharacterView: View {
    let agent: TeamAgent
    let size: CGFloat

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // 배경 원형 그래디언트
                Circle()
                    .fill(backgroundGradient(isActive: agent.isActive))
                    .frame(width: size * 0.85, height: size * 0.85)
                    .shadow(
                        color: agent.isActive ? .green.opacity(0.5) : .black.opacity(0.15),
                        radius: agent.isActive ? 10 : 3
                    )

                // 캐릭터 이미지 (Lottie 또는 이모지)
                if let character = agent.character {
                    LottieView(animation: .named(character.fileName, bundle: .module))
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                        .animationSpeed(agent.isActive ? 3.0 : 1.0)
                        .frame(width: size * 0.7, height: size * 0.7)
                } else {
                    Text(agent.emoji)
                        .font(.system(size: size * 0.4))
                }

                // 활성 상태 인디케이터 (초록 점)
                Circle()
                    .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: max(6, size * 0.08), height: max(6, size * 0.08))
                    .shadow(color: agent.isActive ? .green : .clear, radius: 3)
                    .offset(x: size * 0.33, y: -size * 0.33)
            }
            .onTapGesture {
                handleTap()
            }

            // 에이전트 이름 (크기 비례)
            Text(agent.name.isEmpty ? agent.id : agent.name)
                .font(.system(size: max(9, size * 0.12), weight: .medium))
                .foregroundColor(agent.isActive ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: size + 20)
        }
        .frame(width: size + 20, height: size + max(30, size * 0.25))
    }

    private func handleTap() {
        let text: String
        if agent.isActive {
            let name = agent.name.isEmpty ? agent.id : agent.name
            let role = agent.roleDescription.isEmpty ? agent.id : agent.roleDescription
            text = "\(name): \(role) 작업 중이에요! 열심히 하고 있어요 💪"
        } else {
            text = AgentQuotes.random(for: agent)
        }

        BubbleWindowManager.shared.showBubble(text: text)
        AgentTTSService.shared.speak(text)
    }

    // 배경 그래디언트
    private func backgroundGradient(isActive: Bool) -> LinearGradient {
        if isActive {
            return LinearGradient(
                colors: [Color.green.opacity(0.25), Color.green.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// 말풍선을 별도 NSPanel로 표시 (SwiftUI 리렌더에 영향 안 받음)
@MainActor
class BubbleWindowManager {
    static let shared = BubbleWindowManager()
    private var panel: NSPanel?
    private var hideTimer: Timer?

    func showBubble(text: String) {
        hideTimer?.invalidate()
        panel?.close()

        let bubbleView = NSHostingView(rootView:
            VStack(spacing: 0) {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.88))
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                // 꼬리
                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.black.opacity(0.88))
                    .rotationEffect(.degrees(180))
            }
        )

        let contentSize = bubbleView.fittingSize
        let newPanel = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.level = .floating + 1
        newPanel.collectionBehavior = [.canJoinAllSpaces]
        newPanel.contentView = bubbleView

        // 마우스 위치 근처에 표시
        let mouseLocation = NSEvent.mouseLocation
        let x = mouseLocation.x - contentSize.width / 2
        let y = mouseLocation.y + 60
        newPanel.setFrameOrigin(NSPoint(x: x, y: y))
        newPanel.orderFront(nil)

        panel = newPanel

        // 5초 후 자동 닫기
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.panel?.close()
                self?.panel = nil
            }
        }
    }
}

// 에이전트 대기 중 랜덤 대사
enum AgentQuotes {
    static let idleQuotes: [String] = [
        "심심해... 일 좀 시켜줘~ 🥱",
        "커피 한 잔 하고 올게요 ☕",
        "코드 리뷰할 거 없나요? 👀",
        "버그는 어디 숨었을까... 🔍",
        "오늘도 열일할 준비 완료! 🔥",
        "잠깐 스트레칭 중... 🧘",
        "다음 태스크는 뭐예요? 📋",
        "리팩토링하고 싶은 코드가 보여요 😤",
        "테스트 커버리지 올려볼까요? 📊",
        "문서화... 나중에 하면 안 되나요? 📝",
        "zzZ... 아, 안 졸았어요! 😳",
        "PR 머지 기다리는 중... ⏳",
        "Git 충돌이 무서워요 😱",
        "오늘 배포 있나요? 🚀",
        "이 코드 누가 짠 거야... 아, 나네 😅",
        "AI인데 가끔 사람이 되고 싶어요 🤔",
        "세미콜론 빠뜨린 거 아니죠? ;",
        "Stack Overflow 없이도 할 수 있어요! 💪",
        "다크 모드가 최고야 🌙",
        "타입스크립트 any 쓰면 안 돼요! 🚫",
        "컴파일 에러 0개... 행복해 😊",
        "주말에도 일해야 하나요? 🥺",
    ]

    static func random(for agent: TeamAgent) -> String {
        let name = agent.name.isEmpty ? agent.id : agent.name
        let quote = idleQuotes.randomElement() ?? "..."
        return "\(name): \(quote)"
    }
}

// TTS 음성 서비스
class AgentTTSService {
    static let shared = AgentTTSService()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // 이름: 뒤의 내용만 읽기
        let content: String
        if let colonRange = text.range(of: ": ") {
            content = String(text[colonRange.upperBound...])
        } else {
            content = text
        }

        let utterance = AVSpeechUtterance(string: content)
        if let koVoice = AVSpeechSynthesisVoice(language: "ko-KR") {
            utterance.voice = koVoice
        }
        utterance.rate = 0.5
        utterance.volume = 0.7
        synthesizer.speak(utterance)
    }
}
