import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var scene: GameScene = {
        let scene = GameScene(size: CGSize(width: 752, height: 512))
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, preferredFramesPerSecond: 60)
            .ignoresSafeArea()
            #if os(iOS)
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
            #endif
    }
}

#Preview {
    ContentView()
}
