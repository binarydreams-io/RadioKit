//  RadioKit
//  OSTypeAliases.swift
//
//
//  Created by Leonid Frolov on 26.08.2023.
//

#if canImport(UIKit)
  import UIKit

  typealias PlatformImage = UIImage
  typealias PlatformColor = UIColor
#elseif canImport(Cocoa)
  import Cocoa

  typealias PlatformImage = NSImage
  typealias PlatformColor = NSColor
#endif
