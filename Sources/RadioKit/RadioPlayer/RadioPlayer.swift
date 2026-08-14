//
//  RadioPlayer.swift
//  RadioKit
//
//  Created by Leonid Frolov on 08.05.2023.
//

import AVFoundation
import Network
import Observation

/// Plays internet radio stations through `AVPlayer`.
///
/// Setting ``station`` loads its stream candidates and leaves the player paused.
/// A failing stream advances to the next candidate. A lost network does not
/// advance the stream chain.
@MainActor
@Observable public final class RadioPlayer: NSObject {
  /// The shared player instance.
  public static let shared = RadioPlayer()

  /// The current high-level status of the player.
  public internal(set) var status: PlayerStatus = .radioStationNotSet

  /// The current playback state of the player.
  public internal(set) var playback: PlaybackState = .paused {
    didSet {
      guard playback != oldValue else { return }

      let isPlaying = playback == .playing
      nowPlaying?.setPlaybackState(isPlaying: isPlaying)
      groupSynchronizer?.setPlaying(isPlaying)
    }
  }

  /// The playback volume in the range `0...1`.
  ///
  /// The value controls `AVPlayer.volume` and persists in `UserDefaults`.
  public var volume: Float = RadioPlayer.loadPersistedVolume() {
    didSet {
      let normalized = Self.normalizedVolume(volume)
      if volume != normalized {
        volume = normalized
      }

      guard normalized != oldValue else { return }
      player.volume = normalized
      UserDefaults.standard.set(normalized, forKey: Self.volumeDefaultsKey)
    }
  }

  /// The current network reachability state.
  public internal(set) var network: NetworkState = .satisfied

  /// The station selected for playback.
  public var station: RadioStation? {
    willSet {
      tearDownPlayer()
      resetObservers()
      shouldResumeAfterNetworkRecovery = false
      wasPlaybackActiveBeforeInterruption = false
    }

    didSet {
      guard let station else {
        artwork = nil
        status = .radioStationNotSet
        chain = nil
        deactivateSystemIntegration()
        return
      }

      artwork = makeArtwork(for: station)
      status = .shouldPlay
      chain = StreamChain(station.streams)
      nowPlaying?.setRadioStation(station)
      nowPlaying?.setArtwork(artwork?.image?.artwork)
      groupSynchronizer?.setLastStation(station)
    }
  }

  /// Receives stream-failure events for optional host-app reporting.
  @ObservationIgnored
  public var eventHandler: ((PlaybackEvent) -> Void)?

  @ObservationIgnored
  var chain: StreamChain?

  /// The App Group synchronizer that receives station and playback changes.
  public var groupSynchronizer: RadioGroupSynchronizer?

  /// The song that the current stream reports, if available.
  public internal(set) var songMetadata: RadioSong? {
    willSet {
      guard let newMetadata = newValue else { return }

      _ = withObservationTracking {
        newMetadata.artwork
      } onChange: { [weak self, weak newMetadata] in
        Task { @MainActor [weak self, weak newMetadata] in
          guard
            let self,
            let newMetadata,
            songMetadata === newMetadata,
            isPlaybackRequested
          else { return }

          artwork = newMetadata.artwork ?? station.flatMap(makeArtwork(for:))
        }
      }
    }

    didSet {
      oldValue?.cancelMetadataTask()

      if let song = songMetadata {
        nowPlaying?.setSong(artist: song.artist, title: song.title)
      } else {
        artwork = station.flatMap(makeArtwork(for:))
        nowPlaying?.setRadioStation(station)
      }
    }
  }

  /// The current song artwork, or the station artwork when no song is known.
  public internal(set) var artwork: RadioArtwork? {
    didSet {
      nowPlaying?.setArtwork(artwork?.image?.artwork)
      guard let newArtwork = artwork else { return }

      _ = withObservationTracking {
        newArtwork.image
      } onChange: { [weak self, weak newArtwork] in
        Task { @MainActor [weak self, weak newArtwork] in
          guard let self, let newArtwork, artwork === newArtwork else { return }
          nowPlaying?.setArtwork(newArtwork.image?.artwork)
        }
      }
    }
  }

  /// The unparsed metadata string last delivered by the stream.
  public internal(set) var rawMetadata: String?

  private static let volumeDefaultsKey = "PlaybackVolume"

  static func normalizedVolume(_ value: Float) -> Float {
    guard value.isNaN == false else { return 0 }
    return min(max(value, 0), 1)
  }

  private static func loadPersistedVolume() -> Float {
    let defaults = UserDefaults.standard
    guard defaults.object(forKey: volumeDefaultsKey) != nil else { return 1 }
    return normalizedVolume(defaults.float(forKey: volumeDefaultsKey))
  }

  override private init() {
    super.init()
    player.volume = volume
  }

  let player = AVPlayer()
  var playerItem: AVPlayerItem?
  var nowPlaying: NowPlaying?
  var commandCenter: CommandCenter?
  var metadataDelegate: MetadataOutputDelegate?
  var networkMonitor: NWPathMonitor?
  var itemGeneration: UInt64 = 0
  var isPlaybackRequested = false
  var shouldResumeAfterNetworkRecovery = false
  var systemIntegrationIsActive = false

  #if os(iOS)
    var interruptionObserver: NSObjectProtocol?
    var wasPlaybackActiveBeforeInterruption = false
  #else
    var wasPlaybackActiveBeforeInterruption = false
  #endif

  var timeControlStatusObserver: NSKeyValueObservation?
  var statusObserver: NSKeyValueObservation?

  private func makeArtwork(for station: RadioStation) -> RadioArtwork? {
    station.artworkURL.map { RadioArtwork(url: $0) }
  }
}
