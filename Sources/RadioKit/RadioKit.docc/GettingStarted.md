# Getting Started

Create a station and start internet radio playback.

RadioKit uses Swift tools 6.3 and requires Swift 6.3.3.
It supports iOS 17 or later and macOS 14 or later.
Add the `RadioKit` product to the target that owns playback.

## Create A Station

A ``RadioStation`` contains a canonical stream URL and one or more ``RadioStreamCandidate`` values.
The canonical URL becomes the only candidate when the `streams` array is empty.

```swift
import Foundation
import RadioKit

@MainActor
func playExampleStation() {
  let primaryURL = URL(string: "https://example.com/live-aac")!
  let backupURL = URL(string: "https://example.com/live-mp3")!

  let station = RadioStation(
    id: UUID(),
    name: "Example Radio",
    info: "Live radio",
    streamURL: primaryURL,
    artworkURL: URL(string: "https://example.com/artwork.jpg"),
    streams: [
      RadioStreamCandidate(url: primaryURL, codec: "AAC", rank: 0),
      RadioStreamCandidate(url: backupURL, codec: "MP3", rank: 1),
    ]
  )

  let player = RadioPlayer.shared
  player.station = station
  player.play()
}
```

Call ``RadioPlayer/pause()`` to pause the stream.
Call ``RadioPlayer/togglePlayback()`` when one control must perform both actions.

## Observe State

``RadioPlayer`` uses Observation and runs on the main actor.
SwiftUI views can read its `status`, `playback`, `network`, `songMetadata`, and `artwork` properties directly.

Assign the singleton only from main-actor code.
Do not create another player instance because the public initializer is unavailable.

## Continue Setup

Read <doc:PlaybackAndFailover> before you configure multiple endpoints.
Read <doc:SystemIntegration> before you enable iOS background audio or Apple Music access.
