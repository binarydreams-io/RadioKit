import AVFoundation
import MediaPlayer
import SwiftUI

struct VolumeSlider: View {
  private let activeColor: Color
  private let fillColor: Color
  private let emptyColor: Color

  @State private var progress = AVAudioSession.sharedInstance().outputVolume
  @State private var temporaryProgress: Float = 0
  @State private var outputVolumeObserver: NSKeyValueObservation?
  @GestureState private var isActive = false

  init(color: Color = .accentColor) {
    self.activeColor = color
    self.fillColor = color.opacity(0.65)
    self.emptyColor = color.opacity(0.3)
  }

  private var volume: Float {
    min(max(progress + temporaryProgress, 0), 1)
  }

  var body: some View {
    GeometryReader { bounds in
      HStack(spacing: 10) {
        Image(systemName: "speaker.fill")

        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(emptyColor)

            Capsule()
              .fill(isActive ? activeColor : fillColor)
              .frame(width: geometry.size.width * Double(volume))
          }
          .frame(height: isActive ? 16 : 8)
          .frame(maxHeight: .infinity)
        }

        Image(systemName: "speaker.wave.3.fill")
      }
      .foregroundStyle(isActive ? activeColor : fillColor)
      .frame(
        width: isActive ? bounds.size.width * 1.04 : bounds.size.width,
        height: bounds.size.height
      )
      .contentShape(.rect)
      .gesture(
        DragGesture(minimumDistance: 0)
          .updating($isActive) { _, state, transaction in
            transaction.animation = .spring
            state = true
          }
          .onChanged { gesture in
            withAnimation(.spring) {
              temporaryProgress = Float(gesture.translation.width / bounds.size.width)
            }
            SystemVolume.set(volume)
          }
          .onEnded { _ in
            withAnimation(.spring) {
              progress = volume
              temporaryProgress = 0
            }
          }
      )
      .animation(.spring, value: isActive)
      .onAppear {
        progress = AVAudioSession.sharedInstance().outputVolume
        observeOutputVolume()
        SystemVolume.prepare()
      }
      .onDisappear {
        outputVolumeObserver?.invalidate()
        outputVolumeObserver = nil
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("System volume")
    .accessibilityValue(Text(volume, format: .percent))
    .accessibilityAdjustableAction(adjustVolume)
  }

  private func observeOutputVolume() {
    outputVolumeObserver = AVAudioSession.sharedInstance().observe(
      \.outputVolume,
      options: [.new]
    ) { _, change in
      guard let newVolume = change.newValue else { return }
      Task { @MainActor in
        guard !isActive else { return }
        progress = newVolume
      }
    }
  }

  private func adjustVolume(_ direction: AccessibilityAdjustmentDirection) {
    switch direction {
    case .increment:
      progress = min(progress + 0.05, 1)
    case .decrement:
      progress = max(progress - 0.05, 0)
    @unknown default:
      return
    }

    temporaryProgress = 0
    SystemVolume.set(progress)
  }
}

@MainActor
private enum SystemVolume {
  private static let volumeView = MPVolumeView()
  private static let slider = volumeView.subviews.first { $0 is UISlider } as? UISlider

  static func prepare() {
    _ = slider
  }

  static func set(_ volume: Float) {
    slider?.value = volume
  }
}
