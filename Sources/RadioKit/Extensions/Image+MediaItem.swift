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
    public var mediaItemArtwork: MPMediaItemArtwork {
      MPMediaItemArtwork(boundsSize: size) { _ in self }
    }

    /// The previous name of `mediaItemArtwork`.
    @available(*, deprecated, renamed: "mediaItemArtwork")
    public var artwork: MPMediaItemArtwork {
      mediaItemArtwork
    }
  }

#elseif canImport(AppKit)
  extension NSImage {
    /// A Now Playing artwork wrapper that renders this image at any requested size.
    public var mediaItemArtwork: MPMediaItemArtwork {
      MPMediaItemArtwork(boundsSize: size) { _ in self }
    }

    /// The previous name of `mediaItemArtwork`.
    @available(*, deprecated, renamed: "mediaItemArtwork")
    public var artwork: MPMediaItemArtwork {
      mediaItemArtwork
    }
  }
#endif
