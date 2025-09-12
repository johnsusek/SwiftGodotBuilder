# SwiftGodotBuilder

<a href="#"><img src="media/ludi.png?raw=true" width="250" align="right" title="Ludi (Latin plural) were public games held for the benefit and entertainment of the Roman people (populus Romanus). Pictured: Ancient Roman Gamers"></a>

A declarative toolkit for building [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) games.

### Features

- **Declarative scenes**: Build Godot node trees with a SwiftUI-like syntax.
- **Type-safe modifiers**: Chain configuration calls (.position, .rotation, etc); load resources with .res().
- **Signals**: Strongly-typed .on(\.someSignal) { … } handlers.
- **Aseprite built-in**: parses Aseprite JSON directly - use like any animated sprite.
- **AnimationMachine**: Two way mapping between game state and animations.
- **Refs**: Reference nodes directly, without NodePaths.
- **Actions**: Compose mouse, keyboard and joystick input actions (with recipes to reduce boilerplate).
- **Custom classes**: Use your own @Godot subclasses in views, use custom initializers, with auto registration.

> _Simple games should be simple to make._

## 📕 API Documentation

- [SwiftGodotBuilder](https://swiftpackageindex.com/johnsusek/SwiftGodotBuilder/documentation/swiftgodotbuilder/)

## 🚀 Quick start

```bash
brew install xcodegen
xcodegen -s Examples/project.yml
open Examples/SwiftGodotBuilderExample.xcodeproj
```

Includes **Pong**, **Breakout**, **Space Invaders**, **HUD**, and **Aseprite**  examples.

## 🪟 Views

> _Views **describe** your nodes, like a `.tscn` file, but using code._

**All subclasses of `Node`** can be suffixed with `$` to build views.

```swift
let view = Node2D$ {
  Sprite2D$()
    .res(\.texture, "ball.png")
    .position(x: 100, y: 200)

  Button$()
    .text("Start")
    .on(\.pressed) { GD.print("Game Start!") }
}

// Create the Godot node we described
let node = view.toNode()
```

### 🎨 Modifiers

**All settable properties** of nodes can be used as chainable modifiers.

```swift
Node2D$()
  .position(Vector2(x: 20, y: 20))
  .scale(Vector2(x: 0.5, y: 0.5))
  .rotation(0.25)
```

### 🍓 Resources

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


### 👾 Aseprite

Aseprite support is included. Just add an exported sprite sheet + JSON to your project.

```swift
GNode<AseSprite>(path: "player.json")

// Shorthand: omit `.json` and use type alias:
AseSprite$(path: "player")

// Named node with a specified layer and animation to start playing
AseSprite$("MyDino", path: "DinoSprites", layer: "MORT", autoplay: "move")
```

- `AseSprite` is a subclass of `AnimatedSprite2D`
- Enable the "Split Layers" option when exporting a file with multiple layers.

#### Options

##### ⏱️ Timing

- `uniformFPS(fps)` - arcade feel; even spacing; easiest to retime globally.
- `exactDelays` - perfect fidelity to Aseprite; editor scrubbing less friendly.
- `delaysGCD(cap)` - near-perfect feel + integer frames for editor; default sweet spot.

```swift
AseSprite$(
  path: "player",
  options: .init(timing: .uniformFPS(10)),
  autoplay: "Idle"
)
```

### 📡 Signals

**All Godot signals** can be listened for with `.on`

```swift
Button$()
  .text("Toggle Sound")
  .on(\.toggled) { node, isOn in
    GD.print("Sound is now", isOn ? "ON" : "OFF")
  }
```

### 🎞️ Animation Machine

A declarative mapping between **gameplay states** and **animation clips**.

```swift
let rules = AnimationMachineRules {
  When("Idle", play: "standing") // State `Idle` loops `standing` animation
  When("Move", play: "running") // State `Move` loops `running` animation
  When("Hurt", play: "damaged", loop: false) // State `Hurt` plays `damaged` once

  OnFinish("damaged", go: "Idle")  // Animation `damaged` sets state `Idle` when finished
}

let sm = StateMachine()
let sprite = AseSprite(path: "dino", autoplay: "standing") // any AnimatedSprite2D

let animator = AnimationMachine(machine: sm, sprite: sprite, rules: rules)
animator.activate()

sm.start(in: "Idle")
sm.transition(to: "Hurt") // plays "damaged", then auto-returns to "Idle"
```

### 👯‍♀️ Custom Classes

**Any custom subclass of `Node`** can be used as a view.

```swift
@Godot
class Paddle: Area2D { }

GNode<Paddle> { }
```

- A `Paddle()` will be created when `toNode()` is called.

### 🧬 Custom Instances

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


### 🔗 Refs

Reference Nodes in Views.

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

### 🎬 Packed Scenes

Instance a PackedScene.

```swift
Node2D$()
  .instanceScene("scenes/Enemy.tscn") { spawned in
    spawned.position = Vector2(x: 128, y: 64)
  }
```

### 🏘️ Groups

Easily add to one or many groups.

```swift
Node2D$().group("enemies")
Node2D$().groups(["ui", "interactive"])
```

### 🔃 Conditionals & loops

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

### 🧑‍💻 UI Controls

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

## 🎮 Actions

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

## 🧱 Components

Game-agnostic views for common scenarios.

### Text Menu

A simple centered text menu.

```swift
// Responds to `menu_up`, `menu_down`, `menu_select` actions
TextMenu {
  MenuLabel("Main Menu")
  MenuSpacer()
  MenuItem("Play") { startGame() }
  MenuItem("Options") { openOptions() }
  MenuSpacer(16)
  MenuItem("Quit") { getTree()?.quit() }
}

// Custom action names
TextMenu(upAction: "ui_up", downAction: "ui_down", confirmAction: "ui_accept") { }
```

## ❓ FAQ

> Does my whole game need to be in SwiftGodotBuilder?

No, you can add it to any SwiftGodot project to just use it for e.g. a single scene.

> Does this work on Mac/Windows/Linux?

Yes, though there are only Windows and Mac Example apps currently.

> Is this "SwiftUI for Godot"?

No. There's no `@State`/`@Binding`. It's a builder that only does work when you call `toNode()`.

> Does this hurt runtime performance?

No. Builders are plain Swift values and `toNode()` is just syntax sugar around `addChild`.

> Where do the $ types come from?

A [package plugin](Sources/NodeApiGen) scans Godot's API JSON and generates `typealias Name$ = GNode<Name>`.

## 📰 Articles

- [Separating Node Management from Behavior & State](articles/Article_001.md)

## 🔮 Roadmap

- Linux version of example app
- Splash screen component
- Export to .escn
- VSCode plugin (toolchain setup, build tasks, scaffolding)
- Debug helpers (bounding box visualizer, stats)

## 📜 License

[MIT](LICENSE)
