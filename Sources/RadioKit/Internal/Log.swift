//
//  Log.swift
//  RadioKit
//
//  Created by Leonid Frolov on 19.05.2023.
//

import Foundation
import os

/// A thin wrapper around `os.Logger` for the package's internal diagnostics.
enum Log {
  private static let logger = Logger(
    subsystem: "io.binarydreams.RadioKit",
    category: "RadioKit"
  )
}

// MARK: - Methods

extension Log {
  static func debug(_ message: String) {
    logger.debug("\(message)")
  }

  static func info(_ message: String) {
    logger.info("\(message)")
  }

  static func error(_ message: String) {
    logger.error("\(message)")
  }
}
