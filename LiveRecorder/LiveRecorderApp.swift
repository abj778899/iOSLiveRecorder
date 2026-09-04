import SwiftUI

@main
struct LiveRecorderApp: App {
    @StateObject private var viewModel = AnchorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
