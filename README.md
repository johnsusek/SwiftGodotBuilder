# SwiftGodotBuilder

A declarative toolkit for building Godot scenes in Swift. It sits on top of [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) and uses Swift [result builders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders) to describe node trees as data.

> No runtime magic, no retained state. It's just a builder that emits Godot nodes.

## ✨ Features

- **Declarative scenes**: Compose Godot nodes with a SwiftUI-like syntax.
- **Type safety**: Key paths bind directly to SwiftGodot properties.
- **Modifiers**: Chain configuration calls (.position, .rotation, .scale, etc).
- **Signals**: Strongly-typed `.on(\.someSignal) { … }` handlers.
- **Actions**: Compose mouse, keyboard and joystick input actions (with recipes to reduce boilerplate).


## 📕 [API Documentation](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/)

Highlights: [GNode](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/gnode) · [Actions](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/actions)


## 🚀 Quick start

Add the package, then describe a view and materialize it:

```swift
import SwiftGodotBuilder

let view = Node2D$ {
  Sprite2D$()
    .texture("ball.png")       // loads res://ball.png
    .position(Vector2(x: 100, y: 200))

  Button$()
    .text("Start")
    .on(\.pressed) { GD.print("Game Start!") }
}

let node = view.makeNode()     // Godot.Node2D
```

Integrating into a running tree is trivial; if you're using SwiftGodotKit, see the example app in Examples/.

## 👾 Example project

```bash
brew install xcodegen
xcodegen -s Examples/project.yml
open Examples/SwiftGodotBuilderExample.xcodeproj
```

Re-implementation of the official Pong sample; shows adding a Node into a scene (with SwiftGodotKit as a host).


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

## 🏘️ Custom Classes

Given this SwiftGodot class:

```swift
@Godot
class Paddle: Area2D {
  var side = "left"

  convenience init(side: Side) {
    self.init()
    self.side = side
  }

  override func _process(delta: Double) {
    if side == "left" { ... }
  }
}
```

Use it as a view:

```swift
GNode<Paddle> {
  // ...
}
```

A `Paddle()` will be created when `makeNode()` is called.

## 🏠 Custom Instances

Pass a `make: { ... }` trailing closure to customize creation of the `Node`

```swift
GNode<Paddle> {
  // ...
} make: {
  Paddle(side: "right")
}
```

## 🧷 Refs

Reference Godot nodes in views.

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

## 🎮 Actions

Describe and install input actions into Godot's InputMap.

```swift
let inputs = Actions {
  Action("jump") {
    Key(.space)
    JoyButton(.a, device: 0)
  }

  // Axis helpers (paired actions)
  ActionRecipes.axisLR(
    namePrefix: "aim",
    device: 0,
    axis: .leftX,
    dz: 0.25,
    btnLeft: .dpadLeft,
    btnRight: .dpadRight
  )
}

inputs.install()
```

## 🔍 Conditionals & loops

All standard result-builder patterns work:

```swift
Node2D$ {
  if debug {
    Label$().text("DEBUG")
  }
  for i in 0..<rows {
    HBoxContainer$ {
      for j in 0..<cols { Sprite2D$().position(x: j*16, y: i*16) }
    }
  }
}
```

Note: this logic is not evaluated at runtime, only when `makeNode()` is called.

## ❓ FAQ

> Is this "SwiftUI for Godot"?

No. There's no @State/@Binding. It's a builder that only does work when you call makeNode().

> Does this affect runtime performance?

No. Builders are plain Swift values. Node creation happens once when you materialize.

> Where do the $ types come from?

A package plugin scans Godot's API JSON and generates `typealias Name$ = GNode<Name>`.

## 🔮 Roadmap

- More unit tests, that use Godot runtime
-	More resource helpers (audio, packed scenes)
- Example scenes/tests that run under the engine

## 📜 License

MIT
