import Foundation
import Testing

@testable import RadioKit

struct RadioStationTests {
  @Test func initializerCreatesDefaultStreamCandidate() throws {
    let streamURL = try #require(URL(string: "https://example.com/radio"))
    let station = RadioStation(
      id: UUID(),
      name: "Example Radio",
      info: nil,
      streamURL: streamURL,
      artworkURL: nil
    )

    #expect(station.streams == [RadioStreamCandidate(url: streamURL)])
  }

  @Test func decodingAllowsMissingOptionalFieldsAndStreams() throws {
    let data = Data(
      #"{"id":"9B49455B-EF2B-4D3C-86B2-52D211A06E5F","name":"Example Radio","streamURL":"https:\/\/example.com\/radio"}"#
        .utf8
    )

    let station = try JSONDecoder().decode(RadioStation.self, from: data)

    #expect(station.info == nil)
    #expect(station.artworkURL == nil)
    #expect(station.streams == [RadioStreamCandidate(url: station.streamURL)])
  }

  @Test func decodingRejectsMalformedOptionalField() {
    let data = Data(
      #"{"id":"9B49455B-EF2B-4D3C-86B2-52D211A06E5F","name":"Example Radio","info":42,"streamURL":"https:\/\/example.com\/radio"}"#
        .utf8
    )

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(RadioStation.self, from: data)
    }
  }

  @Test func decodingRejectsMalformedStreamsField() {
    let data = Data(
      #"{"id":"9B49455B-EF2B-4D3C-86B2-52D211A06E5F","name":"Example Radio","streamURL":"https:\/\/example.com\/radio","streams":"invalid"}"#
        .utf8
    )

    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(RadioStation.self, from: data)
    }
  }
}
