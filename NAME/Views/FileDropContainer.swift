import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Kontejner, který přijímá soubory přetažené z Finderu (§5.1, bod 2).
/// Cílem pro puštění je celá plocha obrazovky Timeline; během tažení se zvýrazní tečkovaným obrysem.
/// Vnitřní drag-to-reorder používá vlastní UTType a tímto kontejnerem prochází nedotčeně.
struct FileDropContainer<Content: View>: NSViewRepresentable {
    @Binding var isTargeted: Bool
    let onFiles: ([URL]) -> Void
    let content: Content

    func makeNSView(context: Context) -> DropContainerView {
        let view = DropContainerView()
        view.onFiles = onFiles
        view.onTargetedChange = { isTargeted = $0 }
        let hosting = NSHostingView(rootView: AnyView(content))
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = view.bounds
        view.addSubview(hosting)
        view.hostingView = hosting
        return view
    }

    func updateNSView(_ nsView: DropContainerView, context: Context) {
        nsView.onFiles = onFiles
        nsView.onTargetedChange = { isTargeted = $0 }
        nsView.hostingView?.rootView = AnyView(content)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {}
}

final class DropContainerView: NSView {
    var hostingView: NSHostingView<AnyView>?
    var onFiles: ([URL]) -> Void = { _ in }
    var onTargetedChange: (Bool) -> Void = { _ in }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([UTType.fileURL.identifier])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([UTType.fileURL.identifier])
    }

    private func containsFileURL(_ info: NSDraggingInfo) -> Bool {
        info.draggingPasteboard.types.contains(UTType.fileURL.identifier)
    }

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard containsFileURL(sender) else { return [] }
        onTargetedChange(true)
        return .copy
    }

    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        containsFileURL(sender) ? .copy : []
    }

    func draggingExited(_ sender: NSDraggingInfo?) {
        onTargetedChange(false)
    }

    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        true
    }

    func performDrop(_ sender: NSDraggingInfo) -> Bool {
        onTargetedChange(false)
        var urls: [URL] = []
        for item in sender.draggingPasteboard.pasteboardItems ?? [] {
            if let string = item.string(forType: UTType.fileURL.identifier),
               let url = URL(string: string),
               url.isFileURL {
                urls.append(url)
            }
        }
        guard !urls.isEmpty else { return false }
        onFiles(urls)
        return true
    }
}
