import AppKit
import Foundation

// Manage project folder access permissions using Security-Scoped Bookmarks
@MainActor
class BookmarkService: ObservableObject {
    static let shared = BookmarkService()

    private let bookmarkKey = "projectBookmark"
    private var accessingURL: URL?

    @Published var projectURL: URL? = nil

    init() {
        resolveBookmark()
    }

    // Select project folder via NSOpenPanel
    func selectProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = "Select your Claude Code team project folder"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        saveBookmark(for: url)
    }

    // Save bookmark
    private func saveBookmark(for url: URL) {
        // Release currently accessed URL
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
            print("[BookmarkService] Failed to save bookmark: \(error)")
        }
    }

    // Restore saved bookmark
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
                // Bookmark is stale — re-save
                saveBookmark(for: url)
            } else {
                startAccessing(url: url)
            }
        } catch {
            print("[BookmarkService] Failed to restore bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    // Start accessing Security-Scoped Resource
    private func startAccessing(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("[BookmarkService] Failed to access Security-Scoped Resource")
            return
        }
        accessingURL = url
        projectURL = url
    }

    // Stop accessing Security-Scoped Resource
    func stopAccessing() {
        accessingURL?.stopAccessingSecurityScopedResource()
        accessingURL = nil
    }

    // Delete bookmark (disconnect project)
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
