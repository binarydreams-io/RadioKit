import Testing

import RadioKit

struct RadioKitReleaseTests {
  @Test func versionMatchesRelease() {
    #expect(RadioKitRelease.version == "2.1.0")
  }
}
