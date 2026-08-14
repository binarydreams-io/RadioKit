import Foundation
import RadioKit

guard let streamURL = URL(string: "https://radio.example/live") else {
  fatalError("The fixture stream URL is invalid")
}

let stream = RadioStreamCandidate(url: streamURL, codec: "AAC", rank: 0)
let station = RadioStation(
  id: UUID(),
  name: "Fixture Radio",
  info: "Compile fixture",
  streamURL: streamURL,
  artworkURL: nil,
  streams: [stream]
)

print("RadioKit consumer: \(station.name) uses \(station.streams.count) stream")
print(RadioKitRelease.version)
