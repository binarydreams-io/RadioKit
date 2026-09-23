# Changelog

All notable changes appear in this file.

## Unreleased

### Changed

- CI, documentation, and release workflows build with Swift 6.4 on the `xcode-27` runner image.
- The package still uses Swift tools 6.3, so consumers can build RadioKit with Swift 6.3 or later.
- The quality gate warns about a different local tool version. CI still fails on a mismatch.
- All scripts read the Swift, Swift tools, and quality-tool versions from `scripts/toolchain.env`.

### Fixed

- Documentation generation finds the built module with Swift 6.4.

## 2.0.0 - 2026-09-22

### Changed

- `RadioPlayer.PlayerStatus` is now `RadioPlayer.Status`.
- `RadioPlayer.Status` cases `radioStationNotSet`, `shouldPlay`, and `networkWasLost` are now `noStation`, `idle`, and `networkLost`.
- `RadioPlayer.songMetadata` is now `RadioPlayer.song`.
- `RadioSong.fullMetadata` is now `RadioSong.catalogSong`.
- `RadioGroupSynchronizer.lastRadioStation` is now `RadioGroupSynchronizer.lastStation`.
- `RadioStation.info` is now `RadioStation.subtitle`. The persisted key stays `info`.
- `UIImage.artwork` and `NSImage.artwork` are now `mediaItemArtwork`.
- `RadioStation.init` uses `nil` as the default value for `subtitle` and `artworkURL`.
- The old names stay available as deprecated aliases.

### Breaking

- `RadioSong.rawMetadata` is now a non-optional `String`. Code that unwraps it with `if let` or `guard let` does not compile.
- A `switch` over `RadioPlayer.Status` must handle the new case names. The deprecated names match in `case` patterns, but they do not satisfy exhaustiveness checks.

## 1.0.0 - 2026-08-14

### Added

- Internet radio playback for iOS 17 or later and macOS 14 or later.
- Ranked stream candidates with forward failover after playback failures.
- Observable playback, network, song metadata, artwork, and App Group state.
- System Now Playing information and media-key handling.
- Network recovery and iOS audio-session interruption handling.
- Timed metadata parsing with optional Apple Music enrichment.
- Bounded HTTP and HTTPS artwork loading with average-color analysis.
- App Group synchronization for widgets and app extensions.
- A privacy manifest for the required `UserDefaults` API reasons.
