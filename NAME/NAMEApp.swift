import SwiftUI

@main
struct NAMEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, appDelegate: appDelegate)
        }
        .defaultSize(width: 980, height: 660)
        .commands {
            // §4: Cmd+1 = Timeline, Cmd+2 = Export
            CommandMenu(L("menu.screen")) {
                Button(L("screen.timeline")) {
                    viewModel.screen = .timeline
                }
                .keyboardShortcut("1", modifiers: .command)
                Button(L("screen.export")) {
                    viewModel.screen = .export
                }
                .keyboardShortcut("2", modifiers: .command)
            }
        }
    }
}
