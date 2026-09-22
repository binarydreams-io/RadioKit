//
//  RadioPlayer+Models.swift
//  RadioKit
//
//  Created by Leonid Frolov on 11.09.2024.
//

// MARK: - Types & Errors

extension RadioPlayer {
  /// The high-level status of a `RadioPlayer`.
  public enum Status: CustomStringConvertible, Equatable, Sendable {
    /// No station is selected.
    case noStation
    /// A station is selected, and playback is not requested.
    case idle
    /// The player item loaded and can start.
    case readyToPlay
    /// The player is filling its buffer.
    case buffering
    /// The buffer holds enough data to keep playing.
    case playbackLikelyToKeepUp
    /// The connection dropped while playing.
    case networkLost
    /// The stream failed to load, for example through a bad address, an HTTP
    /// error, or an unsupported codec.
    case streamFailed
    /// A human-readable description of the status.
    public var description: String {
      switch self {
      case .noStation: "No radio station is set"
      case .idle: "The radio station is ready to start"
      case .readyToPlay: "Ready to play"
      case .buffering: "Stream is buffering"
      case .playbackLikelyToKeepUp: "Buffer is full enough"
      case .networkLost: "Network was lost while playing"
      case .streamFailed: "Stream failed to load"
      }
    }
  }

  /// The previous name of ``RadioPlayer/Status``.
  @available(*, deprecated, renamed: "Status")
  public typealias PlayerStatus = Status

  /// The playback state of the current player item.
  public enum PlaybackState: CustomStringConvertible, Equatable, Sendable {
    /// Audio is playing.
    case playing
    /// Playback is paused.
    case paused
    /// A human-readable description of the playback state.
    public var description: String {
      switch self {
      case .playing: "Player is playing"
      case .paused: "Player is paused"
      }
    }
  }

  /// The current network reachability state.
  public enum NetworkState: CustomStringConvertible, Equatable, Sendable {
    /// The network can carry the stream.
    case satisfied
    /// The network is unreachable or too slow to play.
    case unsatisfied
    /// A human-readable description of the network state.
    public var description: String {
      switch self {
      case .satisfied: "Internet is reachable"
      case .unsatisfied: "Poor internet connection"
      }
    }
  }
}

// MARK: - Deprecated Names

extension RadioPlayer.Status {
  /// The previous name of ``noStation``.
  @available(*, deprecated, renamed: "noStation")
  public static var radioStationNotSet: Self {
    .noStation
  }

  /// The previous name of ``idle``.
  @available(*, deprecated, renamed: "idle")
  public static var shouldPlay: Self {
    .idle
  }

  /// The previous name of ``networkLost``.
  @available(*, deprecated, renamed: "networkLost")
  public static var networkWasLost: Self {
    .networkLost
  }
}
