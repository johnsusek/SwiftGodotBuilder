import SwiftGodot
import SwiftGodotPatterns

/// Declarative items used to assemble a text-driven menu.
///
/// You construct a menu by listing `MenuEntry` values inside a
/// ``MenuBuilder`` block passed to ``TextMenu``.
public enum MenuEntry {
  /// A focusable, activatable button row.
  ///
  /// - Parameters:
  ///   - title: Text displayed on the button.
  ///   - action: Closure invoked when the entry is confirmed/pressed.
  case button(title: String, action: () -> Void)

  /// A non-interactive label row.
  ///
  /// - Parameter text: Text to display.
  case label(text: String)

  /// Vertical spacing measured in pixels between rows.
  ///
  /// - Parameter pixels: Height of the spacer.
  case spacer(pixels: Int32)
}

/// Result builder that collects ``MenuEntry`` values to form a menu.
///
/// ```swift
/// let menu = TextMenu {
///   MenuLabel("Main Menu")
///   MenuSpacer()
///   MenuItem("Play") { startGame() }
///   MenuItem("Options") { openOptions() }
///   MenuSpacer(16)
///   MenuItem("Quit") { getTree()?.quit() }
/// }
/// ```
@resultBuilder
public enum MenuBuilder {
  public static func buildBlock(_ parts: [MenuEntry]...) -> [MenuEntry] { parts.flatMap { $0 } }
  public static func buildExpression(_ e: MenuEntry) -> [MenuEntry] { [e] }
  public static func buildExpression(_ es: [MenuEntry]) -> [MenuEntry] { es }
  public static func buildOptional(_ es: [MenuEntry]?) -> [MenuEntry] { es ?? [] }
  public static func buildEither(first: [MenuEntry]) -> [MenuEntry] { first }
  public static func buildEither(second: [MenuEntry]) -> [MenuEntry] { second }
  public static func buildArray(_ arr: [[MenuEntry]]) -> [MenuEntry] { arr.flatMap { $0 } }
}

// MARK: - Builder sugar

/// Creates a button entry with a title and activation handler.
///
/// - Parameters:
///   - title: Text for the button.
///   - action: Closure invoked on confirm/press.
///
/// ```swift
/// MenuItem("Start") { startGame() }
/// ```
@inlinable public func MenuItem(_ title: String, _ action: @escaping () -> Void) -> MenuEntry { .button(title: title, action: action) }

/// Creates a non-interactive label entry.
///
/// - Parameter text: Text for the label.
///
/// ```swift
/// MenuLabel("Settings")
/// ```
@inlinable public func MenuLabel(_ text: String) -> MenuEntry { .label(text: text) }

/// Creates a vertical spacer entry.
///
/// - Parameter pixels: Height in pixels (default 8).
///
/// ```swift
/// MenuSpacer(24)
/// ```
@inlinable public func MenuSpacer(_ pixels: Int32 = 8) -> MenuEntry { .spacer(pixels: pixels) }

/// A text-based vertical menu composed from ``MenuEntry`` values.
///
/// This component builds a centered `VBoxContainer` of labels, spacers, and
/// focusable buttons. It installs a ``MenuInputController`` node to handle
/// navigation (up/down) and confirmation using the input actions
/// `menu_up`, `menu_down`, `menu_select`.
///
/// ### Example
/// ```swift
/// let menu = TextMenu(fontSize: 28) {
///   MenuLabel("Game Title")
///   MenuSpacer(12)
///   MenuItem("Play") { startGame() }
///   MenuItem("Options") { openOptions() }
///   MenuSpacer(12)
///   MenuItem("Quit") { getTree()?.quit() }
/// }
/// ```
///
/// ### Input actions
/// Provide your own action names if your project uses different mappings:
/// ```swift
/// TextMenu(upAction: "ui_up", downAction: "ui_down", confirmAction: "ui_accept") {
///   MenuItem("Continue") { resume() }
/// }
/// ```
public struct TextMenu: GView {
  /// The list of declarative entries composing the menu.
  let entries: [MenuEntry]

  /// Base font size for rows (currently informational; style integration may vary).
  let fontSize: Int32

  /// Input action name used to move selection upward.
  let upActionName: String

  /// Input action name used to move selection downward.
  let downActionName: String

  /// Input action name used to confirm the current selection.
  let confirmActionName: String

  /// Whether selection wraps when moving past the first/last item.
  let wrapSelection: Bool

  /// Creates a text menu from a list of declarative entries.
  ///
  /// - Parameters:
  ///   - fontSize: Base font size for menu text. Default `24`.
  ///   - upAction: Input action name for “move up”. Default `"menu_up"`.
  ///   - downAction: Input action name for “move down”. Default `"menu_down"`.
  ///   - confirmAction: Input action name for “confirm”. Default `"menu_select"`.
  ///   - wrap: If `true`, selection wraps around at ends. Default `true`.
  ///   - content: ``MenuBuilder`` block returning menu entries.
  public init(fontSize: Int32 = 24,
              upAction: String = "menu_up",
              downAction: String = "menu_down",
              confirmAction: String = "menu_select",
              wrap: Bool = true,
              @MenuBuilder _ content: () -> [MenuEntry])
  {
    entries = content()
    self.fontSize = fontSize
    upActionName = upAction
    downActionName = downAction
    confirmActionName = confirmAction
    wrapSelection = wrap
    GodotRegistry.append(MenuInputController.self)
  }

  /// Builds a centered vertical layout of the menu entries and an input controller.
  ///
  /// The view returns:
  /// - `CenterContainer` → `VBoxContainer` containing rows for each entry.
  /// - A trailing `MenuInputController` node configured with action names and
  ///   the collected button callbacks.
  ///
  /// The root anchors to `.fullRect` and uses `.fill` size flags so it expands
  /// to its parent.
  public var body: some GView {
    var buttonActions: [() -> Void] = []
    var items: [any GView] = []

    for e in entries {
      switch e {
      case let .button(title, action):
        let button = Button$()
          .text(title)
          .focusMode(Control.FocusMode.all) // must be focusable
          .on(\.pressed) { _ in action() }
        buttonActions.append(action)
        items.append(button)

      case let .label(text):
        let label = Label$().text(text)
        items.append(label)

      case let .spacer(px):
        let spacer = Control$().customMinimumSize(Vector2(1, Float(px)))
        items.append(spacer)
      }
    }

    return CenterContainer$ {
      VBoxContainer$ {
        items

        GNode<MenuInputController>()
          .configure { c in
            c.upAction = StringName(upActionName)
            c.downAction = StringName(downActionName)
            c.confirmAction = StringName(confirmActionName)
            c.wrapSelection = wrapSelection
            c.actions = buttonActions
          }
      }
    }
    .sizeFlagsVertical(.fill)
    .sizeFlagsHorizontal(.fill)
    .configure { $0.setAnchorsPreset(.fullRect) }
  }
}
