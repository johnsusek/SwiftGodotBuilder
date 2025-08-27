//
//  Signals.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

// MARK: - Signal Modifiers

//
// These modifiers attach Godot signals to a GNode<T> in a SwiftUI-ish way.
// They create a lightweight `SignalProxy` object whose `proxy` method Godot
// calls when the signal fires. The proxy then invokes your Swift closure.
//
// Lifetime: Godot holds the `Callable` target strongly while connected.
// For `.oneShot`, we nil out the closure and free the proxy after the first call.

public extension GNode where T: Object {
  /// Connects a signal with **no arguments** to a closure.
  ///
  /// - Parameters:
  ///   - name: Signal name (e.g., `"pressed"`).
  ///   - flags: Connection flags (`.oneShot` auto-disconnects and frees the proxy after first fire).
  ///   - body: Closure invoked when the signal fires.
  ///
  /// Usage:
  /// ```swift
  /// GNode<Button>("Play")
  ///   .on("pressed") { startGame() }
  /// ```
  func on(_ name: String,
          flags: Object.ConnectFlags = [],
          _ body: @escaping () -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      if flags.contains(.oneShot) {
        // One-shot: run, then tear down the proxy to avoid future invocations.
        proxy.proxy = { [weak proxy] _ in
          body()
          guard let proxy else { return }
          proxy.proxy = nil
          _ = proxy.callDeferred(method: "free")
        }
      } else {
        proxy.proxy = { _ in body() }
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }

  /// Connects a signal with **one argument** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name (e.g., `"toggled"`).
  ///   - flags: Connection flags (`.oneShot` not auto-freed here by default—mirror the no-arg style if desired).
  ///   - body: Closure receiving the unwrapped value of type `A`.
  ///
  /// Usage:
  /// ```swift
  /// GNode<Button>("Sound")
  ///   .on("toggled") { (on: Bool) in audioEnabled = on }
  /// ```
  func on<A: VariantStorable>(_ name: String,
                              flags: Object.ConnectFlags = [],
                              _ body: @escaping (A) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        // Defensive: signals *should* provide arg[0], but don’t crash if not.
        guard args.count > 0 else {
          GD.printErr("⚠️ Signal '\(name)' provided no arguments; expected \(A.self)")
          return
        }

        // Prefer object cast when the Variant stores an engine Object.
        if let obj: Object = args[0].asObject(), let a = obj as? A {
          body(a)
          return
        }

        // Fall back to constructing from the Variant payload.
        if let a = A(args[0]) {
          body(a)
          return
        }

        GD.printErr("⚠️ Could not unwrap signal arg 0 as \(A.self); gtype=\(args[0].gtype)")
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }
}
