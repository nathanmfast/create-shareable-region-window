import SwiftUI

@main
struct CreateShareableRegionWindowApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Create Shareable Region Window") {
            ContentView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
    }
}
