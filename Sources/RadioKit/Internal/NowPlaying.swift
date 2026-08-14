//
//  NowPlaying.swift
//  RadioKit
//
//  Created by Leonid Frolov on 12.05.2023.
//

import Foundation
@preconcurrency import MediaPlayer

/// Publishes station and song details to the system Now Playing panel.
@MainActor
final class NowPlaying {
  private let infoCenter = MPNowPlayingInfoCenter.default()
  private var nowPlayingInfo = [String: Any]()
  private var currentStation: RadioStation?

  func setRadioStation(_ radioStation: RadioStation?) {
    guard let radioStation else {
      clear()
      return
    }

    currentStation = radioStation
    nowPlayingInfo = [
      MPMediaItemPropertyTitle: radioStation.name,
      MPNowPlayingInfoPropertyIsLiveStream: true,
    ]
    if let info = radioStation.info {
      nowPlayingInfo[MPMediaItemPropertyArtist] = info
    }

    infoCenter.nowPlayingInfo = nowPlayingInfo
    infoCenter.playbackState = .paused
  }

  func setSong(artist: String, title: String) {
    nowPlayingInfo[MPMediaItemPropertyTitle] = "\(artist) - \(title)"
    nowPlayingInfo[MPMediaItemPropertyArtist] = currentStation?.name
    infoCenter.nowPlayingInfo = nowPlayingInfo
  }

  func setArtwork(_ artwork: MPMediaItemArtwork?) {
    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
    infoCenter.nowPlayingInfo = nowPlayingInfo
  }

  func setPlaybackState(isPlaying: Bool) {
    infoCenter.playbackState = isPlaying ? .playing : .paused
  }

  func clear() {
    currentStation = nil
    nowPlayingInfo.removeAll()
    infoCenter.nowPlayingInfo = nil
    infoCenter.playbackState = .stopped
  }
}
