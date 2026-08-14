import MusicKit
import RadioKit
import SwiftUI

@main
@MainActor
struct RadioPlayerApp: App {
  var body: some Scene {
    WindowGroup {
      FullPlayer()
        .task {
          _ = await MusicAuthorization.request()

          let player = RadioKit.RadioPlayer.shared
          guard player.station == nil else { return }

          player.station = DemoStation.recordRock
          player.play()
        }
    }
  }
}
