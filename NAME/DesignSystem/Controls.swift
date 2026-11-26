import SwiftUI
import AppKit

// MARK: - Kurzor ukazovátka nad klikatelnými prvky (§3.2)

struct PointingHandModifier: ViewModifier {
    @State private var hovering = false

    func body(content: Content) -> some View {
        content.onHover { hovering in
            self.hovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func pointingHand() -> some View {
        modifier(PointingHandModifier())
    }
}

// MARK: - Tečkovaný obrys (drop cíl, prázdný stav, slot při řazení)

struct DashedBorderModifier: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(color, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        )
    }
}

extension View {
    func dashedBorder(_ color: Color, cornerRadius: CGFloat = 8) -> some View {
        modifier(DashedBorderModifier(color: color, cornerRadius: cornerRadius))
    }
}

// MARK: - Tlačítka (§3.2: idle / hover / pressed, animace 150 ms)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        let hoverInverted = hovering && !configuration.isPressed
        return configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(!isEnabled ? theme.textSecondary : (hoverInverted ? theme.textPrimary : theme.textInverted))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(!isEnabled ? theme.surface : (hoverInverted ? theme.background : theme.backgroundInverted))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isEnabled ? theme.border : theme.textSecondary, lineWidth: hoverInverted ? 2 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.7)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .onHover { hovering = $0 }
            .pointingHand()
    }
}

struct BorderedButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isEnabled ? theme.textPrimary : theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(!isEnabled ? theme.surface : (hovering ? theme.surface : theme.background))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isEnabled ? theme.border : theme.textSecondary, lineWidth: (hovering && !configuration.isPressed) ? 2 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.7)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .onHover { hovering = $0 }
            .pointingHand()
    }
}

/// Malé kulaté tlačítko s křížkem pro odebrání z timeline (§5.2).
struct RemoveButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        let inverted = hovering && !configuration.isPressed
        return configuration.label
            .foregroundStyle(inverted ? theme.textPrimary : theme.textInverted)
            .frame(width: 20, height: 20)
            .background(Circle().fill(inverted ? theme.background : theme.backgroundInverted))
            .overlay(Circle().stroke(theme.border, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .onHover { hovering = $0 }
            .pointingHand()
    }
}

// MARK: - Segmentový ovladač ve stylu černá na bílé (§4, §6.2)

struct SegmentButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    let isSelected: Bool
    let hovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? theme.textInverted : theme.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? theme.backgroundInverted : (hovered ? theme.surface : theme.background))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: hovered)
    }
}

struct AppSegmentedControl<T: Hashable>: View {
    @Environment(\.theme) private var theme
    @Binding var selection: T
    let options: [(value: T, title: String)]
    @State private var hovered: T?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = option.value
                    }
                } label: {
                    Text(option.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SegmentButtonStyle(isSelected: selection == option.value, hovered: hovered == option.value))
                .onHover { hovering in
                    if hovering {
                        hovered = option.value
                    } else if hovered == option.value {
                        hovered = nil
                    }
                }
                .pointingHand()
            }
        }
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Vyhrazené místo (slot) při drag-to-reorder (§5.2)

struct DropSlot: View {
    @Environment(\.theme) private var theme
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(theme.border, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .frame(width: 24, height: height + 28)
    }
}
