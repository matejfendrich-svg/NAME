import SwiftUI
import AppKit

struct AspectRatioKey: PreferenceKey {
    static var defaultValue: CGFloat = 1.5
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Miniatura načtená asynchronně přes ImageIO (ThumbnailProvider), aby UI neblokovalo (§8).
struct ThumbnailView: View {
    @Environment(\.theme) private var theme
    let url: URL
    let height: CGFloat

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                let ratio = image.size.width / max(image.size.height, 1)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit) // letterbox u nestandardních poměrů (§5.2)
                    .preference(key: AspectRatioKey.self, value: ratio)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: height * 0.3))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .frame(height: height)
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        // 2x retina + rezerva
        let pixels = Int(height * 4)
        let image = await Task.detached(priority: .utility) {
            ThumbnailProvider.shared.thumbnail(for: url, maxPixelSize: pixels)
        }.value
        await MainActor.run {
            self.image = image
        }
    }
}
