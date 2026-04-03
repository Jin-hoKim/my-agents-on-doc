import SwiftUI

// 개별 에이전트 캐릭터 뷰
struct AgentCharacterView: View {
    let agent: TeamAgent
    let characterSize: Double

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 3) {
            // 캐릭터 이모지 + 배경
            ZStack {
                // 배경 원형 그래디언트
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: characterSize * 0.85, height: characterSize * 0.85)
                    .shadow(
                        color: agent.isActive ? .green.opacity(0.5) : .black.opacity(0.15),
                        radius: agent.isActive ? 10 : 3
                    )

                // 이모지
                Text(agent.emoji)
                    .font(.system(size: characterSize * 0.4))
                    .scaleEffect(isAnimating && agent.isActive ? 1.1 : 1.0)
                    .animation(
                        agent.isActive
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .easeInOut(duration: 0.3),
                        value: isAnimating
                    )

                // 활성 상태 인디케이터 (초록 점)
                Circle()
                    .fill(agent.isActive ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .shadow(color: agent.isActive ? .green : .clear, radius: 3)
                    .offset(x: characterSize * 0.33, y: -characterSize * 0.33)

                // 모델 뱃지
                Text(agent.modelBadge)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(modelBadgeColor)
                    .clipShape(Capsule())
                    .offset(x: characterSize * 0.3, y: characterSize * 0.3)
            }

            // 에이전트 이름
            Text(agent.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
                .frame(maxWidth: characterSize + 10)

            // 역할 상태
            Text(agent.isActive ? "작업 중" : agent.id)
                .font(.system(size: 8))
                .foregroundColor(agent.isActive ? .green : .secondary)
                .lineLimit(1)
        }
        .frame(width: characterSize + 16, height: characterSize + 34)
        .onAppear {
            isAnimating = agent.isActive
        }
        .onChange(of: agent.isActive) { _, active in
            withAnimation(.spring(duration: 0.3)) {
                isAnimating = active
            }
        }
    }

    // 배경 그래디언트
    private var backgroundGradient: some ShapeStyle {
        if agent.isActive {
            return LinearGradient(
                colors: [Color.green.opacity(0.2), Color.green.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // 모델 뱃지 색상
    private var modelBadgeColor: Color {
        switch agent.model.lowercased() {
        case "opus": return .purple
        case "sonnet": return .blue
        case "haiku": return .green
        default: return .gray
        }
    }
}
