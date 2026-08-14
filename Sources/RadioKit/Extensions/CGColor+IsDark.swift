//  RadioKit
//  CGColor+IsDark.swift
//
//
//  Created by Leonid Frolov on 23.08.2023.
//

#if canImport(UIKit)
  import UIKit
#elseif os(macOS)
  import Cocoa
#endif

extension CGColor {
  /// Whether the color reads as dark based on its perceived luminance, or `nil` if it cannot be evaluated.
  /// - Complexity: O(1), but converts the color through `CIColor`, which is more expensive than a stored property.
  public var isDark: Bool? {
    #if canImport(UIKit)
      let platformColor = PlatformColor(cgColor: self)
      let ciColor = CIColor(color: platformColor)
    #elseif os(macOS)
      guard
        let platformColor = PlatformColor(cgColor: self),
        let ciColor = CIColor(color: platformColor)
      else {
        return nil
      }
    #endif

    let luminance = 0.299 * ciColor.red + 0.587 * ciColor.green + 0.114 * ciColor.blue

    if luminance < 0.4 {
      return true
    } else {
      return false
    }
  }
}
