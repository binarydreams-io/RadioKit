//
//  RadioStation.swift
//  RadioKit
//
//  Created by Leonid Frolov on 10.05.2023.
//

import Foundation

/// A radio station that a ``RadioPlayer`` can stream.
public struct RadioStation: Codable, Equatable, Sendable {
  /// The unique identifier of the station.
  public let id: UUID
  /// The display name of the station.
  public let name: String
  /// An optional description of the station.
  public let info: String?
  /// The canonical stream URL used when no stream candidates are provided.
  public let streamURL: URL
  /// The URL of the station's artwork image, if any.
  public let artworkURL: URL?
  /// Every playable stream of the station.
  ///
  /// The player orders candidates by availability and rank. This array is never
  /// empty because ``streamURL`` supplies a default candidate.
  public let streams: [RadioStreamCandidate]

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case info
    case streamURL
    case artworkURL
    case streams
  }

  /// Creates a radio station with the given identity and stream details.
  /// - Parameters:
  ///   - id: The unique identifier of the station.
  ///   - name: The display name of the station.
  ///   - info: An optional description of the station.
  ///   - streamURL: The canonical URL used when `streams` is empty.
  ///   - artworkURL: The URL of the station's artwork image, if any.
  ///   - streams: Every playable stream. Defaults to one derived from `streamURL`.
  public init(
    id: UUID,
    name: String,
    info: String?,
    streamURL: URL,
    artworkURL: URL?,
    streams: [RadioStreamCandidate] = []
  ) {
    self.id = id
    self.name = name
    self.info = info
    self.streamURL = streamURL
    self.artworkURL = artworkURL
    self.streams = streams.isEmpty ? [RadioStreamCandidate(url: streamURL)] : streams
  }
}

// MARK: - Encoding

extension RadioStation {
  /// Creates a station by decoding its persisted representation.
  /// - Parameter decoder: The decoder that contains the station representation.
  /// - Throws: A decoding error if a present field has an invalid value.
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try values.decode(UUID.self, forKey: .id)
    self.name = try values.decode(String.self, forKey: .name)
    self.info = try values.decodeIfPresent(String.self, forKey: .info)
    self.streamURL = try values.decode(URL.self, forKey: .streamURL)
    self.artworkURL = try values.decodeIfPresent(URL.self, forKey: .artworkURL)
    let decodedStreams = try values.decodeIfPresent(
      [RadioStreamCandidate].self,
      forKey: .streams
    )
    self.streams =
      decodedStreams.flatMap { $0.isEmpty ? nil : $0 }
      ?? [RadioStreamCandidate(url: streamURL)]
  }

  /// Encodes the station into a persistent representation.
  /// - Parameter encoder: The encoder that receives the station representation.
  /// - Throws: An encoding error if the encoder cannot store a field.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(info, forKey: .info)
    try container.encode(streamURL, forKey: .streamURL)
    try container.encode(artworkURL, forKey: .artworkURL)
    try container.encode(streams, forKey: .streams)
  }
}
