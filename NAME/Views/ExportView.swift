import SwiftUI

/// Obrazovka 2: Export (§6) — fluid grid náhled, konfigurace pojmenování,
/// tabulka přejmenování a provedení operace.
struct ExportView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.theme) private var theme

    private let previewThumbHeight: CGFloat = 64
    private let minPreviewCell: CGFloat = 150

    var body: some View {
        Group {
            if vm.items.isEmpty {
                emptyState
            } else if let outcome = vm.result {
                CompletionView(vm: vm, outcome: outcome)
            } else {
                mainContent
            }
        }
    }

    // §9.1: prázdná timeline — výzva k návratu na Timeline.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(L("export.empty"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
            Button(L("export.backToTimeline")) {
                vm.screen = .timeline
            }
            .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                previewGrid
                ConfigPanel(vm: vm)
                RenameTable(vm: vm)
                if let notice = vm.notice {
                    Text(notice)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                AppSegmentedControl(selection: $vm.renameMode, options: [
                    (.inPlace, L("export.mode.inPlace")),
                    (.copyToFolder, L("export.mode.copy")),
                ])
                if vm.renameMode == .copyToFolder {
                    Button(vm.copyDestination?.lastPathComponent ?? L("export.chooseFolder")) {
                        vm.chooseCopyFolder()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    if vm.copyDestination == nil {
                        Text(L("export.folderNone"))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.danger)
                    }
                }
                Spacer()
                renameButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(theme.background)
            .overlay(
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1),
                alignment: .top
            )
        }
    }

    /// §6.1: celá timeline najednou — miniatury se automaticky zmenší, aby se vešly na šířku okna.
    /// Aktualizuje se v reálném čase při každé změně konfigurace.
    private var previewGrid: some View {
        GeometryReader { geometry in
            let available = geometry.size.width
            let columns = max(1, Int(available / minPreviewCell))
            let cellWidth = (available - CGFloat(columns - 1) * 12) / CGFloat(columns)
            let rowCount = Int(ceil(Double(vm.rows.count) / Double(columns)))
            let cellHeight = previewThumbHeight + 30

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: 12), count: columns),
                spacing: 12
            ) {
                ForEach(vm.rows) { row in
                    let item = vm.items[row.index]
                    VStack(spacing: 4) {
                        ThumbnailView(url: item.url, height: previewThumbHeight)
                            .frame(width: cellWidth, height: previewThumbHeight)
                            .background(theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(row.collides ? theme.danger : theme.border, lineWidth: 1)
                            )
                        Text(row.proposedName)
                            .font(.system(size: 10).monospaced())
                            .foregroundStyle(row.collides ? theme.danger : theme.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: CGFloat(rowCount) * cellHeight + CGFloat(max(rowCount - 1, 0)) * 12)
        }
    }

    /// §6.4: černé tlačítko v pravé dolní části; během operace indikátor průběhu, neaktivní.
    private var renameButton: some View {
        Button {
            Task { await vm.runRename() }
        } label: {
            HStack(spacing: 8) {
                if vm.isRenaming, let progress = vm.renameProgress {
                    ProgressView()
                        .controlSize(.small)
                    Text("\(L("export.renaming")) \(progress.done)/\(progress.total)")
                } else {
                    Text(L("export.rename"))
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!vm.canRename)
    }
}
