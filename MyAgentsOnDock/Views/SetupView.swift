import SwiftUI

// 초기 설정 / 프로젝트 연결 뷰
struct SetupView: View {
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared
    @State private var showingSuccess = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                headerSection

                Divider()

                // 섹션 1: 프로젝트 디렉토리 선택
                projectSection

                Divider()

                // 섹션 2: agents.json 연결 상태
                connectionSection

                // 섹션 3: 팀 미리보기 (연결된 경우)
                if configService.connectionStatus.isConnected && !configService.agents.isEmpty {
                    Divider()
                    teamPreviewSection
                }

                // 섹션 4: agents.json 형식 가이드 (파일 없음 / 오류 시)
                if case .fileNotFound = configService.connectionStatus {
                    Divider()
                    formatGuideSection
                }
                if case .error = configService.connectionStatus {
                    Divider()
                    formatGuideSection
                }

                Spacer(minLength: 10)
            }
            .padding(20)
        }
        .frame(width: 480)
    }

    // 헤더
    private var headerSection: some View {
        HStack {
            Text("👥")
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text("My Agents on Dock")
                    .font(.title2.bold())
                Text("Claude Code 팀을 Dock 위에 시각화합니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // 프로젝트 디렉토리 선택
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("프로젝트 폴더", systemImage: "folder.fill")
                .font(.headline)

            if let url = bookmarkService.projectURL {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("변경") {
                        bookmarkService.selectProjectDirectory()
                        configService.loadAgents()
                    }
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    Text("Claude Code 팀이 구성된 프로젝트 폴더를 선택하세요.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        bookmarkService.selectProjectDirectory()
                        configService.loadAgents()
                    }) {
                        Label("프로젝트 폴더 선택", systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // agents.json 연결 상태
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("연결 상태", systemImage: "network")
                .font(.headline)

            HStack(spacing: 10) {
                Image(systemName: configService.connectionStatus.icon)
                    .foregroundColor(statusColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(configService.connectionStatus.displayText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(statusColor)

                    if let url = bookmarkService.agentsConfigURL {
                        Text(url.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                if bookmarkService.projectURL != nil {
                    Button("새로고침") {
                        configService.loadAgents()
                    }
                    .controlSize(.small)
                }
            }
            .padding(10)
            .background(statusColor.opacity(0.08))
            .cornerRadius(8)
        }
    }

    // 팀 미리보기 테이블
    private var teamPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("팀 구성 (\(configService.agents.count)명)", systemImage: "person.3.fill")
                .font(.headline)

            VStack(spacing: 0) {
                // 테이블 헤더
                HStack {
                    Text("")
                        .frame(width: 28)
                    Text("역할")
                        .frame(width: 80, alignment: .leading)
                    Text("이름")
                        .frame(width: 100, alignment: .leading)
                    Text("모델")
                        .frame(width: 60, alignment: .leading)
                    Text("설명")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))

                Divider()

                // 에이전트 목록
                ForEach(configService.agents) { agent in
                    HStack {
                        Text(agent.emoji)
                            .frame(width: 28)
                        Text(agent.id)
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        Text(agent.name)
                            .font(.caption.weight(.medium))
                            .frame(width: 100, alignment: .leading)
                        modelBadgeView(agent.model)
                            .frame(width: 60, alignment: .leading)
                        Text(agent.roleDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)

                    if agent.id != configService.agents.last?.id {
                        Divider().padding(.leading, 10)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // agents.json 형식 가이드
    private var formatGuideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("agents.json 형식", systemImage: "doc.text")
                .font(.headline)

            Text("프로젝트 폴더의 team/agents.json 파일이 아래 형식을 따르는지 확인하세요:")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("""
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
""")
            .font(.system(.caption, design: .monospaced))
            .padding(10)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // 모델 뱃지
    private func modelBadgeView(_ model: String) -> some View {
        Text(model)
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(modelColor(model))
            .clipShape(Capsule())
    }

    private func modelColor(_ model: String) -> Color {
        switch model.lowercased() {
        case "opus": return .purple
        case "sonnet": return .blue
        case "haiku": return .green
        default: return .gray
        }
    }

    private var statusColor: Color {
        switch configService.connectionStatus {
        case .connected: return .green
        case .notConnected: return .gray
        case .fileNotFound: return .orange
        case .error: return .red
        }
    }
}
