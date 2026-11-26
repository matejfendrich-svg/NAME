import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Obrazovka 1: Timeline (§5).
struct TimelineView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.theme) private var theme
    @State private var isFileDragOver = false

    private let thumbnailHeight: CGFloat = 120

    var body: some View {
        FileDropContainer(isTargeted: $isFileDragOver, onFiles: { urls in vm.add(urls: urls) }) {
            VStack(spacing: 0) {
                header
                ZStack {
                    if vm.items.isEmpty {
                        emptyState
                    } else {
                        timelineStrip
                    }
                    if isFileDragOver {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(theme.border, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            .padding(12)
                            .animation(.easeInOut(duration: 0.15), value: isFileDragOver)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(photoCountText(vm.items.count))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Button(L("timeline.sortExif")) {
                Task { await vm.sortByExif() }
            }
            .buttonStyle(BorderedButtonStyle())
            .disabled(vm.items.isEmpty)
            Button(L("timeline.add")) {
                pickFiles()
            }
            .buttonStyle(BorderedButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 16) {
                Text(L("timeline.empty"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                Button(L("timeline.add")) {
                    pickFiles()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dashedBorder(theme.border, cornerRadius: 8)
            .padding(48)
            Spacer()
        }
    }

    private var timelineStrip: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            LazyHStack(alignment: .top, spacing: 12) { // LazyHStack = virtualizace při >200 fotkách (§9.6)
                ForEach(Array(vm.items.enumerated()), id: \.element.id) { index, item in
                    if vm.dropTargetIndex == index {
                        DropSlot(height: thumbnailHeight)
                    }
                    ThumbnailCard(
                        item: item,
                        index: index,
                        isDragging: vm.draggingID == item.id,
                        onRemove: { vm.remove(id: item.id) },
                        onDragStart: { vm.draggingID = item.id },
                        onMove: { id, destination in vm.move(id: id, to: destination) },
                        dropTargetIndex: $vm.dropTargetIndex
                    )
                }
                if vm.dropTargetIndex == vm.items.count {
                    DropSlot(height: thumbnailHeight)
                }
            }
            .padding(24)
        }
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = UTType.supportedImageTypes
        panel.prompt = L("timeline.add")
        if panel.runModal() == .OK {
            vm.add(urls: panel.urls)
        }
    }
}
