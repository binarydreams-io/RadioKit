import MusicKit
import RadioKit
import SwiftUI

struct FullPlayer: View {
  @AppStorage("RecordRockRadioIsFavorite") private var isFavorite = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.openURL) private var openURL
  @State private var player = RadioKit.RadioPlayer.shared

  private var artworkScale: Double {
    player.playback == .playing ? 1 : 0.85
  }

  private var backdropColor: Color {
    Color(player.artwork?.backgroundColor ?? CGColor(gray: 0.12, alpha: 1))
  }

  private var contentColor: Color {
    player.artwork?.isBackgroundDark == false ? .black : .white
  }

  private var artworkAccessibilityLabel: String {
    if let song = player.songMetadata {
      return "Artwork for \(song.title) by \(song.artist)"
    }

    return "Artwork for \(player.station?.name ?? DemoStation.recordRock.name)"
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        backdropColor
          .opacity(0.9)
          .ignoresSafeArea()
          .accessibilityHidden(true)

        VStack(spacing: 20) {
          HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(player.station?.name ?? DemoStation.recordRock.name)
              .font(.title2.weight(.semibold))
              .frame(maxWidth: .infinity, alignment: .leading)

            ToggleButton(
              symbolSize: 24,
              icon: ToggleIcon(activeSymbol: "star.fill", inactiveSymbol: "star"),
              isActive: isFavorite,
              accessibilityLabel: isFavorite ? "Remove from Favorites" : "Add to Favorites"
            ) {
              isFavorite.toggle()
            }
            .foregroundStyle(.yellow)
          }

          Spacer(minLength: 0)

          ArtworkImage(url: player.artwork?.url, cornerRadius: 16)
            .frame(
              width: artworkSize(in: geometry.size),
              height: artworkSize(in: geometry.size)
            )
            .shadow(color: .black.opacity(0.35), radius: 40, y: 16)
            .scaleEffect(reduceMotion ? 1 : artworkScale)
            .animation(
              reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
              value: artworkScale
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(artworkAccessibilityLabel)

          metadataView

          Spacer(minLength: 0)

          ToggleButton(
            symbolSize: 46,
            icon: ToggleIcon(activeSymbol: "pause.fill", inactiveSymbol: "play.fill"),
            isActive: player.playback == .playing,
            accessibilityLabel: player.playback == .playing ? "Pause" : "Play"
          ) {
            player.togglePlayback()
          }
          .padding(.vertical, 4)

          Spacer(minLength: 0)

          VolumeSlider(color: contentColor)
            .frame(height: 44)

          AirPlayPicker(color: contentColor)
            .frame(width: 46, height: 46)
            .accessibilityLabel("AirPlay")
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
      }
    }
    .foregroundStyle(contentColor)
    .tint(contentColor)
  }

  private var metadataView: some View {
    VStack {
      switch player.status {
      case .radioStationNotSet:
        Label("No station selected", systemImage: "antenna.radiowaves.left.and.right.slash")

      case .networkWasLost:
        Label("No network connection", systemImage: "wifi.exclamationmark")

      case .streamFailed:
        Label("The station is unavailable", systemImage: "exclamationmark.triangle")

      case .buffering:
        ProgressView()
          .accessibilityLabel("Buffering")

      case .shouldPlay, .readyToPlay, .playbackLikelyToKeepUp:
        if let song = player.songMetadata {
          HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 2) {
              MarqueeText(song.title)
                .font(.title3.weight(.semibold))
              MarqueeText(song.artist)
                .font(.title3)
                .foregroundStyle(contentColor.opacity(0.65))
            }

            metadataMenu
          }
        } else {
          Text(player.station?.name ?? DemoStation.recordRock.name)
            .font(.title3.weight(.semibold))
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
      }
    }
    .frame(height: 30)
    .padding(.vertical)
  }

  private var metadataMenu: some View {
    Menu {
      if let url = player.songMetadata?.fullMetadata?.url {
        Button("Open in Apple Music", systemImage: "music.note") {
          openURL(url)
        }

        ShareLink(item: url) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      } else {
        Label("Song not found", systemImage: "waveform.badge.magnifyingglass")
      }
    } label: {
      Label("More", systemImage: "ellipsis.circle.fill")
        .labelStyle(.iconOnly)
        .font(.title2)
    }
    .frame(minWidth: 44, minHeight: 44)
    .opacity(0.65)
  }

  private func artworkSize(in availableSize: CGSize) -> Double {
    let width = min(max(availableSize.width - 60, 140), 420)
    let height = max(availableSize.height * 0.42, 140)
    return min(width, height)
  }
}
