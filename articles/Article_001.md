# Separating Node Management from Behavior & State

The following SwiftGodot class has multiple responsibilities:

- Initialize values
- Assemble child nodes
- Connect to a signal
- Process position updates
- Handle hit logic

```swift
@Godot
final class Bullet: Area2D {
  var bulletOwner: BulletOwner = .player
  var speed: Double = 500

  convenience init(owner: BulletOwner, speed: Double) {
    self.init()
    bulletOwner = owner
    self.speed = speed
  }

  override func _ready() {
    let s = ColorRect()
    s.color = (bulletOwner == .player) ? Color(r: 1, g: 1, b: 1, a: 1) : Color(r: 1, g: 0.6, b: 0.3, a: 1)
    s.setSize(Vector2(3, 12))
    addChild(node: s)
    let cs = CollisionShape2D()
    let r = RectangleShape2D()
    r.size = Vector2(3, 12)
    cs.shape = r
    addChild(node: cs)
  }

  override func _process(delta: Double) {
    let dy: Float = bulletOwner == .player ? -1 : 1
    position.y += Float(speed * delta) * dy
    if position.y < -16 || position.y > 616 { queueFree() }
  }

  override func _enterTree() {
    _ = areaEntered.connect { [weak self] other in self?.handleHit(other) }
  }

  private func handleHit(_ other: Area2D?) {
    guard let other else { return }
    switch bulletOwner {
    case .player:
      if let inv = other as? SIInvader {
        inv.die()
        queueFree()
      }
      if let shield = other as? SIShieldBlock {
        shield.hit()
        queueFree()
      }
    case .alien:
      if let player = other as? SIPlayer {
        player.queueFree()
        queueFree()
      }
      if let shield = other as? SIShieldBlock {
        shield.hit()
        queueFree()
      }
    }
  }
}
```

Use later:

```swift
let node = Bullet(owner: .alien, speed: 300)
node.position = shooter.position + Vector2(0, 12)
addChild(node: node)
```

## Separated

### Node Management

Now the view will:

- Initialize values
- Assemble child nodes
- Connect to a signal

```swift
struct BulletView: GView {
  let owner: BulletOwner
  let speed: Double
  let position: Vector2
  let size = Vector2(3, 12)

  var body: some GView {
    GNode<Bullet> {
      ColorRect$()
        .color(owner == .player ? Color(r: 1, g: 1, b: 1, a: 1) : Color(r: 1, g: 0.6, b: 0.3, a: 1))
        .configure { $0.setSize(size) }

      CollisionShape2D$()
        .shape(RectangleShape2D(x: Int(size.x), y: Int(size.y)))
    }
    .position(position)
    .set(\.bulletOwner, owner)
    .set(\.speed, speed)
    .on(\.areaEntered) { b, other in b.handleHit(other) }
  }
}
```

### Behavior/State

Now the class will only:

- Process position updates
- Handle hit logic

```swift
@Godot
final class Bullet: Area2D {
  var bulletOwner: BulletOwner = .player
  var speed: Double = 500

  override func _process(delta: Double) {
    let dy: Float = bulletOwner == .player ? -1 : 1
    position.y += Float(speed * delta) * dy
    if position.y < -16 || position.y > 616 { queueFree() }
  }

  func handleHit(_ other: Area2D?) {
    guard let other else { return }
    switch bulletOwner {
    case .player:
      if let inv = other as? SIInvader {
        inv.die()
        queueFree()
      }
      if let shield = other as? SIShieldBlock {
        shield.hit()
        queueFree()
      }
    case .alien:
      if let player = other as? SIPlayer {
        player.queueFree()
        queueFree()
      }
      if let shield = other as? SIShieldBlock {
        shield.hit()
        queueFree()
      }
    }
  }
}
```

Use later:
```swift
let node = BulletView(owner: .alien, speed: 300, position: shooter.position + Vector2(0, 12)).toNode()
addChild(node: node)
```

