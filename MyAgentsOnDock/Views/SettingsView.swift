import SwiftUI

// 환경설정 뷰
struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var bookmarkService = BookmarkService.shared
    @ObservedObject private var configService = AgentsConfigService.shared

    var body: some View {
        Form {
            // 표시 설정
            Section("표시") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("캐릭터 크기")
                        Spacer()
                        Text("\(Int(settings.characterSize))pt")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: $settings.characterSize,
                        in: AppSettings.minSize...AppSettings.maxSize,
                        step: 4
                    )
                    .onChange(of: settings.characterSize) { _, _ in
                        NotificationCenter.default.post(name: .agentsDidChange, object: nil)
                    }
                }

                Toggle("Dock 위 캐릭터 표시", isOn: $settings.isPanelVisible)
            }

            // 모니터링 설정
            Section("프로세스 감지") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("감지 간격")
                        Spacer()
                        Text("\(Int(settings.monitorInterval))초")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: $settings.monitorInterval,
                        in: AppSettings.minInterval...AppSettings.maxInterval,
                        step: 1
                    )
                    .onChange(of: settings.monitorInterval) { _, _ in
                        ProcessMonitorService.shared.start()
                    }
                }
                Text("Claude CLI 프로세스를 N초마다 감지하여 에이전트 활성 상태를 업데이트합니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 프로젝트 연결
            Section("프로젝트 연결") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bookmarkService.projectURL?.lastPathComponent ?? "미연결")
                            .font(.subheadline.weight(.medium))
                        if let url = bookmarkService.projectURL {
                            Text(url.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    Spacer()
                    Button("변경") {
                        bookmarkService.selectProjectDirectory()
                        configService.loadAgents()
                    }
                    .controlSize(.small)
                }

                if bookmarkService.projectURL != nil {
                    Button("연결 해제", role: .destructive) {
                        bookmarkService.stopAccessing()
                        configService.agents = []
                        configService.connectionStatus = .notConnected
                        ProcessMonitorService.shared.stop()
                    }
                    .controlSize(.small)
                }
            }

            // 앱 정보
            Section("정보") {
                HStack {
                    Text("버전")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("지원 macOS")
                    Spacer()
                    Text("14.0 (Sonoma) 이상")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 500)
    }
}
