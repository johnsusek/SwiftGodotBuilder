# SwiftGodotBuilder

A declarative framework for making Godot games, built on [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) and Swift [ResultBuilders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders).

## ✨ Features
- **Declarative scenes**: Build Godot nodes as Swift values that realize into engine objects.
- **Type safety**: Swift generics & key paths bind directly to Godot properties.
- **Modifiers**: Chain configuration calls (.position, .rotation, .scale, etc).
- **Signals**: Closure-based signal connections with typed signals and args.
- **Actions**: Declare actions and bindings, then install into Godot's InputMap (with recipes to reduce boilerplate).

## 📕 [Documentation](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/)

## 👾 [Sample Game](https://github.com/johnsusek/SwiftGodotBuilder-Pong)

## 📄 Usage

Add this package to your project, import it, and make a node:

```swift
import SwiftGodotBuilder

let view = Node2D$ {}
let node = view.makeNode()
scene.root?.addChild(node: node)
```

Check out [SwiftGodotBuilder_PongApp.swift](https://github.com/johnsusek/SwiftGodotBuilder-Pong/blob/main/SwiftGodotBuilder-Pong/SwiftGodotBuilder_PongApp.swift) for usage with [SwiftGodotKit](https://github.com/migueldeicaza/SwiftGodotKit).

## 🌳 Nodes

```swift
import SwiftGodot
import SwiftGodotBuilder

let gameScene = Node2D$("Game") {
  Sprite2D$("Ball")
    .texture("ball.png")
    .position(x: 100, y: 200)

  Button$("Play")
    .text("Start")
    .on(\.pressed) { GD.print("Game Start!") }
}

// Create the actual Godot node tree:
let root = gameScene.makeNode()
```

This builds a Node2D named Game, with a Sprite2D and a Button as children.

## 🏃‍♂️ Actions
Declare actions in Swift and register them with InputMap.

```swift
import SwiftGodot
import SwiftGodotBuilder

let inputs = Actions {
  // A simple action
  Action("jump") {
    Key(.space)
  }

  ActionGroup {
    Action("move_left", deadzone: 0.2) {
      JoyAxis(0, .leftX, -1.0)
      Key(.a)
    }
    Action("move_right", deadzone: 0.2) {
      JoyAxis(0, .leftX, 1.0)
      Key(.d)
    }
  }

  // Ready-made helpers for axis pairs
  ActionRecipes.axisLR(
    namePrefix: "aim",
    device: 0,
    axis: .leftX,
    dz: 0.25,
    btnLeft: .dpadLeft,
    btnRight: .dpadRight
  )
}

// Install them into Godot (optionally clearing any existing bindings)
inputs.install(clearExisting: true)
```

- Action(...) creates a named action with optional deadzone and a list of events.
- Events:
  - Key(_ key)
  - JoyButton(device, button)
  - JoyAxis(device, axis, value) where value is −1.0…1.0
  - MouseButton(index)
- Group multiple actions inline with ActionGroup { ... }.
- Recipes: ActionRecipes.axisUD(...) and ActionRecipes.axisLR(...) generate up/down or left/right actions for a given joy axis, including optional key/button aliases and shared deadzones.


## 📡 Signals
Attach Godot signals declaratively.

```swift
Button$("Sound")
  .text("Toggle Sound")
  .on(\.toggled) { isOn in
    GD.print("Sound is now", isOn ? "ON" : "OFF")
  }
```

## 🎨 Modifiers
Selected modifiers available on node wrappers (via GNode<T>):

- CanvasItem: .modulate(Color), .zIndex(Int32), .visible(Bool)
- Node2D: .position(Vector2) / .position(x:y:), .rotation(Double), .scale(Vector2), .skew(Double), .transform(Transform2D)
- Camera2D: .offset(Vector2) / .offset(x:y:), .zoom(Vector2)
- Sprite2D: .texture(String), .flipH(Bool), .flipV(Bool), .frame(Int)
- CollisionShape2D: .shape(RectangleShape2D)
- ColorRect: .color(Color)
- Label: .text(String)
- Button: .text(String)

Texture loading notes:
- .texture("ball.png") expects a project-imported resource; the modifier prefixes res:// automatically (e.g., res://ball.png).


## 🙋 FAQ

> Is this "SwiftUI for Godot"?

**No**. SwiftGodotBuilder has no @State or @Binding. The only thing in common is the use of [ResultBuilders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders).

> Will this slow my game down?

**No**. There is no runtime behavior **at all** _until you call `makeNode()`_.

## 🔮 Roadmap
- Generate comprehensive node wrappers for all Godot classes — a few common ones are aliased today (see [Sources/SwiftGodotBuilder/Builtins.swift](Sources/SwiftGodotBuilder/Builtins.swift)).
- More modifiers for common cases.
- More unit tests, that use Godot runtime
- Unify GView/Node modifiers (e.g. .position right now)

## 🤝 Contributing
PRs welcome. Open issues for design feedback.


## 📜 License
MIT
