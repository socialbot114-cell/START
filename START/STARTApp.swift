import SwiftUI

@main
struct STARTApp: App {
    @StateObject private var players = PlayerStore()

    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ContentView()
                        .environmentObject(players)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .preferredColorScheme(.dark)
        }
    }
}
