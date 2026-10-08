import SwiftUI

@main
struct STARTApp: App {
    @StateObject private var players = PlayerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(players)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.ignoresSafeArea())
                .preferredColorScheme(.dark)
        }
    }
}
