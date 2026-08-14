//
//  RadioPlayer+Events.swift
//  RadioKit
//
//  Created by Leonid Frolov on 01.08.2026.
//

import Foundation

extension RadioPlayer {
  /// A playback fact the host app may want to record.
  ///
  /// RadioKit must not depend on the analytics layer, so it reports these
  /// through ``RadioPlayer/eventHandler`` and lets the app decide what to do
  /// with them.
  public enum PlaybackEvent: Equatable, Sendable {
    /// One stream failed to play. The chain advances to the next candidate.
    case streamFailed(RadioStreamCandidate)
    /// Every stream of the current station failed.
    case stationExhausted(streamsTried: Int)
  }
}
