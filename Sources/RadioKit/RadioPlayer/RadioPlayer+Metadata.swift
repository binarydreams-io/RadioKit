//
//  RadioPlayer+Metadata.swift
//  RadioKit
//
//  Created by Leonid Frolov on 11.09.2024.
//

@preconcurrency import AVFoundation
import os

final class MetadataOutputDelegate: NSObject,
  AVPlayerItemMetadataOutputPushDelegate,
  Sendable
{
  private let metadataTask = OSAllocatedUnfairLock<Task<Void, Never>?>(
    initialState: nil
  )
  private let handler: @Sendable (String?) -> Void

  init(handler: @escaping @Sendable (String?) -> Void) {
    self.handler = handler
  }

  nonisolated func metadataOutput(
    _ output: AVPlayerItemMetadataOutput,
    didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
    from track: AVPlayerItemTrack?
  ) {
    let metadata = groups.first?.items.first?.copy() as? AVMetadataItem
    guard let metadata else {
      cancel()
      handler(nil)
      return
    }

    let task = Task { [handler] in
      let value = try? await metadata.load(.stringValue)
      guard Task.isCancelled == false else { return }
      handler(value)
    }

    metadataTask.withLock { currentTask in
      currentTask?.cancel()
      currentTask = task
    }
  }

  nonisolated func cancel() {
    metadataTask.withLock { task in
      task?.cancel()
      task = nil
    }
  }
}

extension RadioPlayer {
  func receiveMetadata(_ rawMetadata: String?, generation: UInt64) {
    guard generation == itemGeneration else { return }
    updateMetadata(rawMetadata: rawMetadata)
  }

  private func updateMetadata(rawMetadata: String?) {
    self.rawMetadata = rawMetadata

    guard let rawMetadata else {
      songMetadata = nil
      return
    }

    guard songMetadata?.rawMetadata != rawMetadata else { return }

    do {
      songMetadata = try RadioSong(rawMetadata: rawMetadata)
    } catch {
      songMetadata = nil
      Log.error(error.localizedDescription)
    }
  }
}
