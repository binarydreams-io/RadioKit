import Testing

@testable import RadioKit

struct RadioPlayerTests {
  @Test(
    "Volume normalization",
    arguments: [
      (Float.nan, Float(0)),
      (-Float.infinity, Float(0)),
      (Float(-0.5), Float(0)),
      (Float(0.5), Float(0.5)),
      (Float(1.5), Float(1)),
      (Float.infinity, Float(1)),
    ]
  )
  @MainActor
  func normalizesVolume(value: Float, expected: Float) {
    #expect(RadioPlayer.normalizedVolume(value) == expected)
  }
}
