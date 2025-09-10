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
- **Patterns**: Game-agnostic utilities: ObjectPool, Spawner/Despawner, InputSnapshot, AbilityRunner and more.

> _Simple games should be simple to make._

## 📕 API Documentation

- [SwiftGodotBuilder](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/)

- [SwiftGodotPatterns](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotpatterns/)

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

## 🪡 Patterns

Game-agnostic classes for common scenarios, import `SwiftGodotPatterns` to use.

## 💁 Class Registry

Register custom `@Godot` classes without needing to call `register(type)`

```swift
struct PaddleView: GView {
  init() {
    GodotRegistry.append(Paddle.self)
  }

  var body: some GView {
    GNode<Paddle>()
  }
}
```

### Physics

```swift
// Named layer enum (define your own Physics2DLayer bitset)
let wall = GNode<StaticBody2D>()
  .collisionLayer(.level)       // sets collisionLayer bits
  .collisionMask([.player,.npc])// sets collisionMask bits
```

### Lifetime

Auto-despawn

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



### Cooldown

A frame-friendly cooldown timer.

```swift
var fireCooldown = Cooldown(duration: 0.25)

// In your code:
if wantsToFire, fireCooldown.tryUse() {
  fireBullet()
}

func _process(delta: Double) {
  fireCooldown.tick(delta: delta)
}
```

### StateMachine

A string-keyed finite state machine with enter/exit/update hooks.

```swift
let sm = StateMachine()
sm.add("Idle", StateMachine.State(onEnter: { print("Idle") }))
sm.add("Run",  StateMachine.State(onUpdate: { dt in /* move */ }))
sm.onChange = { from, to in print("\(from) -> \(to)") }

// In your code:
sm.start(in: "Idle")
sm.transition(to: "Run")

func _process(delta: Double) {
  sm.update(delta: delta)
}
```

### GameTimer

A manually-driven timer with optional repetition and a timeout callback.

```swift
@Godot
class Blinker: Control {
  private let blink = GameTimer(duration: 0.4, repeats: true)

  override func _ready() {
    _ = GameTimer.schedule(after: 1.0) { [weak self] in
      guard let self, let box: ColorRect = getNode("Box") else { return }
      box.visible = true
      blink.start()
    }

    blink.onTimeout = { [weak self] in
      guard let self, let box: ColorRect = getNode("Box") else { return }
      box.visible.toggle()
    }
  }

  override func _process(delta: Double) {
    blink.tick(delta: delta)
  }
}
```

```swift
struct BlinkerView: GView {
  init() {
    GodotRegistry.append(contentsOf: [Blinker.self])
  }

  var body: some GView {
    GNode<Blinker> {
      ColorRect$("Box")
        .color(Color(r: 0.9, g: 0.2, b: 0.3, a: 1))
        .customMinimumSize(Vector2(x: 64, y: 64))
        .visible(false)
    }
  }
}
```

### Health

A game-agnostic hit-point model.

```swift
var hp = Health(max: 100)
hp.onChanged = { old, new in print("HP: \(old) -> \(new)") }
hp.onDied = { print("You died!") }

hp.damage(30)   // HP: 100 -> 70
hp.heal(10)     // HP: 70 -> 80
hp.invulnerable = true
hp.damage(999)  // no change
hp.invulnerable = false
hp.damage(200)  // HP: 80 -> 0, prints "You died!", then onDamaged(200)
```

### ObjectPool

An object pool for Godot `Object` subclasses.

```swift
final class Bullet: Node2D, PoolItem {
  func onAcquire() { visible = true }
  func onRelease() { visible = false; position = .zero }
}

let pool = ObjectPool<Bullet>(factory: { Bullet() })
pool.preload(64)

if let bullet = pool.acquire() {
  bullet.onAcquire()
  // configure and add to scene...
  // later:
  pool.release(bullet)
}
```

### Spawner

A timer-driven generator of objects at a target rate.

```swift
let spawner = Spawner<Bullet>()
spawner.rate = 5            // 5 bullets/sec
spawner.jitter = 0.05       // small timing variance
spawner.make = { Bullet() } // or spawner.usePool(pool.acquire)

spawner.onSpawn = { bullet in
  bullet.configureAndAttach()
}

spawner.reset() // spawn on next tick

func _process(delta: Double) {
  spawner.tick(delta: delta)
}
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

No, you can add it to any SwiftGodot project to just use it for e.g. a single scene. Additionally you can use SwiftGodotPatterns without using Views at all.

> Does this work on Mac/Windows/Linux/Web?

Yes, though the Example app is Mac-only currently.

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

## 📜 License

[MIT](LICENSE)
