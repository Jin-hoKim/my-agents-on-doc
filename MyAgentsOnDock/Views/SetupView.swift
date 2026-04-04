import SwiftUI
import AppKit

// 초기 설정 / 프로젝트 연결 뷰
struct SetupView: View {
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared

    // NSHostingView 임베딩이므로 뷰가 속한 윈도우를 직접 찾아 닫기
    private func closeWindow() {
        DispatchQueue.main.async {
            // 이 뷰를 호스팅하는 윈도우 찾기
            if let window = NSApp.windows.first(where: { $0.title == "팀 프로젝트 연결" }) {
                window.close()
            } else {
                NSApp.keyWindow?.close()
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 헤더
            headerSection

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 섹션 1: 프로젝트 폴더 선택
                    projectFolderSection

                    Divider()

                    // 섹션 2: agents.json 상태
                    agentsFileStatusSection

                    // 섹션 3: 팀 미리보기
                    if !configService.agents.isEmpty {
                        Divider()
                        teamPreviewSection
                    }
                }
                .padding(20)
            }

            Divider()

            // 하단 버튼
            bottomButtons
        }
        .frame(width: 480, height: 520)
        .onAppear {
            configService.reload()
        }
    }

    // 헤더
    private var headerSection: some View {
        HStack {
            Text("🤖")
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text("My Agents on Dock")
                    .font(.headline)
                Text("Claude Code 팀 프로젝트를 연결하세요")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    // 섹션 1: 프로젝트 폴더 선택
    private var projectFolderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("프로젝트 폴더", systemImage: "folder")
                .font(.subheadline.weight(.semibold))

            HStack {
                if let url = bookmarkService.projectURL {
                    Text(url.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("선택된 폴더 없음")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }

                Button("선택...") {
                    bookmarkService.selectProjectFolder()
                    // 폴더 선택 후 자동 리로드
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: .projectURLChanged, object: nil)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // 섹션 2: agents.json 상태
    private var agentsFileStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("agents.json 상태", systemImage: "doc.text")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                Text(configService.connectionStatus.statusEmoji)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(configService.connectionStatus.displayText)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                    if let url = bookmarkService.projectURL {
                        Text(url.appendingPathComponent("team/agents.json").path)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()

                // 새로고침 버튼
                Button(action: { configService.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(statusBackground)
            .cornerRadius(8)

            // agents.json 형식 가이드 (오류 시)
            if case .parseError = configService.connectionStatus {
                agentsJsonGuide
            }
            if case .fileNotFound = configService.connectionStatus {
                agentsJsonGuide
            }
        }
    }

    // 섹션 3: 팀 미리보기
    private var teamPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("팀 구성 (\(configService.agents.count)명)", systemImage: "person.3")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 1) {
                // 헤더 행
                HStack {
                    Text("역할").frame(width: 80, alignment: .leading)
                    Text("이름").frame(maxWidth: .infinity, alignment: .leading)
                    Text("모델").frame(width: 80, alignment: .leading)
                    Text("설명").frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))

                // 에이전트 행들
                ForEach(configService.agents) { agent in
                    HStack {
                        HStack(spacing: 4) {
                            Text(agent.emoji)
                            Text(agent.id)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .frame(width: 80, alignment: .leading)

                        Text(agent.name.isEmpty ? "-" : agent.name)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(agent.model)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(modelColor(agent.model))
                            .frame(width: 80, alignment: .leading)

                        Text(agent.roleDescription.isEmpty ? "-" : agent.roleDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.clear)

                    Divider()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // agents.json 형식 가이드
    private var agentsJsonGuide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("agents.json 형식 예시:")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Text("""
{
  "leader": {
    "model": "opus",
    "description": "PM 재혁 — 요구사항 분석",
    "prompt": "당신은 PM입니다..."
  },
  "frontend": {
    "model": "sonnet",
    "description": "개발자 민지 — Vue 3 전문",
    "prompt": "..."
  }
}
""")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
        }
    }

    // 하단 버튼
    private var bottomButtons: some View {
        HStack {
            if bookmarkService.projectURL != nil {
                Button("연결 해제") {
                    DispatchQueue.main.async {
                        bookmarkService.clearBookmark()
                        configService.reload()
                    }
                }
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }

            Spacer()

            Button("닫기") {
                closeWindow()
            }

            Button("팀 연결") {
                AppSettings.shared.isPanelVisible = true
                closeWindow()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!configService.connectionStatus.isConnected)
        }
        .padding(16)
    }

    private var statusColor: Color {
        switch configService.connectionStatus {
        case .connected:    return .green
        case .fileNotFound, .parseError: return .red
        default:            return .secondary
        }
    }

    private var statusBackground: Color {
        switch configService.connectionStatus {
        case .connected:    return .green.opacity(0.08)
        case .fileNotFound, .parseError: return .red.opacity(0.08)
        default:            return .secondary.opacity(0.06)
        }
    }

    private func modelColor(_ model: String) -> Color {
        switch model.lowercased() {
        case "opus":   return .purple
        case "sonnet": return .blue
        case "haiku":  return .teal
        default:       return .secondary
        }
    }
}
