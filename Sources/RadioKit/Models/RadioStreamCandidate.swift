//
//  RadioStreamCandidate.swift
//  RadioKit
//
//  Created by Leonid Frolov on 01.08.2026.
//

import Foundation

/// One playable stream of a station, with the catalog metadata the player and
/// the host app need.
public struct RadioStreamCandidate: Codable, Equatable, Sendable {
  /// The stream address.
  public let url: URL
  /// The codec the catalog reports, or `nil` when it is unknown.
  public let codec: String?
  /// The preference order of the stream. A lower value plays first.
  public let rank: Int
  /// Whether the catalog last saw this stream as offline.
  public let isOffline: Bool

  /// Creates a stream candidate.
  /// - Parameters:
  ///   - url: The stream address.
  ///   - codec: The codec the catalog reports.
  ///   - rank: The preference order. A lower value plays first.
  ///   - isOffline: Whether the catalog last saw the stream as offline.
  public init(url: URL, codec: String? = nil, rank: Int = 0, isOffline: Bool = false) {
    self.url = url
    self.codec = codec
    self.rank = rank
    self.isOffline = isOffline
  }
}
