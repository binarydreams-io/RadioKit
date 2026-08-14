# Architecture

Follow a playback request from station selection to system output.

RadioKit publishes one module.
It uses Apple frameworks for playback, networking, Observation, media controls, MusicKit, images, and widgets.

## Player Ownership

``RadioPlayer`` is a main-actor singleton that owns one `AVPlayer`.
It also owns the active player item, stream chain, status observers, metadata output, and optional App Group synchronizer.

The singleton keeps process-wide Now Playing and remote-command state consistent with one playback session.
This design does not support independent simultaneous players.

## Playback Flow

1. The host assigns a ``RadioStation``.
2. The player creates an ordered chain from ``RadioStation/streams``.
3. ``RadioPlayer/play()`` activates system integration and creates an `AVPlayerItem`.
4. Key-value observations translate `AVPlayer` state into observable RadioKit state.
5. A failed item advances the chain or exhausts the station.
6. Timed metadata updates ``RadioPlayer/rawMetadata`` and ``RadioPlayer/songMetadata``.

An item generation value rejects callbacks from replaced items.
Replacing or clearing a station cancels metadata work and resets observations.

## Failure Boundaries

An endpoint failure advances the stream chain.
A network-path failure pauses the current candidate and preserves recovery intent.
These paths remain separate so an outage does not consume known alternatives.

RadioKit reports candidate and station exhaustion through ``RadioPlayer/eventHandler``.
The host app decides whether to log, measure, or display those events.

## Artwork And Metadata Work

``RadioSong`` parses metadata on the main actor and performs optional MusicKit lookup in a task.
``RadioArtwork`` fetches bounded image data and computes average color away from the main actor.

Both objects use identity-based observation for task results.
The player ignores artwork updates from a song or station that is no longer current.

## Application Boundary

RadioKit owns playback coordination and Apple media integration.
The host app owns user interface, station discovery, entitlements, authorization prompts, endpoint policy, and product analytics.
