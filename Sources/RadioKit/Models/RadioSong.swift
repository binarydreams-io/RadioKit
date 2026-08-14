//
//  RadioSong.swift
//  RadioKit
//
//  Created by Leonid Frolov on 10.05.2023.
//

import Foundation
@preconcurrency import MusicKit

/// Metadata for the song that a radio stream currently announces.
@MainActor
@Observable public final class RadioSong: Equatable {
  /// The metadata string from which the song was parsed.
  public let rawMetadata: String?
  /// The parsed artist name.
  public internal(set) var artist: String
  /// The parsed song title.
  public internal(set) var title: String
  /// The artwork from the matched Apple Music song, if available.
  public internal(set) var artwork: RadioArtwork?
  /// The matched Apple Music song, if available.
  public internal(set) var fullMetadata: Song?

  private var metadataTask: Task<Void, Never>?

  init(rawMetadata: String?) throws {
    guard let rawMetadata else {
      throw Error.emptyRawMetadata
    }

    let parsed = try Self.parse(rawMetadata: rawMetadata)
    self.rawMetadata = rawMetadata
    self.artist = parsed.artist
    self.title = parsed.title

    self.metadataTask = Task { [weak self] in
      await self?.fillMetadata()
    }
  }

  isolated deinit {
    cancelMetadataTask()
  }

  /// Returns whether two song values came from the same metadata string.
  /// - Parameters:
  ///   - lhs: The first song to compare.
  ///   - rhs: The second song to compare.
  /// - Returns: `true` if both songs have the same raw metadata.
  public nonisolated static func == (lhs: RadioSong, rhs: RadioSong) -> Bool {
    lhs.rawMetadata == rhs.rawMetadata
  }

  /// Cancels the in-flight Apple Music metadata lookup, if any. Called when this
  /// song is replaced as the player's current metadata, and from `deinit`.
  func cancelMetadataTask() {
    metadataTask?.cancel()
    metadataTask = nil
  }

  /// Parses the first metadata separator and preserves separators in the title.
  static func parse(rawMetadata: String?) throws -> (artist: String, title: String) {
    guard let rawMetadata else {
      throw Error.emptyRawMetadata
    }

    guard let separator = rawMetadata.range(of: " - ") else {
      throw Error.invalidRawMetadata
    }

    let artist = rawMetadata[..<separator.lowerBound]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let title = rawMetadata[separator.upperBound...]
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard artist.isEmpty == false, title.isEmpty == false else {
      throw Error.invalidRawMetadata
    }

    return (artist, title)
  }
}

// MARK: - Helpers

extension RadioSong {
  /// Looks the song up in Apple Music and adopts its artwork when the catalog
  /// has a match. A failed lookup leaves the parsed artist and title in place.
  fileprivate func fillMetadata() async {
    do {
      fullMetadata = try await findSong()
    } catch {
      Log.debug(error.localizedDescription)
    }

    if let artwork = fullMetadata?.artwork, let artworkURL = artwork.url(width: 600, height: 600) {
      self.artwork = RadioArtwork(
        url: artworkURL,
        backgroundColor: artwork.backgroundColor,
        primaryTextColor: artwork.primaryTextColor,
        secondaryTextColor: artwork.secondaryTextColor
      )
    }
  }

  /// The best Apple Music catalog match for the parsed artist and title.
  fileprivate func findSong() async throws -> Song {
    guard MusicAuthorization.currentStatus == .authorized else {
      throw Error.musicNotAuthorized
    }

    let searchTerm = "\(artist) \(title)"
    var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
    searchRequest.includeTopResults = true
    searchRequest.limit = 1
    let searchResult = try await searchRequest.response()
    Log.debug("Music search returned \(searchResult.songs.count) song results")

    guard let song = searchResult.songs.first else {
      throw Error.songNotFound
    }

    return song
  }
}

// MARK: - Errors

extension RadioSong {
  enum Error: LocalizedError {
    case emptyRawMetadata
    case invalidRawMetadata
    case musicNotAuthorized
    case songNotFound

    var errorDescription: String? {
      switch self {
      case .emptyRawMetadata: "The metadata string is missing"
      case .invalidRawMetadata: "The metadata string cannot be parsed"
      case .musicNotAuthorized: "Apple Music access is not authorized"
      case .songNotFound: "Apple Music did not return a matching song"
      }
    }
  }
}
