import Foundation

/// Release information for the RadioKit package.
public enum RadioKitRelease {
  /// The package version from the bundled `VERSION` resource.
  public static let version: String = {
    guard
      let url = Bundle.module.url(forResource: "VERSION", withExtension: nil),
      let value = try? String(contentsOf: url, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines),
      value.isEmpty == false
    else {
      preconditionFailure("RadioKit VERSION resource is missing or empty")
    }

    return value
  }()
}
