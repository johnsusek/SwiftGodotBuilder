import Foundation
import SwiftGodot

/// A registry for custom SwiftGodot subclasses that need to
/// be registered with the engine via `SwiftGodot.register(type:)`
///
/// - Important: You must add `GodotRegistry.append(ClassName.self)` in your GView `init`
/// to use custom classes in your views.
///
/// ### Example
/// ```swift
/// @Godot class Ball: Area2D {}
///
/// struct BallView: GView {
///  init() {
///    GodotRegistry.append(Ball.self)
///  }
///
///  var body: some GView {
///    GNode<Ball>()
///  }
/// }
/// ```
///
/// - Note: Enqueued classes are registered and dequeued when `toNode` is called.
public enum GodotRegistry {
  /// Pending types to register on the next `flush()`. Access guarded by `lock`.
  private static var queuedTypes: [Object.Type] = []

  /// Set of types already seen to prevent duplicate registration.
  private static var seen = Set<ObjectIdentifier>()

  /// Internal mutex guarding `queuedTypes` and `seen`.
  private static let lock = NSLock()

  /// Enqueues a sequence of Godot `Object` subclasses for later registration.
  ///
  /// Types already seen are ignored. Safe to call from multiple threads.
  public static func append(contentsOf ts: [Object.Type]) {
    for t in ts {
      append(t)
    }
  }

  /// Enqueues a single Godot `Object` subclass for later registration.
  ///
  /// If the type was already queued (or registered earlier), it is ignored.
  /// Safe to call from multiple threads.
  public static func append(_ t: Object.Type) {
    lock.lock()
    defer { lock.unlock() }

    let id = ObjectIdentifier(t)
    if seen.contains(id) { return }

    seen.insert(id)
    queuedTypes.append(t)
  }

  /// Registers all queued types with the Godot engine and clears the queue.
  ///
  /// - Note: Safe to call multiple times; previously seen types are skipped.
  /// - Important: Ensure the engine is initialized and ready (e.g., you can
  ///   access a valid `SceneTree`) before calling `flush()`.
  public static func flush() {
    lock.lock()
    let types = queuedTypes
    queuedTypes.removeAll()
    lock.unlock()

    for t in types {
      SwiftGodot.register(type: t)
    }
  }
}
