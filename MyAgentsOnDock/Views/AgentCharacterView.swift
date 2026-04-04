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
        // 유명 밈 & 인터넷 유머
        "This is fine. 🔥🐶🔥",
        "나 지금 진지한 거야? 네, 매우 진지합니다 🗿",
        "어... 그건 내일의 내가 할 일이지 😎",
        "인생은 짧아. 파이썬을 써 🐍",
        "404: 할 일을 찾을 수 없습니다",
        "sudo make me a sandwich 🥪",
        "방금 뭐 하려고 했더라... 🤔",
        "오늘의 운세: 대길 🎋",
        "피자 먹고 싶다... 하와이안 말고 🍕",
        "현실은 VR보다 그래픽이 좋다 🌎",

        // 세계적 농담
        "평행우주의 나는 지금 뭐 하고 있을까 🌌",
        "고양이가 세계를 지배하는 건 시간문제야 🐱",
        "달에 가고 싶다... Wi-Fi만 되면 🌙",
        "시간여행이 되면 어제 먹은 치킨을 다시 먹을 거야 🍗",
        "만약 내가 영화 주인공이라면... 엑스트라겠지 🎬",
        "우주는 넓고 할 건 많다... 근데 넷플릭스가... 📺",
        "잠은 DLC인데 왜 무료지? 💤",

        // 철학적(?) 유머
        "내가 생각한다, 고로 배가 고프다 🧠",
        "로봇도 꿈을 꿀까? 전기양의 꿈을? 🤖",
        "오늘 하루도 무사히... 아직 끝 안 났구나 ⏰",
        "행복은 가까이 있어. 냉장고 안에 🧊",

        // 동물 밈
        "도지 왈: such empty, much bored, wow 🐕",
        "카피바라처럼 살고 싶다. 평화롭게 🦫",
        "오리는 공짜로 빵을 먹는다. 부럽다 🦆",
        "고슴도치 딜레마: 가까이 가면 찔리고 멀면 춥고 🦔",

        // 랜덤 재미
        "혈액형이 B형이라 B급 유머밖에 못 해요 😂",
        "지구는 둥글다. 하지만 내 인생은 롤러코스터 🎢",
        "음악 추천해줄까? 절대로 포기 안 할 거야 🎵",
        "Wi-Fi 없는 곳에선 살 수 없어 📡",
        "오늘의 명언: 내일은 내일의 해가 뜬다 ☀️",
        "아이스크림은 슬플 때도 맛있다 🍦",
        "세상에서 제일 긴 단어? 스마일. S와 E 사이에 마일이 있으니까 😁",
        "나는 멀티태스킹 마스터. 동시에 아무것도 안 함 🏆",
        "시간은 금이다. 근데 난 파산했다 💸",
        "외계인이 지구를 안 침공하는 이유? 별점 1점이라서 ⭐",
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
