import SwiftUI
import UIKit

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
                .onAppear(perform: fillSimulatorScene)
        }
    }

    @MainActor
    private func fillSimulatorScene() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        let screenSize = scene.screen.bounds.size
        scene.sizeRestrictions?.minimumSize = screenSize
        scene.sizeRestrictions?.maximumSize = screenSize
        scene.windows.first?.frame = scene.screen.bounds
    }
}
