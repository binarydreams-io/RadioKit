//
//  RadioPlayer+KVO.swift
//  RadioKit
//
//  Created by Leonid Frolov on 11.09.2024.
//

@preconcurrency import AVFoundation

// MARK: - Key-Value Handlers

extension RadioPlayer {
  fileprivate func handleTimeControlStatusUpdate(
    rawValue: Int,
    waitingReason: String?,
    generation: UInt64
  ) {
    guard generation == itemGeneration else { return }
    guard let timeControlStatus = AVPlayer.TimeControlStatus(rawValue: rawValue) else {
      return
    }

    switch timeControlStatus {
    case .waitingToPlayAtSpecifiedRate:
      if let waitingReason {
        Log.debug("Player is waiting to play: \(waitingReason)")
      }

      if network == .unsatisfied {
        shouldResumeAfterNetworkRecovery = isPlaybackRequested
        pause(keepingStatus: .networkWasLost, preservingRecoveryIntent: true)
      } else {
        status = .buffering
        playback = .playing
      }

    case .playing:
      status = .playbackLikelyToKeepUp
      playback = .playing

    case .paused:
      playback = .paused

    @unknown default:
      break
    }
  }

  fileprivate func handlePlayerStatusUpdate(rawValue: Int, generation: UInt64) {
    guard generation == itemGeneration else { return }
    guard let itemStatus = AVPlayerItem.Status(rawValue: rawValue) else { return }

    switch itemStatus {
    case .readyToPlay:
      status = .readyToPlay
    case .failed:
      advanceAfterStreamFailure()
    case .unknown:
      break
    @unknown default:
      break
    }
  }
}

// MARK: - Stream Fallback

extension RadioPlayer {
  func advanceAfterStreamFailure() {
    if network == .unsatisfied {
      shouldResumeAfterNetworkRecovery = isPlaybackRequested
      pause(keepingStatus: .networkWasLost, preservingRecoveryIntent: true)
      return
    }

    if let failed = chain?.current {
      eventHandler?(.streamFailed(failed))
    }

    guard chain?.advance() != nil else {
      eventHandler?(.stationExhausted(streamsTried: chain?.triedCount ?? 0))
      pause(keepingStatus: .streamFailed, preservingRecoveryIntent: false)
      return
    }

    resetObservers()
    guard configurePlayer() else {
      pause(keepingStatus: .streamFailed, preservingRecoveryIntent: false)
      return
    }
    setupObservers()
    player.play()
  }
}

// MARK: - Key-Value Observers

extension RadioPlayer {
  func setupObservers() {
    resetObservers()
    let generation = itemGeneration

    timeControlStatusObserver = player.observe(
      \.timeControlStatus,
      options: [.new, .initial]
    ) { [weak self] player, _ in
      let rawValue = player.timeControlStatus.rawValue
      let waitingReason = player.reasonForWaitingToPlay?.rawValue
      Task { @MainActor [weak self] in
        self?.handleTimeControlStatusUpdate(
          rawValue: rawValue,
          waitingReason: waitingReason,
          generation: generation
        )
      }
    }

    statusObserver = playerItem?.observe(
      \.status,
      options: [.new, .initial]
    ) { [weak self] item, _ in
      let rawValue = item.status.rawValue
      Task { @MainActor [weak self] in
        self?.handlePlayerStatusUpdate(rawValue: rawValue, generation: generation)
      }
    }
  }

  func resetObservers() {
    timeControlStatusObserver?.invalidate()
    timeControlStatusObserver = nil
    statusObserver?.invalidate()
    statusObserver = nil
  }
}
