import SwiftUI

struct MarqueeText: View {
  let text: String
  let alignment: Alignment

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.layoutDirection) private var layoutDirection
  @State private var animate = false
  @State private var stringWidth = 0.0
  @State private var stringHeight = 0.0

  private let fadeWidth = 8.0

  private var mirror: Double {
    layoutDirection == .rightToLeft ? -1 : 1
  }

  init(_ text: String, alignment: Alignment = .leading) {
    self.text = text
    self.alignment = alignment
  }

  var body: some View {
    let animation = Animation
      .linear(duration: max(stringWidth / 30, 1))
      .delay(3)
      .repeatForever(autoreverses: false)

    ZStack {
      GeometryReader { geometry in
        if stringWidth > geometry.size.width, !reduceMotion {
          Group {
            Text(text)
              .lineLimit(1)
              .offset(x: (animate ? -stringWidth - stringHeight * 2 : 0) * mirror)
              .animation(animation, value: animate)
              .fixedSize(horizontal: true, vertical: false)

            Text(text)
              .lineLimit(1)
              .offset(x: (animate ? 0 : stringWidth + stringHeight * 2) * mirror)
              .animation(animation, value: animate)
              .fixedSize(horizontal: true, vertical: false)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .offset(x: fadeWidth * mirror)
          .mask {
            HStack(spacing: 0) {
              Color.clear.frame(width: 2)
              LinearGradient(
                colors: [.clear, .black],
                startPoint: .leading,
                endPoint: .trailing
              )
              .frame(width: fadeWidth)
              Color.black
              LinearGradient(
                colors: [.black, .clear],
                startPoint: .leading,
                endPoint: .trailing
              )
              .frame(width: fadeWidth)
              Color.clear.frame(width: 2)
            }
          }
          .frame(width: geometry.size.width + fadeWidth)
          .offset(x: -fadeWidth * mirror)
          .onAppear { animate = true }
        } else {
          Text(text)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: alignment)
            .onAppear { animate = false }
        }
      }
      .background {
        Text(text)
          .fixedSize(horizontal: true, vertical: false)
          .hidden()
          .onSizeChange { size in
            stringWidth = size.width
            stringHeight = size.height
            if !animate, !reduceMotion {
              animate = true
            }
          }
      }
    }
    .frame(height: stringHeight)
    .onChange(of: text) {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        animate = false
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(text)
  }
}
