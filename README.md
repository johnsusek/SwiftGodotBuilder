
<a href="#"><img src="media/ludi.png?raw=true" width="250" align="right" title="Ludi (Latin plural) were public games held for the benefit and entertainment of the Roman people (populus Romanus). Pictured: Ancient Roman Gamers"></a>

### SwiftGodotBuilder

A declarative toolkit for building [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) games, companion to [SwiftGodotPatterns](https://github.com/johnsusek/SwiftGodotPatterns).

Build Godot node trees with a SwiftUI-like syntax. Chain configuration calls, resource loaders, signal handlers and more in a familiar syntax.

> _Simple games should be simple to make._


#### 📕 [API Documentation](https://swiftpackageindex.com/johnsusek/SwiftGodotBuilder/documentation/swiftgodotbuilder)

<br><br>

### 📓 Introduction

Instead of:

```swift
let label = Label()
label.text = "Hello, World"
let canvas = CanvasLayer()
canvas.addChild(node: label)
```

You can write:

```swift
CanvasLayer$ {
  Label$().text("Hello, World")
}
```

#### 🚀 Get Started

The [SwiftGodotBuilderExample](https://github.com/johnsusek/SwiftGodotBuilderExample) repository contains a project with various samples.

Includes **Pong**, **Breakout**, **Space Invaders**, and many more.

#### 👨‍💻 VSCode Extension

Use the [SwiftGodotHelper](https://marketplace.visualstudio.com/items?itemName=JohnSusek.swiftgodot) extension for environment checks, build tasks, and more.

### 🪟 Views

> _Views **describe** your nodes, like a `.tscn` file, but using code._

**All subclasses of `Node`** can be suffixed with `$` to build views.

```swift
let view = Node2D$ {
  Sprite2D$()
    .res(\.texture, "ball.png")
    .position(x: 100, y: 200)

  Button$()
    .text("Start")
    .onSignal(\.pressed) { GD.print("Game Start!") }
}

// Create the Godot node we described
let node = view.toNode()
```

#### 🎨 Modifiers

**All settable properties** of nodes can be used as chainable modifiers.

```swift
Node2D$()
  .position(Vector2(x: 20, y: 20))
  .scale(Vector2(x: 0.5, y: 0.5))
  .rotation(0.25)
```

#### 📡 Signals

**All Godot signals** can be listened for with `.on`

```swift
Button$()
  .text("Toggle Sound")
  .onSignal(\.toggled) { node, isOn in
    GD.print("Sound is now", isOn ? "ON" : "OFF")
  }
```

#### 🍓 Resources

**All resource types** can be loaded with `.res`

```swift
Sprite2D$().res(\.texture, "art/player.png")

AudioStreamPlayer2D$().res(\.stream, "audio/laser.ogg")

// Conditionally assign when a path might be nil
Sprite2D$().resIf(\.texture, maybeTexturePath)

// Load any Resource, then mutate the node
Node2D$().withResource("shaders/tint.tres", as: Shader.self) { node, shader in
  let mat = ShaderMaterial()
  mat.shader = shader
  (node as? Sprite2D)?.material = mat
}
```


#### 👾 Aseprite

Aseprite support is included. Just add an exported sprite sheet + JSON to your project.

```swift
AseSprite$(path: "player.json")

// Shorthand: omit .json
AseSprite$("MyDino", path: "DinoSprites", layer: "MORT", autoplay: "move")
```

- `AseSprite` is a subclass of `AnimatedSprite2D`
- Enable the "Split Layers" option when exporting a file with multiple layers.


### Runtime

```swift
Node2D$().onReady { node in }
Node2D$().onProcess { node, delta in }
Node2D$().onPhysicsProcess { node, delta in }
```

### Physics

```swift
// Named layer enums + node helper
let wall = GNode<StaticBody2D>()
  .collisionLayer(.alpha)        // sets collisionLayer bits
  .collisionMask([.beta,.gamma]) // sets collisionMask bits
```

### Lifetime

```swift
// Time-based and/or offscreen despawn
Node2D$("Bullet") {
  Sprite2D$().res(\.texture, "bullet.png")
}
.autoDespawn(seconds: 4, whenOffscreen: true, offscreenDelay: 0.1)

// Pool-friendly variant
let pool = ObjectPool<Node2D>(factory: { Node2D() })
Node2D$("Enemy").autoDespawnToPool(pool, whenOffscreen: true)
```

#### 👯‍♀️ Custom Classes

**Any custom subclass of `Node`** can be used as a view.

```swift
@Godot
class Paddle: Area2D { }

GNode<Paddle> { }
```

- A `Paddle()` will be created when `toNode()` is called.

#### 🧬 Custom Instances

```swift
@Godot
class Paddle: Area2D {
  var side = "left"

  convenience init(side: Side) {
    self.init()
    self.side = side
  }

  override func _process(delta: Double) {
    if side == "left" { /* ... */ }
  }
}
```

Pass a `make: { }` trailing closure to customize instance:

```swift
GNode<Paddle> {
  // ...
} make: {
  Paddle(side: "right")
}
```

- A `Paddle(side: "right")` will be created when `toNode()` is called.


#### 🔗 Refs

Reference Nodes in Views.

```swift
let label = Ref<Label>()

VBoxContainer$ {
  Label$()
    .text("Lives: 0")
    .ref(label)

  Button$()
    .text("❤️")
    .onSignal(\.pressed) { _ in
      guard let l = label.node else { return }
      l.text = "Lives: 1"
    }
}
```

Reference instantiated Views in Nodes.

```swift
class Player: Node2D {
  let sprite = Slot<Sprite2D>()

  override func _ready() {
    // sprite.node is a Sprite2D
  }
}

let player = GNode<Player>("Player") {
  Sprite2D$()
    .res(\.texture, "player.png")
    .ref(\Player.sprite) // binds to Player.sprite
}
```

- Use instead of `getChild(NodePath)` to keep your nodes & gameplay classes loosely coupled.

- See also: [DinoFighter](Examples/Sources/DinoFighter)

#### 🎬 Packed Scenes

Instance a PackedScene.

```swift
Node2D$()
  .instanceScene("scenes/Enemy.tscn") { spawned in
    spawned.position = Vector2(x: 128, y: 64)
  }
```

#### 🏘️ Groups

Easily add to one or many groups.

```swift
Node2D$().group("enemies")
Node2D$().groups(["ui", "interactive"])
```

#### 🔃 Conditionals & loops

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

- This logic is only evaluated when `toNode()` is called.

#### 🧑‍💻 UI Controls

Chain modifiers to set anchors, offsets, sizing, and alignment:

#### Inside a Container

`.sizeH()`, `.sizeV()`, `.size()`

```swift
VBoxContainer$ {
  Button$().text("Play").sizeH(.expandFill)
  Button$().text("Options").size(.shrinkCenter)
  Button$().text("Quit").sizeH(.expandFill)
}
```

#### Outside a Container

`.anchors()`, `.offsets()`, `.anchorsAndOffsets()`, `.anchor(top:right:bottom:left)`, `.offset(top:right:bottom:left)`

```swift
CanvasLayer$ {
  Label$().text("42 ❤️")
    .anchors(.bottomLeft)
    .offsets(.bottomLeft, margin: 10)
}
```

#### A Container

`alignment()`

```swift
HBoxContainer$ {
  ["🗡️", "🛡️", "💣", "🧪", "🪄"]
    .map { Button$().text($0) }
}
.anchors(.topWide)
.offset(top: 10, right: -10)
.alignment(.end)
```

- See also: [HUDView](Examples/Sources/HUDView.swift)

### 🎮 Actions

Use declarative code to succinctly describe your input scheme.

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

### ❓ FAQ

> Q: Is this "SwiftUI for Godot"?

No. There's no `@State`/`@Binding`. There is no runtime behavior at all, beyond normal Godot events.

> Q: Does my whole game need to be in SwiftGodotBuilder?

No, you can add it to an existing SwiftGodot project. Anywhere you would write `addChild(node)`, you can instead write `addChild(view.toNode)`.

> Q: Does this hurt runtime performance?

No. `toNode()` is just syntax sugar around `addChild`. You control when are where to call this, just like a traditional SwiftGodot game.

> Q: So views aren't nodes?

No, views are representations of nodes, like a `.tscn` file. They aren't actually nodes until you call `.toNode()`. And they aren't part of the scene until you insert them with e.g. `addChild()`.

> Q: Why do I have to write `GNode<MyClass> {}` instead of `MyClass$ {}`?

`Node2D$` is just a `typealias` for `GNode<Node2D>`, so you can do `typealias MyClass$ = GNode<MyClass>` to use that syntax.

### Troubleshooting

> `- error: cannot convert value of type 'KeyPath<YourClass, Ref<NodeType>>' to expected argument type 'Ref<NodeType>'`

Chain your `.ref()` call after setting properties:

```swift
// Bad: causes error
Control$ {}
  .ref(\Overlay.panel)
  .anchors(.topLeft)

// Good: ref after properties
Control$ {}
  .anchors(.topLeft)
  .ref(\Overlay.panel)
```

### 📰 Articles

- [Separating Node Management from Behavior & State](articles/Article_001.md)

### 🔮 Roadmap

- Add library linking helper to VSCode plugin
- Export to .escn feature
- Additional samples of increasing complexity

### 📜 License

[MIT](LICENSE)
