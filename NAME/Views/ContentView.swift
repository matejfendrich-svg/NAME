import SwiftUI

/// Jediné hlavní okno aplikace (§4): obsah + přepínač obrazovek v dolním okraji uprostřed.
struct ContentView: View {
    @StateObject private var vm = AppViewModel()
    let appDelegate: AppDelegate
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme { Theme(colorScheme: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                TimelineView(vm: vm)
                    .opacity(vm.screen == .timeline ? 1 : 0)
                    .zIndex(vm.screen == .timeline ? 1 : 0)
                    .allowsHitTesting(vm.screen == .timeline)
                ExportView(vm: vm)
                    .opacity(vm.screen == .export ? 1 : 0)
                    .zIndex(vm.screen == .export ? 1 : 0)
                    .allowsHitTesting(vm.screen == .export)
            }
            .animation(theme.screenAnimation, value: vm.screen) // crossfade 175 ms

            HStack {
                Spacer()
                AppSegmentedControl(selection: $vm.screen, options: [
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
                vm.add(urls: appDelegate.openedFiles)
                appDelegate.openedFiles.removeAll()
            }
        }
        .onChange(of: appDelegate.openedFiles) { files in
            guard !files.isEmpty else { return }
            vm.add(urls: files)
            appDelegate.openedFiles.removeAll()
        }
        .commands {
            CommandMenu(L("menu.screen")) {
                Button(L("screen.timeline")) {
                    vm.screen = .timeline
                }
                .keyboardShortcut("1", modifiers: .command)
                Button(L("screen.export")) {
                    vm.screen = .export
                }
                .keyboardShortcut("2", modifiers: .command)
            }
        }
    }
}
