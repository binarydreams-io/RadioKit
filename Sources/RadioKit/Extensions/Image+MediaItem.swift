//  RadioKit
//  Image+MediaItem.swift
//
//
//  Created by Leonid Frolov on 13.11.2023.
//

import MediaPlayer

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

#if canImport(UIKit)
  extension UIImage {
    /// A Now Playing artwork wrapper that renders this image at any requested size.
    public var artwork: MPMediaItemArtwork {
      MPMediaItemArtwork(boundsSize: size) { _ in self }
    }
  }

#elseif canImport(AppKit)
  extension NSImage {
    /// A Now Playing artwork wrapper that renders this image at any requested size.
    public var artwork: MPMediaItemArtwork {
      MPMediaItemArtwork(boundsSize: size) { _ in self }
    }
  }
#endif
