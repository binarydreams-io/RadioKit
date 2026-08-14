# App Group Sync

Share the last station and playing flag with widgets or app extensions.

``RadioGroupSynchronizer`` stores a small playback snapshot in an App Group `UserDefaults` suite.
It exposes the stored station and playing flag through Observation.

## Configure The Suite

Enable the same App Group capability for the app and each extension.
Create a synchronizer with the exact suite identifier, then attach it to the player.

```swift
import RadioKit

@MainActor
func configureSharedPlaybackState() {
  let synchronizer = RadioGroupSynchronizer(
    suiteName: "group.com.example.radio"
  )
  RadioPlayer.shared.groupSynchronizer = synchronizer
}
```

After attachment, the player stores a selected station and changes to the playing flag.
Each changed value requests a reload of all WidgetKit timelines.

An extension can create its own synchronizer with the same suite name.
Read ``RadioGroupSynchronizer/lastRadioStation`` and ``RadioGroupSynchronizer/isPlaying`` from that instance.

## Data Boundary

The synchronizer stores a JSON-encoded ``RadioStation`` and one Boolean value.
It does not share an `AVPlayer`, audio-session state, live metadata, or downloaded artwork.

If the suite name is invalid or unavailable, the synchronizer keeps default values and cannot persist changes.
RadioKit logs encoding and decoding failures without exposing an error property.
