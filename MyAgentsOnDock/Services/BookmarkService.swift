import AppKit
import Foundation

// Security-Scoped Bookmarks로 프로젝트 폴더 접근 권한 관리
@MainActor
class BookmarkService: ObservableObject {
    static let shared = BookmarkService()

    private let bookmarkKey = "projectBookmark"
    private var accessingURL: URL?

    @Published var projectURL: URL? = nil

    init() {
        resolveBookmark()
    }

    // NSOpenPanel로 프로젝트 폴더 선택
    func selectProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "선택"
        panel.message = "Claude Code 팀 프로젝트 폴더를 선택하세요"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        saveBookmark(for: url)
    }

    // 북마크 저장
    private func saveBookmark(for url: URL) {
        // 기존 접근 중인 URL 해제
        stopAccessing()

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
            AppSettings.shared.lastProjectPath = url.path
            startAccessing(url: url)
        } catch {
            print("[BookmarkService] 북마크 저장 실패: \(error)")
        }
    }

    // 저장된 북마크 복원
    private func resolveBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                // 북마크가 만료된 경우 재저장
                saveBookmark(for: url)
            } else {
                startAccessing(url: url)
            }
        } catch {
            print("[BookmarkService] 북마크 복원 실패: \(error)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    // Security-Scoped Resource 접근 시작
    private func startAccessing(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("[BookmarkService] Security-Scoped Resource 접근 실패")
            return
        }
        accessingURL = url
        projectURL = url
    }

    // Security-Scoped Resource 접근 중단
    func stopAccessing() {
        accessingURL?.stopAccessingSecurityScopedResource()
        accessingURL = nil
    }

    // 북마크 삭제 (프로젝트 연결 해제)
    func clearBookmark() {
        stopAccessing()
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        AppSettings.shared.lastProjectPath = ""
        projectURL = nil
    }

    deinit {
        accessingURL?.stopAccessingSecurityScopedResource()
    }
}
