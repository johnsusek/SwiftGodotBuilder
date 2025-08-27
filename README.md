# SwiftGodotBuilder

SwiftUI-inspired library for making Godot games, built on [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot).

## ✨ Features
- Declarative scenes: Build Godot nodes as Swift values that realize into engine objects.
- Modifiers: Chain configuration calls (.position, .rotation, .scale, .modulate, .texture, .flipH, .flipV, .frame, .color, .zIndex, .visible, .offset, .zoom, .text).
- Signals: Closure-based signal connections with typed args.
- Input Actions: Declare actions and bindings, then install into Godot's InputMap (with deadzones and recipes).
- Type safety: Swift generics & key paths bind directly to Godot properties.

## 📕 [Documentation](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/)
## 🎭 Scenes

```swift
import SwiftGodot
import SwiftGodotBuilder

let gameScene = Scene {
  Node2D$("Game") {
    Sprite2D$("Ball")
      .texture("ball.png")
      .position(x: 100, y: 200)

    Button$("Play")
      .text("Start")
      .on("pressed") { GD.print("Game Start!") }
  }
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

// Build a set of actions
let inputs = Actions {
  Action("jump") { Key(.space) }

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
  .on("toggled") { (on: Bool) in
    GD.print("Sound is now", on ? "ON" : "OFF")
  }

Button$("Play")
  .on("pressed", flags: [.oneShot]) { startGame() } // auto-disconnect after first fire
```

- No-arg signals: .on("pressed") { … }
- One-arg signals (typed): .on("toggled") { (Bool) in … }
- One-shot: pass flags: [.oneShot] to auto-disconnect after the first invocation.


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


## 📦 Installation
Add to your Swift package:

```swift
dependencies: [
  .package(url: "https://github.com/YOURNAME/SwiftGodotBuilder.git", branch: "main"),
]
```

Then import it:

```swift
import SwiftGodotBuilder

let gameScene = Scene { ... }
```

And add it in your runGodot loadScene hook:

```swift
func loadScene(scene: SceneTree) {
    let gameSceneNode = gameScene.makeNode()
    scene.root?.addChild(node: gameSceneNode)
}
```


## 🔮 Roadmap
- Generate comprehensive node wrappers for all Godot classes — a few common ones are aliased today (see [Sources/SwiftGodotBuilder/Builtins.swift](Sources/SwiftGodotBuilder/Builtins.swift)).
- More modifiers.
- 2+ arg signals.
- Update BuildContext with more asset types.


## 🤝 Contributing
PRs welcome. Open issues for design feedback.


## 📜 License
MIT
