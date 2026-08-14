import Foundation
import Observation
import Testing

@testable import RadioKit

struct RadioGroupSynchronizerTests {
  @MainActor
  @Test func playbackStateIsObservableAndWritesAreIdempotent() async throws {
    let suiteName = "RadioGroupSynchronizerTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var reloadCount = 0
    let synchronizer = RadioGroupSynchronizer(defaults: defaults) {
      reloadCount += 1
    }

    await confirmation("Playback observation fires once") { observed in
      withObservationTracking {
        _ = synchronizer.isPlaying
      } onChange: {
        observed()
      }

      synchronizer.setPlaying(true)
    }

    #expect(synchronizer.isPlaying)
    #expect(defaults.bool(forKey: "isPlayingNow"))
    #expect(reloadCount == 1)

    synchronizer.setPlaying(true)
    #expect(reloadCount == 1)
  }

  @MainActor
  @Test func stationWritesAreCachedAndIdempotent() throws {
    let suiteName = "RadioGroupSynchronizerTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var reloadCount = 0
    let synchronizer = RadioGroupSynchronizer(defaults: defaults) {
      reloadCount += 1
    }
    let station = RadioStation(
      id: UUID(),
      name: "Example Radio",
      info: nil,
      streamURL: try #require(URL(string: "https://example.com/radio")),
      artworkURL: nil
    )

    synchronizer.setLastStation(station)
    #expect(synchronizer.lastRadioStation == station)
    #expect(reloadCount == 1)

    synchronizer.setLastStation(station)
    #expect(reloadCount == 1)

    let restored = RadioGroupSynchronizer(defaults: defaults) {}
    #expect(restored.lastRadioStation == station)
  }
}
