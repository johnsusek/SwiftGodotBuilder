import SwiftGodot

/// A helper that automatically despawns its host node (the parent)
/// under common conditions:
///
/// - **Time-based expiry** via ``seconds``
/// - **Off-screen expiry** via ``offscreen`` with optional debounce ``offscreenDelay``
/// - **Pool-aware**: optionally returns the host to a pool using ``releaseToPool``
///
/// Add `AutoDespawn2D` as a **child** of the node you want to despawn. On first
/// ready, it captures `getParent()` as its *host* and manages teardown when any
/// configured condition is met. Teardown is **idempotent** (it runs once).
///
/// ### Usage
/// ```swift
/// // Free after 4 seconds or when it leaves the camera (whichever first).
/// GNode<Node2D>("Bullet") {
///   Sprite2D$().res(\.texture, "art/bullet.png")
///   GNode<AutoDespawn2D>().configure {
///     $0.seconds = 4
///     $0.offscreen = true
///   }
/// }
/// ```
@Godot
public final class AutoDespawn2D: Node {
  // MARK: Configuration

  /// Optional time-to-live (seconds).
  ///
  /// When set to a value `> 0`, the host is despawned after this many seconds
  /// have elapsed since `_ready()`.
  public var seconds: Double? = nil

  /// Enables off-screen despawn.
  ///
  /// When `true`, the host will be despawned after it leaves the visible view.
  /// See also ``offscreenDelay`` to debounce edge flicker near screen bounds.
  public var offscreen: Bool = false

  /// Optional debounce for off-screen despawn (seconds).
  ///
  /// If `> 0`, the host must remain off-screen for at least this long before
  /// despawn occurs. If `0`, despawn happens immediately on `screen_exited`.
  public var offscreenDelay: Double = 0

  /// Hook invoked exactly once just before the host is freed or returned
  /// to a pool. Use for SFX, VFX, counters, etc.
  public var onDespawn: (() -> Void)?

  /// Optional pool hook. If provided, this closure is called with the host node
  /// instead of calling `queueFree()` on the host. The component itself is
  /// still freed after the host is handled.
  public var releaseToPool: ((Node) -> Void)?

  // MARK: Internal state

  /// The node to be despawned; captured as `getParent()` in `_ready()`.
  private weak var host: Node?
  /// TTL timer (one-shot).
  private var timer: GameTimer?
  /// Off-screen debounce timer (one-shot).
  private var offscreenTimer: GameTimer?
  /// Screen visibility sensor for 2D.
  private var notifier: VisibleOnScreenNotifier2D?
  /// Guard to ensure we tear down only once.
  private var done = false

  // MARK: Lifecycle

  /// Godot ready hook: captures the host, configures timers and visibility sensor.
  ///
  /// - Important: Must be a **child** of the node you intend to despawn; the
  ///   component uses `getParent()` to identify the host.
  override public func _ready() {
    host = getParent()

    if let s = seconds, s > 0 {
      let t = GameTimer(duration: s, repeats: false)
      t.onTimeout = { [weak self] in self?.despawn() }
      t.start()
      timer = t
      setProcess(enable: true)
    }

    if offscreen {
      let n = VisibleOnScreenNotifier2D()
      n.name = "AutoDespawnNotifier"
      _ = n.screenExited.connect { [weak self] in self?.beginOffscreenCountdown() }
      _ = n.screenEntered.connect { [weak self] in self?.cancelOffscreenCountdown() }
      addChild(node: n) // child of this helper inherits host's canvas via parent chain
      notifier = n
      if offscreenDelay > 0 { offscreenTimer = GameTimer(duration: offscreenDelay, repeats: false) }
      setProcess(enable: true)
    }
  }

  /// Godot process hook: advances internal timers each frame.
  ///
  /// - Parameter delta: Elapsed seconds since last frame (from Godot).
  override public func _process(delta: Double) {
    timer?.tick(delta: delta)
    offscreenTimer?.tick(delta: delta)
  }

  // MARK: Off-screen handling

  /// Starts the off-screen debounce (or despawns immediately if no delay).
  @_documentation(visibility: private)
  private func beginOffscreenCountdown() {
    if offscreenDelay <= 0 { despawn(); return }
    offscreenTimer?.reset()
    offscreenTimer?.onTimeout = { [weak self] in self?.despawn() }
    offscreenTimer?.start()
  }

  /// Cancels an in-flight off-screen debounce when the host re-enters view.
  @_documentation(visibility: private)
  private func cancelOffscreenCountdown() {
    offscreenTimer?.stop()
    offscreenTimer?.reset()
  }

  // MARK: Despawn

  /// Performs an idempotent teardown of the host and this helper.
  ///
  /// **Order**:
  /// 1. Invoke ``onDespawn``
  /// 2. If ``releaseToPool`` is set, pass the host to it; else call `queueFree()` on the host
  /// 3. Call `queueFree()` on this component
  ///
  /// If the host has already been removed (or never existed), this method
  /// still frees the component itself.
  private func despawn() {
    if done { return }
    done = true
    onDespawn?()

    guard let h = host else { queueFree(); return }
    if let releaseToPool { releaseToPool(h) } else { h.queueFree() }
    queueFree()
  }
}
