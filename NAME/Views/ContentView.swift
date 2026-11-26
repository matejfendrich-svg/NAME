import SwiftUI

/// Jediné hlavní okno aplikace (§4): obsah + přepínač obrazovek v dolním okraji uprostřed.
struct ContentView: View {
    let viewModel: AppViewModel
    let appDelegate: AppDelegate
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                TimelineView(vm: viewModel)
                    .opacity(viewModel.screen == .timeline ? 1 : 0)
                    .zIndex(viewModel.screen == .timeline ? 1 : 0)
                    .allowsHitTesting(viewModel.screen == .timeline)
                ExportView(vm: viewModel)
                    .opacity(viewModel.screen == .export ? 1 : 0)
                    .zIndex(viewModel.screen == .export ? 1 : 0)
                    .allowsHitTesting(viewModel.screen == .export)
            }
            .animation(theme.screenAnimation, value: viewModel.screen) // crossfade 175 ms

            HStack {
                Spacer()
                AppSegmentedControl(selection: $viewModel.screen, options: [
                    (.timeline, L("screen.timeline")),
                    (.export, L("screen.export")),
                ])
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(theme.background.ignoresSafeArea())
        .themed(colorScheme)
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            if !appDelegate.openedFiles.isEmpty {
                viewModel.add(urls: appDelegate.openedFiles)
                appDelegate.openedFiles.removeAll()
            }
        }
        .onChange(of: appDelegate.openedFiles) { files in
            guard !files.isEmpty else { return }
            viewModel.add(urls: files)
            appDelegate.openedFiles.removeAll()
        }
    }
}
