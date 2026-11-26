import Foundation
import AppKit
import Combine

enum Screen: Hashable {
    case timeline
    case export
}

enum RenameMode: Hashable {
    case inPlace
    case copyToFolder
}

/// Hlavní stav aplikace (MVVM, §8). Stav přetrvává při přepínání obrazovek.
@MainActor
final class AppViewModel: ObservableObject {
    @Published var items: [PhotoItem] = [] { didSet { recomputeRows() } }
    @Published var screen: Screen = .timeline
    @Published var config: NamingConfig { didSet { saveConfig(); recomputeRows() } }
    @Published var rows: [RenameRow] = []
    @Published var renameMode: RenameMode = .inPlace { didSet { recomputeRows() } }
    @Published var copyDestination: URL? { didSet { recomputeRows() } }
    @Published var isRenaming = false
    @Published var renameProgress: (done: Int, total: Int)?
    @Published var result: RenameOutcome?
    @Published var notice: String?
    @Published var draggingID: UUID?
    @Published var dropTargetIndex: Int?

    private(set) var lastRename: [(from: URL, to: URL)] = []

    private let defaultsKey = "cz.matejfendrich-svg.NAME.namingConfig"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(NamingConfig.self, from: data) {
            _config = Published(initialValue: decoded)
        } else {
            _config = Published(initialValue: NamingConfig())
        }
    }

    // MARK: - Vkládání souborů (§5.1)

    /// Přidá soubory na konec timeline; duplicity (stejná cesta) se zahodí.
    func add(urls: [URL]) {
        var known = Set(items.map { $0.url.standardizedFileURL.path })
        for url in urls {
            guard UTType.supportedExtensions.contains(url.pathExtension.lowercased()) else { continue }
            let path = url.standardizedFileURL.path
            guard !known.contains(path) else { continue }
            known.insert(path)
            items.append(PhotoItem(url: url.standardizedFileURL))
        }
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    // MARK: - Řazení (§5.2)

    func move(id: UUID, to destination: Int) {
        guard let from = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: from)
        let adjusted = destination > from ? destination - 1 : destination
        items.insert(item, at: min(max(adjusted, 0), items.count))
        dropTargetIndex = nil
        draggingID = nil
    }

    /// „Seřadit dle EXIF“ — stabilní řazení podle data pořízení; soubory bez data zůstanou na konci.
    /// Čtení EXIF běží mimo hlavní vlákno, aby UI zůstalo plynulé i u stovek fotek.
    func sortByExif() async {
        let snapshot = items
        let decorated = await Task.detached(priority: .userInitiated) {
            snapshot.enumerated().map { (index: $0.offset, item: $0.element, date: ExifDateProvider.date(for: $0.element.url)) }
        }.value
        let sorted = decorated.sorted { lhs, rhs in
            switch (lhs.date, rhs.date) {
            case let (l?, r?): return l < r
            case (nil, nil): return lhs.index < rhs.index
            case (nil, _): return false
            case (_, nil): return true
            }
        }
        items = sorted.map { $0.item }
        dropTargetIndex = nil
        draggingID = nil
    }

    // MARK: - Návrhy názvů a kolize (§6.2, §6.3, §9.4)

    private func recomputeRows() {
        let fileManager = FileManager.default
        var destCounts: [String: Int] = [:]
        var destPaths: [String] = []
        var names: [String] = []
        for (index, item) in items.enumerated() {
            let name = config.proposedName(for: item, index: index)
            let directory: URL
            if renameMode == .copyToFolder, let copyDestination {
                directory = copyDestination
            } else {
                directory = item.url.deletingLastPathComponent()
            }
            let dest = directory.appendingPathComponent(name).standardizedFileURL.path
            destCounts[dest, default: 0] += 1
            destPaths.append(dest)
            names.append(name)
        }
        let ownPaths = Set(items.map { $0.url.standardizedFileURL.path })
        rows = items.enumerated().map { index, item in
            // Kolize: stejný cílový název vícekrát, nebo existující soubor mimo tuto operaci.
            let collides = (destCounts[destPaths[index]] ?? 0) > 1
                || (fileManager.fileExists(atPath: destPaths[index]) && !ownPaths.contains(destPaths[index]))
            return RenameRow(
                id: item.id,
                index: index,
                currentName: item.fileName,
                proposedName: names[index],
                collides: collides
            )
        }
    }

    var canRename: Bool {
        guard !items.isEmpty, !isRenaming, config.isValid, !rows.contains(where: { $0.collides }) else { return false }
        if renameMode == .copyToFolder {
            return copyDestination != nil
        }
        return true
    }

    // MARK: - Provedení přejmenování (§6.4)

    func chooseCopyFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = L("export.chooseFolder")
        if panel.runModal() == .OK {
            copyDestination = panel.urls.first
        }
    }

    func runRename() async {
        guard canRename else { return }
        isRenaming = true
        renameProgress = (0, items.count)
        notice = nil
        let snapshot = items
        let proposals = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.proposedName) })
        let mode = renameMode
        let destination = copyDestination
        let outcome = await Task.detached(priority: .userInitiated) {
            RenameService.perform(items: snapshot, proposals: proposals, mode: mode, destination: destination) { done, total in
                Task { @MainActor in
                    self.renameProgress = (done, total)
                }
            }
        }.value
        lastRename = outcome.renamed
        if mode == .inPlace {
            for move in outcome.renamed {
                if let index = items.firstIndex(where: { $0.url.standardizedFileURL.path == move.from.standardizedFileURL.path }) {
                    items[index].url = move.to
                }
            }
        }
        result = outcome
        renameProgress = nil
        isRenaming = false
    }

    /// Undo (§11, ot. 5): vrátí původní názvy po přejmenování na místě.
    func undoLastRename() async {
        let moves = lastRename
        guard !moves.isEmpty else { return }
        let failures = await Task.detached(priority: .userInitiated) {
            RenameService.undo(moves: moves)
        }.value
        for move in moves {
            if let index = items.firstIndex(where: { $0.url.standardizedFileURL.path == move.to.standardizedFileURL.path }) {
                items[index].url = move.from
            }
        }
        notice = failures.isEmpty
            ? L("undo.done")
            : String(format: L("undo.partial"), failures.count)
    }

    /// „Zpět na Timeline“ po dokončení (§6.4): vyčistí relaci.
    func backToTimeline() {
        items = []
        result = nil
        notice = nil
        lastRename = []
        draggingID = nil
        dropTargetIndex = nil
        screen = .timeline
    }

    // MARK: - Persistence konfigurace (§6.2)

    private func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
