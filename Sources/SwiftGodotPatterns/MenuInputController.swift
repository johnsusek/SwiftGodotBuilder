import SwiftGodot

/// A poll-driven input controller for menu navigation.
///
/// Attach this node as a **sibling** alongside your menu `Button` nodes (for
/// example, inside the same `VBoxContainer`). It discovers the immediate `Button`
/// children of its parent in order, keeps track of a focused index, and
/// performs movement/activation based on configured input actions.
@Godot
public final class MenuInputController: Node {
  // MARK: Configuration

  /// Input action used to move selection upward (previous item).
  public var upAction = StringName("menu_up")

  /// Input action used to move selection downward (next item).
  public var downAction = StringName("menu_down")

  /// Input action used to confirm/activate the currently selected item.
  public var confirmAction = StringName("menu_select")

  /// If `true`, moving past either end wraps around. Otherwise it clamps.
  public var wrapSelection = true

  // MARK: State

  /// Zero-based index of the currently selected button among the parent's
  /// immediate children.
  private var selectedIndex = 0

  /// Optional activation handlers. If present, should align with the order
  /// of discovered `Button` children.
  public var actions: [() -> Void] = []

  // MARK: Lifecycle

  /// Grabs initial focus on the configured `selectedIndex`.
  override public func _ready() {
    focusIndex(selectedIndex)
  }

  /// Polls input actions each frame and updates selection or triggers confirm.
  ///
  /// - Parameter delta: Unused here; included to satisfy Godot's signature.
  override public func _process(delta _: Double) {
    let movedUp = Input.isActionJustPressed(action: upAction)
    let movedDown = Input.isActionJustPressed(action: downAction)
    let confirming = Input.isActionJustPressed(action: confirmAction)

    if movedUp { move(-1) }
    if movedDown { move(1) }
    if confirming { activate() }
  }

  // MARK: Behavior

  /// Moves selection by `step` and updates focus.
  ///
  /// - Parameter step: Typically `+1` to move down or `-1` to move up.
  private func move(_ step: Int) {
    let bs = buttons()
    if bs.isEmpty { return }
    var next = selectedIndex + step
    if wrapSelection {
      next = (next % bs.count + bs.count) % bs.count
    } else {
      next = max(0, min(bs.count - 1, next))
    }
    selectedIndex = next
    bs[next].grabFocus()
  }

  /// Activates the current selection by invoking the aligned action, if any.
  private func activate() {
    if selectedIndex < actions.count {
      actions[selectedIndex]()
      return
    }
  }

  /// Focuses the button at index `i` (clamped) and records it as selected.
  ///
  /// - Parameter i: Desired index to focus.
  private func focusIndex(_ i: Int) {
    let bs = buttons()
    if bs.isEmpty { return }
    let clamped = max(0, min(bs.count - 1, i))
    selectedIndex = clamped
    bs[clamped].grabFocus()
  }

  /// Returns the parent's immediate children filtered to `Button`s, in order.
  ///
  /// - Returns: Array of `Button` nodes discovered from the parent.
  private func buttons() -> [Button] {
    guard let parent = getParent() else { return [] }
    let count = Int(parent.getChildCount())
    var result: [Button] = []
    result.reserveCapacity(count)
    for idx in 0 ..< count {
      if let b = parent.getChild(idx: Int32(idx)) as? Button { result.append(b) }
    }
    return result
  }
}
