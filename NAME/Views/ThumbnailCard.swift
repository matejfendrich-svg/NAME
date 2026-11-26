import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Karta miniatury na timeline (§5.2): štítek s číslem, název souboru v monospace,
/// tlačítko „×“ při hoveru a drag-to-reorder.
struct ThumbnailCard: View {
    @Environment(\.theme) private var theme
    let item: PhotoItem
    let index: Int
    let isDragging: Bool
    let onRemove: () -> Void
    let onDragStart: () -> Void
    let onMove: (UUID, Int) -> Void
    @Binding var dropTargetIndex: Int?

    @State private var hovering = false
    @State private var aspect: CGFloat = 1.5

    private let height: CGFloat = 120

    var body: some View {
        let width = max(60, min(height * 2.2, height * aspect))
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                ThumbnailView(url: item.url, height: height)
                    .frame(width: width, height: height)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .onPreferenceChange(AspectRatioKey.self) { aspect = $0 }

                // Štítek s pořadovým číslem — přečísluje se automaticky při každé změně pořadí.
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 11, weight: .bold).monospaced())
                    .foregroundStyle(theme.textInverted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.backgroundInverted)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(6)

                if hovering {
                    HStack {
                        Spacer()
                        Button {
                            onRemove()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .buttonStyle(RemoveButtonStyle())
                    }
                    .padding(6)
                }
            }
            .frame(width: width)

            Text(item.fileName)
                .font(.system(size: 11).monospaced())
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .frame(width: width + 16)
        }
        .frame(width: width)
        // Během tažení se miniatura zvětší a mírně zvedne (§5.2).
        .scaleEffect(isDragging ? 1.06 : 1)
        .shadow(color: Color.primary.opacity(isDragging ? 0.35 : 0), radius: 8, y: 4)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .onHover { hovering = $0 }
        .onDrag {
            onDragStart()
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(of: [.photoItem], delegate: ReorderDropDelegate(index: index, dropTargetIndex: $dropTargetIndex, onMove: onMove))
    }
}

struct ReorderDropDelegate: DropDelegate {
    let index: Int
    @Binding var dropTargetIndex: Int?
    let onMove: (UUID, Int) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.photoItem])
    }

    func dropEntered(info: DropInfo) {
        dropTargetIndex = index
    }

    func dropUpdated(info: DropInfo) -> DropOperation {
        .move
    }

    func dropExited(info: DropInfo) {
        if dropTargetIndex == index {
            dropTargetIndex = nil
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        dropTargetIndex = nil
        guard let provider = info.itemProviders(for: [.photoItem]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { string, _ in
            guard let value = string as? String, let id = UUID(uuidString: value) else { return }
            DispatchQueue.main.async {
                onMove(id, index)
            }
        }
        return true
    }
}
