import SwiftUI
import Lottie

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
