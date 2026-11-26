import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Design systém dle specifikace §3.1 — výhradně černá, bílá a odstíny šedé,
/// jediná povolená barva je `danger` (#D40000) pro chyby a kolize názvů.
/// Uživatel rozhodl (spec §11, ot. 1): v tmavém režimu macOS se paleta invertuje.
struct Theme {
    let colorScheme: ColorScheme
    private var isDark: Bool { colorScheme == .dark }

    var background: Color { isDark ? Color(hex: 0x000000) : Color(hex: 0xFFFFFF) }
    var backgroundInverted: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x000000) }
    var surface: Color { isDark ? Color(hex: 0x1A1A1A) : Color(hex: 0xF5F5F5) }
    var border: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x000000) }
    var textPrimary: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x000000) }
    var textSecondary: Color { isDark ? Color(hex: 0x666666) : Color(hex: 0x999999) }
    var textInverted: Color { isDark ? Color(hex: 0x000000) : Color(hex: 0xFFFFFF) }
    var danger: Color { Color(hex: 0xD40000) }

    /// §3.2: všechny přechody stavů 120–180 ms.
    var stateAnimation: Animation { .easeInOut(duration: 0.15) }
    /// §4: crossfade mezi obrazovkami 150–200 ms.
    var screenAnimation: Animation { .easeInOut(duration: 0.175) }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(colorScheme: .light)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func themed(_ colorScheme: ColorScheme) -> some View {
        environment(\.theme, Theme(colorScheme: colorScheme))
    }
}
