import Testing

@testable import RadioKit

struct RadioSongTests {
  @MainActor
  @Test func parserPreservesAdditionalHyphensInTitle() throws {
    let parsed = try RadioSong.parse(
      rawMetadata: "The Artist - The Title - Extended Mix"
    )

    #expect(parsed.artist == "The Artist")
    #expect(parsed.title == "The Title - Extended Mix")
  }

  @MainActor
  @Test(
    "Parser rejects empty values",
    arguments: [" - Title", "Artist - ", "   -   "]
  )
  func parserRejectsEmptyValues(rawMetadata: String) {
    #expect(throws: RadioSong.Error.self) {
      try RadioSong.parse(rawMetadata: rawMetadata)
    }
  }
}
