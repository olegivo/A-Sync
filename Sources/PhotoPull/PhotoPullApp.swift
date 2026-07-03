import SwiftUI

@main
struct PhotoPullApp: App {

    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup("PhotoPull") {
            ContentView()
                .environmentObject(settings)
                .frame(minWidth: 520, minHeight: 460)
        }
        .windowResizability(.contentMinSize)
    }
}
