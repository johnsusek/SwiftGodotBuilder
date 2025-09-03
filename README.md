# SwiftGodotBuilder

<a href="#"><img src="media/ludi.png?raw=true" width="250" align="left" title="Ludi (Latin plural) were public games held for the benefit and entertainment of the Roman people (populus Romanus). Pictured: Ancient Roman Gamers"></a>

A declarative toolkit for building Godot scenes in Swift. It sits on top of [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot) and uses Swift [result builders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders) to describe node trees as data.

### Features

- **Declarative scenes**: Compose Godot nodes with a SwiftUI-like syntax.
- **Type safety**: Key paths bind directly to SwiftGodot properties.
- **Modifiers**: Chain configuration calls (.position, .rotation, .scale, etc).
- **Signals**: Strongly-typed `.on(\.someSignal) { … }` handlers.
- **Actions**: Compose mouse, keyboard and joystick input actions (with recipes to reduce boilerplate).

> _Simple games should be simple to make._

<br>

## 📕 [API Documentation](https://johnsusek.github.io/SwiftGodotBuilder/documentation/swiftgodotbuilder/)

## 🚀 Quick start

```bash
brew install xcodegen
xcodegen -s Examples/project.yml
open Examples/SwiftGodotBuilderExample.xcodeproj
```

- Includes **Pong**, **Breakout** and **Space Invaders**  examples.

## 🪟 Views

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

// Create the actual Godot node tree:
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
// Sprite texture
Sprite2D$()
  .res(\.texture, "art/player.png")

// AnimatedSprite2D frames
AnimatedSprite2D$()
  .res(\.spriteFrames, "anim/player_frames.tres")

// Audio players
AudioStreamPlayer2D$()
  .res(\.stream, "audio/laser.ogg")
```

### 📡 Signals

**All Godot signals** can be listened for with `.on`

```swift
Button$()
  .text("Toggle Sound")
  .on(\.toggled) { isOn in
    GD.print("Sound is now", isOn ? "ON" : "OFF")
  }
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

- This logic is evaluated whenever `toNode()` is called.

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

Game-agnostic helpers for common scenarios.

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

## ❓ FAQ

> Is this "SwiftUI for Godot"?

No. There's no @State/@Binding. It's a builder that only does work when you call toNode().

> Does this affect runtime performance?

No. Builders are plain Swift values. Just syntax sugar around `addChild`.

> Where do the $ types come from?

A package plugin scans Godot's API JSON and generates `typealias Name$ = GNode<Name>`.

## 📰 Articles

- [Separating Node Management from Behavior & State](articles/Article_001.md)

## 🔮 Roadmap

- More unit tests, that use Godot runtime
- Chaining modifiers from custom views

## 📜 License

MIT
