//
//  CommandCenter.swift
//  RadioKit
//
//  Created by Leonid Frolov on 12.05.2023.
//

import Foundation
@preconcurrency import MediaPlayer

/// Owns the remote-command targets installed for one active player lifecycle.
@MainActor
final class CommandCenter {
  typealias Action = @MainActor @Sendable () -> Bool

  private struct Target {
    let command: MPRemoteCommand
    let token: Any
  }

  private let commandCenter = MPRemoteCommandCenter.shared()
  private var targets = [Target]()

  init(
    playAction: @escaping Action,
    pauseAction: @escaping Action,
    toggleAction: @escaping Action
  ) {
    addTarget(to: commandCenter.playCommand, action: playAction)
    addTarget(to: commandCenter.pauseCommand, action: pauseAction)
    addTarget(to: commandCenter.togglePlayPauseCommand, action: toggleAction)
  }

  isolated deinit {
    invalidate()
  }

  func invalidate() {
    for target in targets {
      target.command.removeTarget(target.token)
      target.command.isEnabled = false
    }
    targets.removeAll()
  }

  private func addTarget(to command: MPRemoteCommand, action: @escaping Action) {
    command.isEnabled = true
    let token = command.addTarget { _ in
      Self.performOnMainActor(action)
    }
    targets.append(Target(command: command, token: token))
  }

  nonisolated private static func performOnMainActor(
    _ action: @escaping Action
  ) -> MPRemoteCommandHandlerStatus {
    let succeeded: Bool
    if Thread.isMainThread {
      succeeded = MainActor.assumeIsolated {
        action()
      }
    } else {
      succeeded = DispatchQueue.main.sync {
        action()
      }
    }

    return succeeded ? .success : .commandFailed
  }
}
