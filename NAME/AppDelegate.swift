import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    // Soubory otevřené přes Finder „Otevřít s…“ (§5.1, bod 1) předáme do ContentView.
    @Published var openedFiles: [URL] = []

    func application(_ application: NSApplication, openFiles files: [String]) {
        NSApp.reply(toOpenOrPrint: .success)
        openedFiles.append(contentsOf: files.compactMap { URL(fileURLWithPath: $0) })
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        openedFiles.append(contentsOf: urls.filter { $0.isFileURL })
    }
}
