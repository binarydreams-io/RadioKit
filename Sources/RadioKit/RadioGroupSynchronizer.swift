//
//  RadioGroupSynchronizer.swift
//  RadioKit
//
//  Created by Leonid Frolov on 08.11.2023.
//

import Foundation
import WidgetKit

/// Stores playback state in an App Group for widgets and app extensions.
@MainActor
@Observable public final class RadioGroupSynchronizer {
  @ObservationIgnored private let defaults: UserDefaults?
  @ObservationIgnored private let reloadTimelines: @MainActor () -> Void

  /// The most recently played station in the shared suite.
  public internal(set) var lastRadioStation: RadioStation?

  /// Whether playback is currently active.
  public internal(set) var isPlaying: Bool

  /// Creates a synchronizer for an App Group suite.
  /// - Parameter suiteName: The suite name shared by the app and its extensions.
  public init(suiteName: String) {
    let defaults = UserDefaults(suiteName: suiteName)
    self.defaults = defaults
    self.reloadTimelines = {
      WidgetCenter.shared.reloadAllTimelines()
    }
    self.lastRadioStation = Self.loadLastStation(from: defaults)
    self.isPlaying = defaults?.bool(forKey: Keys.isPlaying) ?? false
  }

  init(
    defaults: UserDefaults,
    reloadTimelines: @escaping @MainActor () -> Void
  ) {
    self.defaults = defaults
    self.reloadTimelines = reloadTimelines
    self.lastRadioStation = Self.loadLastStation(from: defaults)
    self.isPlaying = defaults.bool(forKey: Keys.isPlaying)
  }
}

// MARK: - Methods

extension RadioGroupSynchronizer {
  /// Stores a station as the most recently played station.
  /// - Parameter station: The station to store.
  public func setLastStation(_ station: RadioStation) {
    guard station != lastRadioStation, let defaults else { return }

    do {
      let data = try JSONEncoder().encode(station)
      defaults.set(data, forKey: Keys.lastRadioStation)
      lastRadioStation = station
      reloadTimelines()
    } catch {
      Log.error("Last-station encoding failed: \(error.localizedDescription)")
    }
  }

  /// Stores whether playback is currently active.
  /// - Parameter isPlaying: `true` if playback is active.
  public func setPlaying(_ isPlaying: Bool) {
    guard isPlaying != self.isPlaying, let defaults else { return }

    defaults.set(isPlaying, forKey: Keys.isPlaying)
    self.isPlaying = isPlaying
    reloadTimelines()
  }
}

extension RadioGroupSynchronizer {
  fileprivate enum Keys {
    static let lastRadioStation = "lastRadioStation"
    static let isPlaying = "isPlayingNow"
  }

  fileprivate static func loadLastStation(from defaults: UserDefaults?) -> RadioStation? {
    guard let data = defaults?.data(forKey: Keys.lastRadioStation) else {
      return nil
    }

    do {
      return try JSONDecoder().decode(RadioStation.self, from: data)
    } catch {
      Log.error("Last-station decoding failed: \(error.localizedDescription)")
      return nil
    }
  }
}
