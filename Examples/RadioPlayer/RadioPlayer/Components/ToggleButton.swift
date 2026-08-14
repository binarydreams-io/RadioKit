import SwiftUI

struct ToggleButton: View {
  @ScaledMetric(relativeTo: .body) private var symbolSize = 24.0

  let icon: ToggleIcon
  let isActive: Bool
  let accessibilityLabel: String
  let action: () -> Void

  init(
    symbolSize: Double,
    icon: ToggleIcon,
    isActive: Bool,
    accessibilityLabel: String,
    action: @escaping () -> Void
  ) {
    self._symbolSize = ScaledMetric(wrappedValue: symbolSize, relativeTo: .body)
    self.icon = icon
    self.isActive = isActive
    self.accessibilityLabel = accessibilityLabel
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Image(systemName: isActive ? icon.activeSymbol : icon.inactiveSymbol)
        .font(.system(size: symbolSize))
        .frame(width: symbolSize, height: symbolSize)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .frame(minWidth: 44, minHeight: 44)
    .accessibilityLabel(accessibilityLabel)
  }
}

struct ToggleIcon {
  let activeSymbol: String
  let inactiveSymbol: String
}
