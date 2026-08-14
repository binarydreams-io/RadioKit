//
//  RadioPlayer+Helpers.swift
//  RadioKit
//
//  Created by Leonid Frolov on 11.09.2024.
//

@preconcurrency import AVFoundation
@preconcurrency import MediaPlayer
@preconcurrency import Network

// MARK: - Player Lifecycle

extension RadioPlayer {
  func activateSystemIntegration() -> Bool {
    guard systemIntegrationIsActive == false else { return true }
    guard activateAudioSession() else { return false }

    let nowPlaying = NowPlaying()
    self.nowPlaying = nowPlaying
    nowPlaying.setRadioStation(station)
    nowPlaying.setArtwork(artwork?.image?.artwork)

    commandCenter = CommandCenter(
      playAction: { [weak self] in self?.handleRemotePlay() ?? false },
      pauseAction: { [weak self] in self?.handleRemotePause() ?? false },
      toggleAction: { [weak self] in self?.handleRemoteToggle() ?? false }
    )

    setupNetworkMonitor()
    #if os(iOS)
      setupInterruptionObserver()
    #endif

    systemIntegrationIsActive = true
    return true
  }

  func deactivateSystemIntegration() {
    guard systemIntegrationIsActive else { return }

    commandCenter?.invalidate()
    commandCenter = nil

    networkMonitor?.pathUpdateHandler = nil
    networkMonitor?.cancel()
    networkMonitor = nil

    #if os(iOS)
      if let interruptionObserver {
        NotificationCenter.default.removeObserver(interruptionObserver)
        self.interruptionObserver = nil
      }
    #endif

    nowPlaying?.clear()
    nowPlaying = nil
    deactivateAudioSession()
    systemIntegrationIsActive = false
  }

  func activateAudioSession() -> Bool {
    #if os(iOS)
      do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
          .playback,
          mode: .default,
          policy: .longFormAudio
        )
        try audioSession.setActive(true)
        return true
      } catch {
        Log.error("Audio-session activation failed: \(error.localizedDescription)")
        return false
      }
    #else
      return true
    #endif
  }

  func deactivateAudioSession() {
    #if os(iOS)
      do {
        try AVAudioSession.sharedInstance().setActive(
          false,
          options: .notifyOthersOnDeactivation
        )
      } catch {
        Log.error("Audio-session deactivation failed: \(error.localizedDescription)")
      }
    #endif
  }

  func configurePlayer() -> Bool {
    guard let streamURL = chain?.current?.url else { return false }

    itemGeneration &+= 1
    metadataDelegate?.cancel()

    let item = AVPlayerItem(url: streamURL)
    let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
    let generation = itemGeneration
    let metadataDelegate = MetadataOutputDelegate { [weak self] rawMetadata in
      Task { @MainActor [weak self] in
        self?.receiveMetadata(rawMetadata, generation: generation)
      }
    }
    metadataOutput.setDelegate(metadataDelegate, queue: .main)
    item.add(metadataOutput)

    self.metadataDelegate = metadataDelegate
    playerItem = item
    player.replaceCurrentItem(with: item)
    return true
  }

  func tearDownPlayer() {
    itemGeneration &+= 1
    isPlaybackRequested = false
    metadataDelegate?.cancel()
    metadataDelegate = nil
    playerItem = nil
    songMetadata = nil
    rawMetadata = nil
    playback = .paused
    player.replaceCurrentItem(with: nil)
  }
}

// MARK: - Network

extension RadioPlayer {
  func setupNetworkMonitor() {
    guard networkMonitor == nil else { return }

    let monitor = NWPathMonitor()
    networkMonitor = monitor
    monitor.pathUpdateHandler = { [weak self] path in
      let isSatisfied = path.status == .satisfied
      Task { @MainActor [weak self] in
        self?.handleNetworkUpdate(isSatisfied: isSatisfied)
      }
    }
    monitor.start(queue: .main)
  }

  func handleNetworkUpdate(isSatisfied: Bool) {
    network = isSatisfied ? .satisfied : .unsatisfied

    if isSatisfied {
      guard status == .networkWasLost, shouldResumeAfterNetworkRecovery else {
        return
      }

      shouldResumeAfterNetworkRecovery = false
      play()
      return
    }

    guard isPlaybackRequested else { return }
    shouldResumeAfterNetworkRecovery = true
    pause(keepingStatus: .networkWasLost, preservingRecoveryIntent: true)
  }
}

// MARK: - Audio Session Interruptions

#if os(iOS)
  extension RadioPlayer {
    func setupInterruptionObserver() {
      guard interruptionObserver == nil else { return }

      interruptionObserver = NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: AVAudioSession.sharedInstance(),
        queue: .main
      ) { [weak self] notification in
        guard
          let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt
        else { return }

        let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
        Task { @MainActor [weak self] in
          self?.handleInterruption(typeValue: typeValue, optionsValue: optionsValue)
        }
      }
    }

    func handleInterruption(typeValue: UInt, optionsValue: UInt?) {
      guard let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
        return
      }

      switch type {
      case .began:
        wasPlaybackActiveBeforeInterruption = isPlaybackRequested
        Log.debug("Audio-session interruption began")

      case .ended:
        let options = optionsValue.map(AVAudioSession.InterruptionOptions.init(rawValue:))
        let shouldResume =
          wasPlaybackActiveBeforeInterruption
          && isPlaybackRequested
          && options?.contains(.shouldResume) == true
        wasPlaybackActiveBeforeInterruption = false

        if shouldResume, activateAudioSession() {
          player.play()
        }

      @unknown default:
        break
      }
    }
  }
#endif
