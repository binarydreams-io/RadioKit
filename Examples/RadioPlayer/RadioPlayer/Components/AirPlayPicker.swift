import AVKit
import SwiftUI

struct AirPlayPicker: UIViewRepresentable {
  let color: Color

  init(color: Color = .accentColor) {
    self.color = color
  }

  func makeUIView(context: Context) -> AVRoutePickerView {
    AVRoutePickerView()
  }

  func updateUIView(_ routePickerView: AVRoutePickerView, context: Context) {
    let tintColor = UIColor(color)
    routePickerView.tintColor = tintColor
    routePickerView.activeTintColor = tintColor
  }
}
