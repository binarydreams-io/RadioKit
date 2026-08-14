//
//  StreamChain.swift
//  RadioKit
//
//  Created by Leonid Frolov on 01.08.2026.
//

import Foundation

/// The ordered stream candidates of a station with a forward-only cursor.
///
/// The player advances the cursor on every playback failure until a stream
/// plays or the chain runs out. A successful start does not rewind the cursor.
///
/// Candidates sort by `isOffline` first and by `rank` second. A stream the
/// catalog last saw offline therefore goes last but stays reachable: a filter
/// would make a station unplayable whenever every flag is stale.
struct StreamChain {
  private let candidates: [RadioStreamCandidate]
  private var cursor = 0

  /// Creates a chain over the candidates, in playing order.
  init(_ candidates: [RadioStreamCandidate]) {
    self.candidates = candidates.enumerated().sorted { left, right in
      let leftCandidate = left.element
      let rightCandidate = right.element

      if leftCandidate.isOffline != rightCandidate.isOffline {
        return !leftCandidate.isOffline
      }

      if leftCandidate.rank != rightCandidate.rank {
        return leftCandidate.rank < rightCandidate.rank
      }

      return left.offset < right.offset
    }.map(\.element)
  }

  /// The candidate at the cursor, or `nil` once the chain runs out.
  var current: RadioStreamCandidate? {
    candidates.indices.contains(cursor) ? candidates[cursor] : nil
  }

  /// How many candidates the player attempted, the current one included.
  var triedCount: Int {
    min(cursor + 1, candidates.count)
  }

  /// Whether the cursor has moved past every candidate.
  var isExhausted: Bool {
    current == nil
  }

  /// Moves the cursor forward.
  /// - Returns: The new candidate, or `nil` when the chain runs out.
  @discardableResult
  mutating func advance() -> RadioStreamCandidate? {
    cursor += 1
    return current
  }

  /// Moves the cursor back to the first candidate.
  mutating func reset() {
    cursor = 0
  }
}
