import SwiftUI
import Lottie
import AVFoundation

// Individual agent character view
struct AgentCharacterView: View {
    let agent: TeamAgent
    let size: CGFloat

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Background circular gradient
                Circle()
                    .fill(backgroundGradient(isActive: agent.isActive))
                    .frame(width: size * 0.85, height: size * 0.85)
                    .shadow(
                        color: agent.isActive ? .green.opacity(0.5) : .black.opacity(0.15),
                        radius: agent.isActive ? 10 : 3
                    )

                // Character image (Lottie or emoji)
                if let character = agent.character {
                    LottieView(animation: .named(character.fileName, bundle: .module))
                        .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                        .animationSpeed(agent.isActive ? 3.0 : 1.0)
                        .frame(width: size * 0.7, height: size * 0.7)
                } else {
                    Text(agent.emoji)
                        .font(.system(size: size * 0.4))
                }

                // Active state indicator (green dot)
                Circle()
                    .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: max(6, size * 0.08), height: max(6, size * 0.08))
                    .shadow(color: agent.isActive ? .green : .clear, radius: 3)
                    .offset(x: size * 0.33, y: -size * 0.33)
            }
            .onTapGesture {
                handleTap()
            }

            // Agent name (proportional to size)
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
        if agent.isActive {
            let name = agent.name.isEmpty ? agent.id : agent.name
            let role = agent.roleDescription.isEmpty ? agent.id : agent.roleDescription
            let text = "\(name): Working on \(role)! Doing my best 💪"
            BubbleWindowManager.shared.showBubble(text: text)
            AgentTTSService.shared.speak(text)
        } else {
            let name = agent.name.isEmpty ? agent.id : agent.name
            // Show loading state
            BubbleWindowManager.shared.showBubble(text: "\(name): Hmm... 🤔")
            // Fetch a joke from the web
            JokeFetcher.shared.fetchJoke { joke in
                DispatchQueue.main.async {
                    let text = "\(name): \(joke)"
                    BubbleWindowManager.shared.showBubble(text: text)
                    AgentTTSService.shared.speak(text)
                }
            }
        }
    }

    // Background gradient
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

// Show speech bubble in a separate NSPanel (unaffected by SwiftUI re-renders)
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

                // Tail
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

        // Show near mouse position
        let mouseLocation = NSEvent.mouseLocation
        let x = mouseLocation.x - contentSize.width / 2
        let y = mouseLocation.y + 60
        newPanel.setFrameOrigin(NSPoint(x: x, y: y))
        newPanel.orderFront(nil)

        panel = newPanel

        // Auto-close after 5 seconds
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.panel?.close()
                self?.panel = nil
            }
        }
    }
}

// Fetch jokes from free API (fallback: local jokes)
class JokeFetcher {
    static let shared = JokeFetcher()

    // icanhazdadjoke.com (free, no key required)
    func fetchJoke(completion: @escaping (String) -> Void) {
        let apis: [() -> URLRequest] = [
            { self.dadJokeRequest() },
            { self.jokeApiRequest() },
        ]

        // Select a random API
        let request = apis.randomElement()!()

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(AgentQuotes.randomQuote())
                return
            }

            if let joke = self.parseDadJoke(data) ?? self.parseJokeApi(data) {
                completion(joke)
            } else {
                completion(AgentQuotes.randomQuote())
            }
        }
        task.resume()
    }

    // icanhazdadjoke.com request
    private func dadJokeRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: "https://icanhazdadjoke.com/")!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("MyAgentsOnDock/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 3
        return request
    }

    // JokeAPI request (Programming, Misc, Pun)
    private func jokeApiRequest() -> URLRequest {
        let categories = ["Programming", "Misc", "Pun", "Christmas"]
        let category = categories.randomElement()!
        var request = URLRequest(url: URL(string: "https://v2.jokeapi.dev/joke/\(category)?type=single&safe-mode")!)
        request.timeoutInterval = 3
        return request
    }

    private func parseDadJoke(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let joke = json["joke"] as? String else { return nil }
        return joke
    }

    private func parseJokeApi(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        // single type joke
        if let joke = json["joke"] as? String { return joke }
        // two-part type joke
        if let setup = json["setup"] as? String, let delivery = json["delivery"] as? String {
            return "\(setup)\n\(delivery)"
        }
        return nil
    }
}

// Random idle quotes for agents (fallback when network fails)
enum AgentQuotes {
    static let idleQuotes: [String] = [
        // Famous memes & internet humor
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

        // Universal jokes
        "평행우주의 나는 지금 뭐 하고 있을까 🌌",
        "고양이가 세계를 지배하는 건 시간문제야 🐱",
        "달에 가고 싶다... Wi-Fi만 되면 🌙",
        "시간여행이 되면 어제 먹은 치킨을 다시 먹을 거야 🍗",
        "만약 내가 영화 주인공이라면... 엑스트라겠지 🎬",
        "우주는 넓고 할 건 많다... 근데 넷플릭스가... 📺",
        "잠은 DLC인데 왜 무료지? 💤",

        // Philosophical(?) humor
        "내가 생각한다, 고로 배가 고프다 🧠",
        "로봇도 꿈을 꿀까? 전기양의 꿈을? 🤖",
        "오늘 하루도 무사히... 아직 끝 안 났구나 ⏰",
        "행복은 가까이 있어. 냉장고 안에 🧊",

        // Animal memes
        "도지 왈: such empty, much bored, wow 🐕",
        "카피바라처럼 살고 싶다. 평화롭게 🦫",
        "오리는 공짜로 빵을 먹는다. 부럽다 🦆",
        "고슴도치 딜레마: 가까이 가면 찔리고 멀면 춥고 🦔",

        // Random fun
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
        return "\(name): \(randomQuote())"
    }

    static func randomQuote() -> String {
        idleQuotes.randomElement() ?? "..."
    }
}

// TTS speech service
class AgentTTSService {
    static let shared = AgentTTSService()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, force: Bool = false) {
        // Skip if TTS disabled (force=true for preview)
        if !force {
            let enabled = DispatchQueue.main.sync { AppSettings.shared.ttsEnabled }
            guard enabled else { return }
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Read only the content after "name: "
        let content: String
        if let colonRange = text.range(of: ": ") {
            content = String(text[colonRange.upperBound...])
        } else {
            content = text
        }

        let voiceId = DispatchQueue.main.sync { AppSettings.shared.ttsVoiceRaw }
        let utterance = AVSpeechUtterance(string: content)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voiceId)
            ?? AVSpeechSynthesisVoice(language: "ko-KR")
        utterance.rate = 0.5
        utterance.volume = 0.7
        synthesizer.speak(utterance)
    }
}
