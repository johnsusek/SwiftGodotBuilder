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

  /// Connects a signal with **two arguments** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name (e.g., `"toggled"`).
  ///   - flags: Connection flags (`.oneShot` not auto-freed here by default—mirror the no-arg style if desired).
  ///   - body: Closure receiving the unwrapped value of type `A`.
  func on<A: VariantStorable, B: VariantStorable>(_ name: String,
                                                  flags: Object.ConnectFlags = [],
                                                  _ body: @escaping (A, B) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        guard args.count > 1 else {
          GD.printErr("⚠️ Signal '\(name)' provided \(args.count) arguments; expected 2: \(A.self), \(B.self)")
          return
        }

        let a0: A? = {
          if let obj: Object = args[0].asObject(), let cast = obj as? A { return cast }
          return A(args[0])
        }()
        let a1: B? = {
          if let obj: Object = args[1].asObject(), let cast = obj as? B { return cast }
          return B(args[1])
        }()

        guard let a = a0, let b = a1 else {
          GD.printErr("⚠️ Could not unwrap signal args as (\(A.self), \(B.self)); gtypes=(\(args[0].gtype), \(args[1].gtype))")
          return
        }

        body(a, b)
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }

  /// Connects a signal with **three arguments** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name.
  ///   - flags: Connection flags.
  ///   - body: Closure receiving `(A, B, C)`.
  func on<A: VariantStorable, B: VariantStorable, C: VariantStorable>(_ name: String,
                                                                      flags: Object.ConnectFlags = [],
                                                                      _ body: @escaping (A, B, C) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        guard args.count > 2 else {
          GD.printErr("⚠️ Signal '\(name)' provided \(args.count) arguments; expected 3: \(A.self), \(B.self), \(C.self)")
          return
        }

        let a0: A? = {
          if let obj: Object = args[0].asObject(), let cast = obj as? A { return cast }
          return A(args[0])
        }()
        let a1: B? = {
          if let obj: Object = args[1].asObject(), let cast = obj as? B { return cast }
          return B(args[1])
        }()
        let a2: C? = {
          if let obj: Object = args[2].asObject(), let cast = obj as? C { return cast }
          return C(args[2])
        }()

        guard let a = a0, let b = a1, let c2 = a2 else {
          GD.printErr("⚠️ Could not unwrap signal args as (\(A.self), \(B.self), \(C.self)); gtypes=(\(args[0].gtype), \(args[1].gtype), \(args[2].gtype))")
          return
        }

        body(a, b, c2)
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }

  /// Connects a signal with **four arguments** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name.
  ///   - flags: Connection flags.
  ///   - body: Closure receiving `(A, B, C, D)`.
  func on<A: VariantStorable, B: VariantStorable, C: VariantStorable, D: VariantStorable>(_ name: String,
                                                                                          flags: Object.ConnectFlags = [],
                                                                                          _ body: @escaping (A, B, C, D) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        guard args.count > 3 else {
          GD.printErr("⚠️ Signal '\(name)' provided \(args.count) arguments; expected 4: \(A.self), \(B.self), \(C.self), \(D.self)")
          return
        }

        let a0: A? = {
          if let obj: Object = args[0].asObject(), let cast = obj as? A { return cast }
          return A(args[0])
        }()
        let a1: B? = {
          if let obj: Object = args[1].asObject(), let cast = obj as? B { return cast }
          return B(args[1])
        }()
        let a2: C? = {
          if let obj: Object = args[2].asObject(), let cast = obj as? C { return cast }
          return C(args[2])
        }()
        let a3: D? = {
          if let obj: Object = args[3].asObject(), let cast = obj as? D { return cast }
          return D(args[3])
        }()

        guard let a = a0, let b = a1, let c2 = a2, let d = a3 else {
          GD.printErr("⚠️ Could not unwrap signal args as (\(A.self), \(B.self), \(C.self), \(D.self)); gtypes=(\(args[0].gtype), \(args[1].gtype), \(args[2].gtype), \(args[3].gtype))")
          return
        }

        body(a, b, c2, d)
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }

  /// Connects a signal with **five arguments** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name.
  ///   - flags: Connection flags.
  ///   - body: Closure receiving `(A, B, C, D, E)`.
  func on<A: VariantStorable, B: VariantStorable, C: VariantStorable, D: VariantStorable, E: VariantStorable>(_ name: String,
                                                                                                              flags: Object.ConnectFlags = [],
                                                                                                              _ body: @escaping (A, B, C, D, E) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        guard args.count > 4 else {
          GD.printErr("⚠️ Signal '\(name)' provided \(args.count) arguments; expected 5: \(A.self), \(B.self), \(C.self), \(D.self), \(E.self)")
          return
        }

        let a0: A? = {
          if let obj: Object = args[0].asObject(), let cast = obj as? A { return cast }
          return A(args[0])
        }()
        let a1: B? = {
          if let obj: Object = args[1].asObject(), let cast = obj as? B { return cast }
          return B(args[1])
        }()
        let a2: C? = {
          if let obj: Object = args[2].asObject(), let cast = obj as? C { return cast }
          return C(args[2])
        }()
        let a3: D? = {
          if let obj: Object = args[3].asObject(), let cast = obj as? D { return cast }
          return D(args[3])
        }()
        let a4: E? = {
          if let obj: Object = args[4].asObject(), let cast = obj as? E { return cast }
          return E(args[4])
        }()

        guard let a = a0, let b = a1, let c2 = a2, let d = a3, let e = a4 else {
          GD.printErr("⚠️ Could not unwrap signal args as (\(A.self), \(B.self), \(C.self), \(D.self), \(E.self)); gtypes=(\(args[0].gtype), \(args[1].gtype), \(args[2].gtype), \(args[3].gtype), \(args[4].gtype))")
          return
        }

        body(a, b, c2, d, e)
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }

  /// Connects a signal with **six arguments** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name.
  ///   - flags: Connection flags.
  ///   - body: Closure receiving `(A, B, C, D, E, F)`.
  func on<A: VariantStorable, B: VariantStorable, C: VariantStorable, D: VariantStorable, E: VariantStorable, F: VariantStorable>(_ name: String,
                                                                                                                                  flags: Object.ConnectFlags = [],
                                                                                                                                  _ body: @escaping (A, B, C, D, E, F) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        guard args.count > 5 else {
          GD.printErr("⚠️ Signal '\(name)' provided \(args.count) arguments; expected 6: \(A.self), \(B.self), \(C.self), \(D.self), \(E.self), \(F.self)")
          return
        }

        let a0: A? = {
          if let obj: Object = args[0].asObject(), let cast = obj as? A { return cast }
          return A(args[0])
        }()
        let a1: B? = {
          if let obj: Object = args[1].asObject(), let cast = obj as? B { return cast }
          return B(args[1])
        }()
        let a2: C? = {
          if let obj: Object = args[2].asObject(), let cast = obj as? C { return cast }
          return C(args[2])
        }()
        let a3: D? = {
          if let obj: Object = args[3].asObject(), let cast = obj as? D { return cast }
          return D(args[3])
        }()
        let a4: E? = {
          if let obj: Object = args[4].asObject(), let cast = obj as? E { return cast }
          return E(args[4])
        }()
        let a5: F? = {
          if let obj: Object = args[5].asObject(), let cast = obj as? F { return cast }
          return F(args[5])
        }()

        guard let a = a0, let b = a1, let c2 = a2, let d = a3, let e = a4, let f = a5 else {
          GD.printErr("⚠️ Could not unwrap signal args as (\(A.self), \(B.self), \(C.self), \(D.self), \(E.self), \(F.self)); gtypes=(\(args[0].gtype), \(args[1].gtype), \(args[2].gtype), \(args[3].gtype), \(args[4].gtype), \(args[5].gtype))")
          return
        }

        body(a, b, c2, d, e, f)
      }

      _ = n.connect(
        signal: StringName(name),
        callable: .init(object: proxy, method: SignalProxy.proxyName),
        flags: UInt32(flags.rawValue)
      )
    }
    return c
  }

  /// Connects a signal with **seven arguments** to a typed closure.
  ///
  /// - Parameters:
  ///   - name: Signal name.
  ///   - flags: Connection flags.
  ///   - body: Closure receiving `(A, B, C, D, E, F, G)`.
  func on<A: VariantStorable, B: VariantStorable, C: VariantStorable, D: VariantStorable, E: VariantStorable, F: VariantStorable, G: VariantStorable>(_ name: String,
                                                                                                                                                      flags: Object.ConnectFlags = [],
                                                                                                                                                      _ body: @escaping (A, B, C, D, E, F, G) -> Void) -> Self
  {
    var c = self
    c.ops.append { n, _ in
      let proxy = SignalProxy()

      proxy.proxy = { args in
        guard args.count > 6 else {
          GD.printErr("⚠️ Signal '\(name)' provided \(args.count) arguments; expected 7: \(A.self), \(B.self), \(C.self), \(D.self), \(E.self), \(F.self), \(G.self)")
          return
        }

        let a0: A? = {
          if let obj: Object = args[0].asObject(), let cast = obj as? A { return cast }
          return A(args[0])
        }()
        let a1: B? = {
          if let obj: Object = args[1].asObject(), let cast = obj as? B { return cast }
          return B(args[1])
        }()
        let a2: C? = {
          if let obj: Object = args[2].asObject(), let cast = obj as? C { return cast }
          return C(args[2])
        }()
        let a3: D? = {
          if let obj: Object = args[3].asObject(), let cast = obj as? D { return cast }
          return D(args[3])
        }()
        let a4: E? = {
          if let obj: Object = args[4].asObject(), let cast = obj as? E { return cast }
          return E(args[4])
        }()
        let a5: F? = {
          if let obj: Object = args[5].asObject(), let cast = obj as? F { return cast }
          return F(args[5])
        }()
        let a6: G? = {
          if let obj: Object = args[6].asObject(), let cast = obj as? G { return cast }
          return G(args[6])
        }()

        guard let a = a0, let b = a1, let c2 = a2, let d = a3, let e = a4, let f = a5, let g = a6 else {
          GD.printErr("⚠️ Could not unwrap signal args as (\(A.self), \(B.self), \(C.self), \(D.self), \(E.self), \(F.self), \(G.self)); gtypes=(\(args[0].gtype), \(args[1].gtype), \(args[2].gtype), \(args[3].gtype), \(args[4].gtype), \(args[5].gtype), \(args[6].gtype))")
          return
        }

        body(a, b, c2, d, e, f, g)
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
