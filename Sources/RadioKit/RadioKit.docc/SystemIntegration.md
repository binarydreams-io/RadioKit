# System Integration

Configure Now Playing information, remote commands, background audio, and interruptions.

## Activation Lifecycle

RadioKit activates system integration lazily when ``RadioPlayer/play()`` starts a valid station.
Selecting a station without playing it does not install remote-command targets.

Activation creates Now Playing state, play and pause command handlers, and a network monitor.
On iOS, activation also configures the shared audio session for long-form playback.

Pausing does not remove system integration.
Set ``RadioPlayer/station`` to `nil` to remove handlers, clear Now Playing information, and deactivate the iOS audio session.

## Now Playing And Commands

Now Playing information starts with the station name and description.
Parsed song metadata replaces those display fields while a song is available.
Downloaded artwork is added when image loading succeeds.

RadioKit handles system play, pause, and toggle commands.
The shared ``RadioPlayer`` means these command handlers represent one process-wide playback session.

## iOS Background Audio

Enable the Background Modes capability in the host app.
Select Audio, AirPlay, and Picture in Picture.

RadioKit sets `AVAudioSession` to the playback category with the long-form audio policy.
The host app remains responsible for signing, entitlements, and conflicts with other audio-session users.

When an iOS interruption ends with the `shouldResume` option, RadioKit resumes active playback intent.
It does not resume when the user paused or the system omits that option.

## Validation

Lock-screen controls, media keys, interruptions, and background execution depend on system state.
Validate these paths in the host app.
Use a physical iOS device for final background and remote-command checks.
