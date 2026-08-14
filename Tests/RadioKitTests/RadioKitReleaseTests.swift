import Testing

import RadioKit

struct RadioKitReleaseTests {
  @Test func versionMatchesRelease() {
    #expect(RadioKitRelease.version == "1.0.0")
  }
}
