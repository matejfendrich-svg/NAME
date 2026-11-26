import Foundation

struct RenameFailure: Identifiable {
    let id = UUID()
    let fileName: String
    let message: String
}

struct RenameOutcome: Identifiable {
    let id = UUID()
    let mode: RenameMode
    let renamed: [(from: URL, to: URL)]
    let failures: [RenameFailure]
}

/// Přejmenování přes FileManager (§8, §6.4). Mění se výhradně názvy souborů,
/// obsah ani přípony se nikdy neupravují. Soubory zůstávají ve svých složkách
/// (režim inPlace), nebo se zkopírují do zvolené složky (režim copyToFolder — uživatel zvolil, spec §11, ot. 3).
enum RenameService {
    static func perform(
        items: [PhotoItem],
        proposals: [UUID: String],
        mode: RenameMode,
        destination: URL?,
        progress: (Int, Int) -> Void
    ) -> RenameOutcome {
        let fileManager = FileManager.default
        var renamed: [(from: URL, to: URL)] = []
        var failures: [RenameFailure] = []
        // Dvoufázové přejmenování: nejprve do dočasných unikátních názvů, pak do finálních,
        // aby nezáleželo na pořadí a nevznikly kolize uvnitř samotné operace.
        var pendingMoves: [(tmp: URL, dest: URL, originalName: String)] = []

        for (index, item) in items.enumerated() {
            guard let newName = proposals[item.id] else { continue }
            let directory: URL
            if mode == .copyToFolder, let destination {
                directory = destination
            } else {
                directory = item.url.deletingLastPathComponent()
            }
            let dest = directory.appendingPathComponent(newName)

            if mode == .inPlace, dest.standardizedFileURL.path == item.url.standardizedFileURL.path {
                // Název se nemění — přeskočit, nezapočítávat jako chybu.
                progress(index + 1, items.count)
                continue
            }

            let didAccess = item.url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    item.url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                switch mode {
                case .inPlace:
                    let tmp = directory.appendingPathComponent(".NAME-tmp-\(UUID().uuidString)")
                    try fileManager.moveItem(at: item.url, to: tmp)
                    pendingMoves.append((tmp, dest, item.fileName))
                    renamed.append((item.url, dest))
                case .copyToFolder:
                    try fileManager.copyItem(at: item.url, to: dest)
                    renamed.append((item.url, dest))
                }
            } catch {
                // §9.5: selhání jednoho souboru nenaruší zbytek.
                failures.append(RenameFailure(fileName: item.fileName, message: error.localizedDescription))
            }
            progress(index + 1, items.count)
        }

        for move in pendingMoves {
            do {
                try fileManager.moveItem(at: move.tmp, to: move.dest)
            } catch {
                failures.append(RenameFailure(fileName: move.originalName, message: error.localizedDescription))
            }
        }

        return RenameOutcome(mode: mode, renamed: renamed, failures: failures)
    }

    /// Undo po přejmenování (uživatel zvolil — spec §11, ot. 5): vrátí původní názvy.
    static func undo(moves: [(from: URL, to: URL)]) -> [RenameFailure] {
        let fileManager = FileManager.default
        var failures: [RenameFailure] = []
        for move in moves.reversed() {
            let didAccess = move.to.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    move.to.stopAccessingSecurityScopedResource()
                }
            }
            do {
                try fileManager.moveItem(at: move.to, to: move.from)
            } catch {
                failures.append(RenameFailure(fileName: move.to.lastPathComponent, message: error.localizedDescription))
            }
        }
        return failures
    }
}
