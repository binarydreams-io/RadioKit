//
//  RadioPlayer+Methods.swift
//  RadioKit
//
//  Created by Leonid Frolov on 11.09.2024.
//

extension RadioPlayer {
  /// Starts playback of the selected station.
  public func play() {
    _ = startPlayback()
  }

  /// Pauses playback of the selected station.
  public func pause() {
    shouldResumeAfterNetworkRecovery = false
    pause(keepingStatus: nil, preservingRecoveryIntent: false)
  }

  /// Toggles the active playback intent.
  /// - Returns: `true` only when an active playback intent remains.
  @discardableResult
  public func togglePlayback() -> Bool {
    if isPlaybackRequested {
      pause()
      return false
    }

    return startPlayback()
  }
}

extension RadioPlayer {
  @discardableResult
  func startPlayback() -> Bool {
    guard station != nil else { return false }
    guard isPlaybackRequested == false else { return true }

    if chain?.isExhausted == true {
      chain?.reset()
    }

    guard chain?.current != nil else { return false }
    guard activateSystemIntegration() else { return false }
    guard configurePlayer() else { return false }

    isPlaybackRequested = true
    setupObservers()
    player.play()
    return true
  }

  func pause(
    keepingStatus errorStatus: PlayerStatus?,
    preservingRecoveryIntent: Bool
  ) {
    isPlaybackRequested = false
    if preservingRecoveryIntent == false {
      shouldResumeAfterNetworkRecovery = false
    }

    player.pause()
    tearDownPlayer()
    resetObservers()
    status = errorStatus ?? (station == nil ? .radioStationNotSet : .shouldPlay)
  }

  func handleRemotePlay() -> Bool {
    startPlayback()
  }

  func handleRemotePause() -> Bool {
    guard station != nil, isPlaybackRequested else { return false }
    pause()
    return true
  }

  func handleRemoteToggle() -> Bool {
    guard station != nil else { return false }

    if isPlaybackRequested {
      pause()
      return true
    }

    return startPlayback()
  }
}
