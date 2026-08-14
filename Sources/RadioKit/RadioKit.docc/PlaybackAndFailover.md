# Playback And Failover

Understand candidate order, failures, and network recovery.

## Candidate Order

Each ``RadioStreamCandidate`` has a URL, an optional codec label, a rank, and an offline hint.
The codec label does not configure `AVPlayer`.

RadioKit applies this order:

1. Candidates with `isOffline == false` come first.
2. Candidates with lower `rank` values come first within each availability group.
3. Candidates with equal values keep their original array order.

Offline candidates remain in the chain.
This behavior lets playback try them when every catalog hint is stale.

## Failure Behavior

RadioKit advances when `AVPlayerItem.status` becomes `failed`.
The player emits ``RadioPlayer/PlaybackEvent`` through ``RadioPlayer/eventHandler`` before it advances.

The event reports either one failed candidate or exhaustion of the complete station.
When every candidate fails, ``RadioPlayer/status`` becomes `streamFailed` and playback pauses.

A later call to ``RadioPlayer/play()`` resets an exhausted chain and starts from the first candidate.
Assigning a station also creates a new chain.

`AVPlayer` controls buffering and transport behavior.
A stalled stream can remain in the buffering state without producing a failure.

## Network Recovery

RadioKit starts network monitoring with the first playback request.
If the network path becomes unsatisfied during playback, the player pauses without consuming a candidate.

``RadioPlayer/status`` becomes `networkWasLost`.
When the path recovers, RadioKit starts the same candidate again if the user did not pause playback.

Calling ``RadioPlayer/pause()`` during an outage cancels automatic recovery.

## Playback Intent

``RadioPlayer/play()`` is idempotent while playback remains requested.
``RadioPlayer/playback`` describes the current item, while `status` gives more detail about readiness and failure.

Treat ``RadioPlayer/network`` as reachability information, not as proof that a stream endpoint works.
