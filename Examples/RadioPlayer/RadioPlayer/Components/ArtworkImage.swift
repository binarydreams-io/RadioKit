import SwiftUI

struct ArtworkImage: View {
  let url: URL?
  var cornerRadius: Double = 12

  var body: some View {
    AsyncImage(
      url: url,
      transaction: Transaction(animation: .easeInOut(duration: 0.25))
    ) { phase in
      switch phase {
      case let .success(image):
        image
          .resizable()
          .scaledToFill()
          .transition(.opacity)

      case .empty:
        ZStack {
          Color.white.opacity(0.12)
          ProgressView()
            .accessibilityLabel("Loading artwork")
        }

      case .failure:
        ZStack {
          Color.white.opacity(0.12)
          Image(systemName: "antenna.radiowaves.left.and.right")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }

      @unknown default:
        Color.clear
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .clipShape(.rect(cornerRadius: cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(.white.opacity(0.18), lineWidth: 0.5)
        .accessibilityHidden(true)
    }
  }
}
