# ``RadioKit``

Play internet radio with failover, metadata, artwork, and system media controls.

## Overview

RadioKit provides one observable, main-actor player for iOS and macOS.
It wraps `AVPlayer` and orders each station's stream candidates for failover.

The player publishes timed song metadata, remote artwork, network state, and playback state.
It also integrates with Now Playing information and system media commands.

Apple Music enrichment and App Group synchronization are optional.
The package has no third-party package dependencies.

## Topics

### Start Here

- <doc:GettingStarted>
- <doc:RadioPlayerExample>

### Playback

- <doc:PlaybackAndFailover>
- <doc:MetadataAndArtwork>
- <doc:SystemIntegration>

### State And Design

- <doc:AppGroupSync>
- <doc:PrivacyAndSecurity>
- <doc:Architecture>

### Player

- ``RadioPlayer``
- ``RadioPlayer/PlayerStatus``
- ``RadioPlayer/PlaybackState``
- ``RadioPlayer/NetworkState``
- ``RadioPlayer/PlaybackEvent``

### Models

- ``RadioStation``
- ``RadioStreamCandidate``
- ``RadioArtwork``
- ``RadioSong``

### Synchronization

- ``RadioGroupSynchronizer``
