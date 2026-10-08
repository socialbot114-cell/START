import SwiftUI

@main
struct STARTApp: App {
    @StateObject private var players = PlayerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(players)
                .frame(
                    width: UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale,
                    height: UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background.ignoresSafeArea())
                .preferredColorScheme(.dark)
        }
    }
}
