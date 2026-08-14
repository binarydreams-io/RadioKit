# RadioPlayer Example

Run the complete SwiftUI example and inspect a practical RadioKit integration.

The example is stored in `Examples/RadioPlayer`.
It demonstrates station setup, observable player state, artwork, metadata, and playback controls.

## Run The Demo

1. Open the Xcode project in `Examples/RadioPlayer`.
2. Select its app scheme and a supported destination.
3. Choose a development team if signing is not configured locally.
4. Build and run the app.

Use a physical iOS device to evaluate background audio, interruptions, lock-screen controls, and remote commands.
Simulator playback is useful for interface work but is not final evidence for those system behaviors.

## Runtime Content

The demo requests the Record Rock Radio stream and artwork URL at runtime.
It does not bundle a Radio Record logo or stream audio.

RadioKit and Binary Dreams, LLC are not affiliated with or endorsed by Radio Record.
The station names, trademarks, stream, and artwork remain with their respective owners and providers.

The repository's MIT License covers demo source code.
It does not grant rights to third-party content that the demo requests.

## Optional Apple Music Setup

Apple Music enrichment requires the MusicKit capability and `NSAppleMusicUsageDescription` in the demo app.
The user must authorize access before catalog metadata and catalog artwork can appear.

Playback and timed stream metadata do not require Apple Music authorization.
