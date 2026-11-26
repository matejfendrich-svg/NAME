import Foundation

/// Řádek tabulky přejmenování (§6.3).
struct RenameRow: Identifiable, Equatable {
    let id: UUID
    let index: Int
    let currentName: String
    let proposedName: String
    var collides: Bool
}
