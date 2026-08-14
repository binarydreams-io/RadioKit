# Architecture

RadioKit publishes one Swift module for iOS and macOS.
Subsystem directories define implementation boundaries without creating more package products.

## Playback Pipeline

1. The host app assigns a `RadioStation` to `RadioPlayer.shared`.
2. The player sorts stream candidates by availability, rank, and original order.
3. A playback request creates an `AVPlayerItem` for the current candidate.
4. `AVPlayer` status observations update the public player state.
5. A failed item produces a `PlaybackEvent` and advances the stream chain.
6. Exhausting the chain changes the player status to `streamFailed`.

A network loss pauses the current attempt without advancing the chain.
The player starts the same candidate again when the path recovers and playback is still requested.

## Metadata And Artwork

An `AVPlayerItemMetadataOutput` receives timed metadata.
RadioKit parses the first `Artist - Title` separator and preserves later separators in the title.

When MusicKit access is authorized, the player requests the first matching Apple Music song.
The match can supply structured song data and artwork.
Without authorization or a result, parsed stream metadata remains available.

Artwork loading uses a dedicated `URLSession` without cookies or credential storage.
Response and image limits bound memory-intensive decoding before platform image creation.

## System Integration

The first valid playback request activates Now Playing information, remote commands, and network monitoring.
On iOS, the same request activates the shared audio session for long-form playback.

Setting the station to `nil` removes remote-command targets, stops network monitoring, clears Now Playing information, and deactivates the iOS audio session.

## State And Concurrency

`RadioPlayer`, `RadioSong`, `RadioArtwork`, and `RadioGroupSynchronizer` use Observation on the main actor.
`RadioStation` and `RadioStreamCandidate` are value types that conform to `Sendable`.

The player stores volume in standard `UserDefaults`.
An optional `RadioGroupSynchronizer` stores the last station and playing flag in an App Group suite.

## Application Boundary

RadioKit owns playback coordination, failover, timed metadata, artwork loading, and system media integration.
The host app owns station catalogs, user interface, entitlements, permissions, analytics, privacy disclosures, and endpoint rights.
