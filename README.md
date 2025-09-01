# SwiftGodotBuilder

A declarative framework for making Godot games, built on [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) and Swift [ResultBuilders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders).

## ✨ Features

- **Declarative scenes**: Build Godot nodes as Swift values that realize into engine objects.
- **Type safety**: Swift generics & key paths bind directly to Godot properties.
- **Modifiers**: Chain configuration calls (.position, .rotation, .scale, etc).
- **Signals**: Closure-based signal connections with typed signals and args.
- **Actions**: Declare actions and bindings, then install into Godot's InputMap (with recipes to reduce boilerplate).

## 📕 [API Documentation](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/)

Most useful: [GNode](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/gnode), [Actions](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/actions)

## 📄 Usage

Add this package to your project, write a view, and make it a node:

```swift
import SwiftGodotBuilder

let view = Node2D$ { /* ... */ }
let node = view.makeNode() // SwiftGodot.Node2D
```

Check out the [Pong Sample](https://github.com/johnsusek/SwiftGodotBuilder-Pong/blob/main/SwiftGodotBuilder-Pong/SwiftGodotBuilder_PongApp.swift#L16) for a way to add a SwiftGodot `Node` to a scene with [SwiftGodotKit](https://github.com/migueldeicaza/SwiftGodotKit).


## 👾 Examples

```bash
brew install xcodegen
xcodegen -s Examples/project.yml
open Examples/SwiftGodotBuilderExample.xcodeproj
```

See also: [Pong Sample](https://github.com/johnsusek/SwiftGodotBuilder-Pong)

## 🪟 Views

Use the `$` suffix on **any subclass** of `Node` to build views.

```swift
let view = Node2D$ {
  Sprite2D$()
    .texture("ball.png")
    .position(x: 100, y: 200)

  Button$()
    .text("Start")
    .on(\.pressed) { GD.print("Game Start!") }
}

// Create the actual Godot node tree:
let node = view.makeNode()
```

## 🎨 Modifiers

**All settable properties** on SwiftGodot nodes can be used as chainable modifiers.

```swift
Node2D$()
  .position(Vector2(x: 20, y: 20))
  .scale(Vector2(x: 0.5, y: 0.5))
  .rotation(0.25)
```

## 🍓 Resources

Special modifiers that make working with resources easier.

- `.texture(String)` - path to a project-imported resource, **prefixes res:// automatically**

## 📡 Signals

Attach Godot signals declaratively.

```swift
Button$()
  .text("Toggle Sound")
  .on(\.toggled) { isOn in
    GD.print("Sound is now", isOn ? "ON" : "OFF")
  }
```

## 🔗 Refs

Reference Godot nodes in signal handlers.

```swift
let label = Ref<Label>()

VBoxContainer$ {
  Label$()
    .text("Lives: 0")
    .ref(label)

  Button$()
    .text("❤️")
    .on(\.pressed) { _ in
      guard let l = label.node else { return }
      l.text = "Lives: 1"
    }
}
```

## 🏃‍♂️ Actions

Declare and register input actions.

```swift
let inputs = Actions {
  Action("jump") {
    Key(.space)
    JoyButton(.a, device: 0)
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

// Install them into Godot
inputs.install()
```

## 🙋 FAQ

> Is this "SwiftUI for Godot"?

**No**. SwiftGodotBuilder has no @State or @Binding. The only thing in common is the use of [ResultBuilders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders).

> Will this slow my game down?

**No**. There is no runtime behavior **at all** _until you call `makeNode()`_.

## 🔮 Roadmap

- More unit tests, that use Godot runtime
- Example app
- More resource handlers (sounds, etc)

## 📜 Core Values

- Never interfere with a game's runtime performance.
- Simple games should be simple to make, complex games still possible.

## License

MIT
