import Foundation

/// Položka timeline: odkaz na soubor na disku. Pořadí je dáno pozicí v poli `AppViewModel.items`.
struct PhotoItem: Identifiable, Equatable {
    let id: UUID
    var url: URL

    var fileName: String { url.lastPathComponent }
    var fileExtension: String { url.pathExtension }

    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
    }
}
