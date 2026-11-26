import SwiftUI

@main
struct NAMEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(appDelegate: appDelegate)
        }
        .defaultSize(width: 980, height: 660)
    }
}
