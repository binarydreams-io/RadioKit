import Foundation
import RadioKit

enum DemoStation {
  static let recordRock: RadioStation = {
    guard
      let id = UUID(uuidString: "2ADAC7FA-2D8F-4D30-A367-3AFFA79805D3"),
      let streamURL = URL(string: "https://radiorecord.hostingradio.ru/rock96.aacp"),
      let artworkURL = URL(
        string: "https://cdn.radiotuna.app/images/stations/a40bb597-3f5f-4ae5-a33d-c9f548492c26.webp"
      )
    else {
      fatalError("The demo station constants must contain valid URLs and a valid UUID.")
    }

    return RadioStation(
      id: id,
      name: "Record Rock Radio",
      info: "Live rock radio",
      streamURL: streamURL,
      artworkURL: artworkURL,
      streams: [
        RadioStreamCandidate(
          url: streamURL,
          codec: "AAC",
          rank: 1
        )
      ]
    )
  }()
}
