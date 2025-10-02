//
//  GNode+Signals.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

public extension GNode where T: Object {
  /// Connects a Godot signal with no arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SimpleSignal`) from a Godot node to a Swift closure, allowing you to respond to signal emissions in Swift.
  ///
  /// - Parameters:
  ///   - kp: The key path to the signal property on the node.
  ///   - flags: Flags to control the connection behavior. Defaults to an empty set.
  ///   - body: The closure to execute when the signal is emitted. Receives the node as its only argument.
  ///
  /// - Returns: The modified `GNode` with the signal connection added.
  ///
  /// - Usage:
  ///   ```
  ///   myNode.onSignal(\.pressed) { node in
  ///       print("\(node) was pressed")
  ///   }
  ///   ```
  func onSignal(_ kp: KeyPath<T, SimpleSignal>,
                flags: Object.ConnectFlags = [],
                _ body: @escaping (T) -> Void) -> Self
  {
    var s = self
    s.ops.append { (n: T) in _ = n[keyPath: kp].connect(flags: flags) { body(n) } }
    return s
  }

  /// Connects a Godot signal with one argument to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive the argument in Swift.
  ///
  /// - Parameters:
  ///   - kp: The key path to the signal property on the node.
  ///   - flags: Flags to control the connection behavior. Defaults to an empty set.
  ///   - body: The closure to execute when the signal is emitted. Receives the node and the signal's argument.
  ///
  /// - Returns: The modified `GNode` with the signal connection added.
  ///
  /// - Usage:
  ///   ```
  ///   myNode.onSignal(\.areaEntered) { node, area in
  ///       print("Node \(node): area \(area)")
  ///   }
  ///   ```
  func onSignal<A: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in _ = n[keyPath: kp].connect(flags: flags) { a0 in body(n, a0) } }
    return s
  }

  /// Connects a Godot signal with two arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A, B>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive both arguments in Swift.
  ///
  /// - Parameters:
  ///   - kp: The key path to the signal property on the node.
  ///   - flags: Flags to control the connection behavior. Defaults to an empty set.
  ///   - body: The closure to execute when the signal is emitted. Receives the node and both signal arguments.
  ///
  /// - Returns: The modified `GNode` with the signal connection added.
  func onSignal<A: _GodotBridgeable, B: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A, B>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A, B) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in _ = n[keyPath: kp].connect(flags: flags) { a0, a1 in body(n, a0, a1) } }
    return s
  }

  /// Connects a Godot signal with three arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A, B, C>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive all three arguments in Swift.
  ///
  /// - Parameters:
  ///   - kp: The key path to the signal property on the node.
  ///   - flags: Flags to control the connection behavior. Defaults to an empty set.
  ///   - body: The closure to execute when the signal is emitted. Receives the node and the signal's three arguments.
  ///
  /// - Returns: The modified `GNode` with the signal connection added.
  func onSignal<A: _GodotBridgeable, B: _GodotBridgeable, C: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A, B, C>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A, B, C) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in
      _ = n[keyPath: kp].connect(flags: flags) { a0, a1, a2 in body(n, a0, a1, a2) }
    }
    return s
  }

  /// Connects a Godot signal with four arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A, B, C, D>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive all four arguments in Swift.
  ///
  /// - Parameters:
  ///   - kp: The key path to the signal property on the node.
  ///   - flags: Flags to control the connection behavior. Defaults to an empty set.
  ///   - body: The closure to execute when the signal is emitted. Receives the node and the signal's four arguments.
  ///
  /// - Returns: The modified `GNode` with the signal connection added.
  func onSignal<A: _GodotBridgeable, B: _GodotBridgeable, C: _GodotBridgeable, D: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A, B, C, D>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A, B, C, D) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in
      _ = n[keyPath: kp].connect(flags: flags) { a0, a1, a2, a3 in body(n, a0, a1, a2, a3) }
    }
    return s
  }

  /// Connects a Godot signal with five arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A, B, C, D, E>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive all five arguments in Swift.
  func onSignal<A: _GodotBridgeable, B: _GodotBridgeable, C: _GodotBridgeable, D: _GodotBridgeable, E: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A, B, C, D, E>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A, B, C, D, E) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in
      _ = n[keyPath: kp].connect(flags: flags) { a0, a1, a2, a3, a4 in body(n, a0, a1, a2, a3, a4) }
    }
    return s
  }

  /// Connects a Godot signal with six arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A, B, C, D, E, F>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive all six arguments in Swift.
  func onSignal<A: _GodotBridgeable, B: _GodotBridgeable, C: _GodotBridgeable, D: _GodotBridgeable, E: _GodotBridgeable, F: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A, B, C, D, E, F>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A, B, C, D, E, F) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in
      _ = n[keyPath: kp].connect(flags: flags) { a0, a1, a2, a3, a4, a5 in body(n, a0, a1, a2, a3, a4, a5) }
    }
    return s
  }

  /// Connects a Godot signal with seven arguments to a Swift closure.
  ///
  /// Use this to bind a signal (`SignalWithArguments<A, B, C, D, E, F, G>`) from a Godot node to a Swift closure, allowing you to respond to signal emissions and receive all seven arguments in Swift.
  func onSignal<A: _GodotBridgeable, B: _GodotBridgeable, C: _GodotBridgeable, D: _GodotBridgeable, E: _GodotBridgeable, F: _GodotBridgeable, G: _GodotBridgeable>(
    _ kp: KeyPath<T, SignalWithArguments<A, B, C, D, E, F, G>>,
    flags: Object.ConnectFlags = [],
    _ body: @escaping (T, A, B, C, D, E, F, G) -> Void
  ) -> Self {
    var s = self
    s.ops.append { (n: T) in
      _ = n[keyPath: kp].connect(flags: flags) { a0, a1, a2, a3, a4, a5, a6 in body(n, a0, a1, a2, a3, a4, a5, a6) }
    }
    return s
  }
}
