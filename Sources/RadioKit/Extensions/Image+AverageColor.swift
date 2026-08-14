//  RadioKit
//  Image+AverageColor.swift
//
//
//  Created by Leonid Frolov on 23.08.2023.
//

#if canImport(UIKit)
  import UIKit
#elseif os(macOS)
  import Cocoa
#endif

#if canImport(UIKit)
  extension UIImage {
    /// The average color of the image, or `nil` if it cannot be computed.
    /// - Complexity: O(*n*) in the number of pixels. The image renders through a Core
    ///   Image area-average filter, so do not call this repeatedly, and keep it off
    ///   the main thread for large images.
    public var averageColor: CGColor? {
      averageColorValue
    }
  }

#elseif os(macOS)
  extension NSImage {
    /// The average color of the image, or `nil` if it cannot be computed.
    /// - Complexity: O(*n*) in the number of pixels. The image renders through a Core
    ///   Image area-average filter, so do not call this repeatedly, and keep it off
    ///   the main thread for large images.
    public var averageColor: CGColor? {
      averageColorValue
    }
  }
#endif

extension PlatformImage {
  /// Shared implementation backing the public `averageColor` property.
  fileprivate var averageColorValue: CGColor? {
    #if canImport(UIKit)
      guard let inputImage = CIImage(image: self) else { return nil }
    #elseif os(macOS)
      guard let inputImage = asCIImage() else { return nil }
    #endif

    let extentVector = CIVector(
      x: inputImage.extent.origin.x,
      y: inputImage.extent.origin.y,
      z: inputImage.extent.size.width,
      w: inputImage.extent.size.height
    )

    guard
      let filter = CIFilter(
        name: "CIAreaAverage",
        parameters: [
          kCIInputImageKey: inputImage,
          kCIInputExtentKey: extentVector,
        ]
      )
    else { return nil }

    guard let outputImage = filter.outputImage else { return nil }

    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
    context.render(
      outputImage,
      toBitmap: &bitmap,
      rowBytes: 4,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
      format: .RGBA8,
      colorSpace: nil
    )

    return CGColor(
      red: CGFloat(bitmap[0]) / 255,
      green: CGFloat(bitmap[1]) / 255,
      blue: CGFloat(bitmap[2]) / 255,
      alpha: CGFloat(bitmap[3]) / 255
    )
  }
}

#if os(macOS)
  extension NSImage {
    /// The image as a `CIImage`, built from the best available representation.
    fileprivate func asCIImage() -> CIImage? {
      if let cgImage = asCGImage() {
        return CIImage(cgImage: cgImage)
      }
      return nil
    }

    /// The image as a `CGImage`, using the representation that best fits its size.
    fileprivate func asCGImage() -> CGImage? {
      var rect = NSRect(origin: CGPoint(x: 0, y: 0), size: size)
      return cgImage(forProposedRect: &rect, context: NSGraphicsContext.current, hints: nil)
    }
  }
#endif
