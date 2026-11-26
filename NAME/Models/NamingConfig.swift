import Foundation

enum NumberFormat: String, Codable, CaseIterable, Hashable {
    case plain = "1"
    case twoDigits = "01"
    case threeDigits = "001"
    case fourDigits = "0001"
    case roman = "I"
    case letters = "A"

    var label: String { rawValue }
}

enum NamePosition: String, Codable, CaseIterable, Hashable {
    case numberFirst
    case nameFirst
}

enum NameSeparator: String, Codable, CaseIterable, Hashable {
    // Rozhodnutí dle §2 pravidla 2: specifikace §6.2 ukazuje výstup „01 - Vylet_Praha.jpg“,
    // proto je varianta „spojovník“ reprezentována řetězcem " - " (s mezerami kolem).
    case space = " "
    case dash = " - "
    case underscore = "_"
    case none = ""

    var label: String {
        switch self {
        case .space: return L("config.sep.space")
        case .dash: return L("config.sep.dash")
        case .underscore: return L("config.sep.underscore")
        case .none: return L("config.sep.none")
        }
    }
}

/// Konfigurace pojmenování (§6.2), ukládá se do UserDefaults mezi spuštěními.
struct NamingConfig: Codable, Equatable {
    var baseName: String = ""
    var position: NamePosition = .numberFirst
    var numberFormat: NumberFormat = .twoDigits
    var separator: NameSeparator = .dash
    var startNumber: Int = 1

    /// §9.3: „/“ a „:“ jsou na macOS v názvech souborů nepovolené — nahradí se podtržítkem.
    var sanitizedBaseName: String {
        baseName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBaseNameModified: Bool { sanitizedBaseName != baseName }
    var isValid: Bool { !sanitizedBaseName.isEmpty }

    func numberString(for index: Int) -> String {
        let n = startNumber + index
        switch numberFormat {
        case .plain: return String(max(n, 0))
        case .twoDigits: return String(format: "%02d", max(n, 0))
        case .threeDigits: return String(format: "%03d", max(n, 0))
        case .fourDigits: return String(format: "%04d", max(n, 0))
        case .roman: return Self.roman(n)
        case .letters: return Self.letters(n)
        }
    }

    /// Nový název souboru — přípona zůstává zachována, mění se jen název (§6.4).
    func proposedName(for item: PhotoItem, index: Int) -> String {
        let ext = item.fileExtension.isEmpty ? "" : ".\(item.fileExtension)"
        let num = numberString(for: index)
        let base = sanitizedBaseName
        switch position {
        case .numberFirst: return num + separator.rawValue + base + ext
        case .nameFirst: return base + separator.rawValue + num + ext
        }
    }

    /// Živý náhled v konfiguračním panelu (§6.2).
    func sampleName(index: Int = 0, ext: String = "jpg") -> String {
        let base = sanitizedBaseName.isEmpty ? L("config.sampleBase") : sanitizedBaseName
        let e = ext.isEmpty ? "" : ".\(ext)"
        let num = numberString(for: index)
        switch position {
        case .numberFirst: return num + separator.rawValue + base + e
        case .nameFirst: return base + separator.rawValue + num + e
        }
    }

    private static func roman(_ n: Int) -> String {
        let table: [(Int, String)] = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
            (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
        ]
        var value = max(n, 1)
        var result = ""
        for (v, symbol) in table {
            while value >= v {
                result += symbol
                value -= v
            }
        }
        return result
    }

    private static func letters(_ n: Int) -> String {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var value = max(n, 1)
        var result = ""
        while value > 0 {
            value -= 1
            let idx = alphabet.index(alphabet.startIndex, offsetBy: value % 26)
            result = String(alphabet[idx]) + result
            value /= 26
        }
        return result
    }
}
