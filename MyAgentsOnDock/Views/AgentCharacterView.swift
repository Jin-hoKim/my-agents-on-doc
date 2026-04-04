import SwiftUI
import Lottie

// 개별 에이전트 캐릭터 뷰
struct AgentCharacterView: View {
    let agent: TeamAgent
    let size: CGFloat

    @State private var isAnimating = false

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
                        .playbackMode(agent.isActive
                            ? .playing(.toProgress(1, loopMode: .loop))
                            : .playing(.toProgress(0.5, loopMode: .playOnce)))
                        .frame(width: size * 0.7, height: size * 0.7)
                } else {
                    Text(agent.emoji)
                        .font(.system(size: size * 0.4))
                        .scaleEffect(isAnimating && agent.isActive ? 1.1 : 1.0)
                        .animation(
                            agent.isActive
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                : .easeInOut(duration: 0.3),
                            value: isAnimating
                        )
                }

                // 활성 상태 인디케이터 (초록 점)
                Circle()
                    .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .shadow(color: agent.isActive ? .green : .clear, radius: 3)
                    .offset(x: size * 0.33, y: -size * 0.33)

                // 모델 뱃지
                Text(agent.modelBadge)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(modelBadgeColor(model: agent.model))
                    .clipShape(Capsule())
                    .offset(x: -size * 0.3, y: -size * 0.33)
            }

            // 에이전트 이름
            Text(agent.name.isEmpty ? agent.id : agent.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(agent.isActive ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: size + 4)

            // 상태 텍스트
            Text(agent.isActive ? "작업 중" : "대기 중")
                .font(.system(size: 7))
                .foregroundColor(agent.isActive ? .green : .secondary.opacity(0.6))
        }
        .frame(width: size + 4, height: size + 38)
        .onAppear {
            isAnimating = agent.isActive
        }
        .onChange(of: agent.isActive) { _, active in
            withAnimation(.spring) {
                isAnimating = active
            }
        }
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

    // 모델 뱃지 색상
    private func modelBadgeColor(model: String) -> Color {
        switch model.lowercased() {
        case "opus":   return .purple
        case "sonnet": return .blue
        case "haiku":  return .teal
        default:       return .gray
        }
    }
}
