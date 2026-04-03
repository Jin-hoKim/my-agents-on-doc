import AppKit
import Foundation

// Security-Scoped Bookmarks를 통한 프로젝트 디렉토리 접근 관리
@MainActor
class BookmarkService: ObservableObject {
    static let shared = BookmarkService()

    private let bookmarkKey = "projectDirectoryBookmark"
    private var accessedURL: URL?

    @Published var projectURL: URL?
    @Published var isAccessing: Bool = false

    // 앱 시작 시 저장된 bookmark 복원 시도
    func restoreBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // 오래된 bookmark → 재선택 필요
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
                return
            }

            if url.startAccessingSecurityScopedResource() {
                accessedURL = url
                projectURL = url
                isAccessing = true
            }
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    // NSOpenPanel로 프로젝트 폴더 선택
    func selectProjectDirectory() {
        let panel = NSOpenPanel()
        panel.title = "프로젝트 폴더 선택"
        panel.message = "Claude Code 팀이 구성된 프로젝트 폴더를 선택하세요"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        // 기존 접근 해제
        stopAccessing()

        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)

            if url.startAccessingSecurityScopedResource() {
                accessedURL = url
                projectURL = url
                isAccessing = true
            }
        } catch {
            // bookmark 생성 실패 시 직접 URL 사용 (개발 환경)
            projectURL = url
        }
    }

    // 프로젝트 연결 해제
    func stopAccessing() {
        accessedURL?.stopAccessingSecurityScopedResource()
        accessedURL = nil
        isAccessing = false
        projectURL = nil
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    // agents.json 경로 반환
    var agentsConfigURL: URL? {
        projectURL?.appendingPathComponent("team/agents.json")
    }

    deinit {
        accessedURL?.stopAccessingSecurityScopedResource()
    }
}
