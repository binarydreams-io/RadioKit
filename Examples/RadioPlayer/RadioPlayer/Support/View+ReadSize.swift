import SwiftUI

extension View {
  func onSizeChange(_ action: @escaping (CGSize) -> Void) -> some View {
    background {
      GeometryReader { geometry in
        Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
      }
    }
    .onPreferenceChange(SizePreferenceKey.self, perform: action)
  }
}

private struct SizePreferenceKey: PreferenceKey {
  static let defaultValue = CGSize.zero

  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}
