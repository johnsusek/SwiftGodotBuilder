import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

private enum FighterBits {
  static let body: Physics2DLayer = .alpha
  static let hit: Physics2DLayer = .beta
  static let hurt: Physics2DLayer = .gamma
}

let inputs = Actions {
  Action("kick") {
    Key(.k)
    JoyButton(.b, device: 0)
  }

  Action("crouch") {
    Key(.s)
    Key(.down)
  }

  ActionRecipes.axisLR(
    namePrefix: "move", device: 0, axis: .leftX, dz: 0.2,
    keyLeft: .a, keyRight: .d, btnLeft: .dpadLeft, btnRight: .dpadRight
  )
}

struct Dinoview: GView {
  let layer: String
  let position: Vector2
  let isCpu: Bool

  init(_ layer: String, position: Vector2, isCpu: Bool = true) {
    self.layer = layer
    self.position = position
    self.isCpu = isCpu
  }

  var body: some GView {
    GNode<DinoFighter> {
      AseSprite$(path: "DinoSprites", layer: layer, autoplay: "idle")
        .ref(\DinoFighter.sprite)

      // Body collider
      CollisionShape2D$()
        .position(Vector2(1, 4))
        .shape(RectangleShape2D(w: 14, h: 8))

      // Hurt collider
      Area2D$ {
        CollisionShape2D$().shape(RectangleShape2D(w: 16, h: 16))
      }
      .position(Vector2(0, 8))
      .monitorable(true)
      .collisionLayer(FighterBits.hurt)
      .collisionMask(FighterBits.hurt)
      .ref(\DinoFighter.hurtbox)

      // Hit collider
      Area2D$ {
        CollisionShape2D$()
          .shape(RectangleShape2D(w: 14, h: 10))
          .ref(\DinoFighter.hitShape)
      }
      .position(Vector2(14, 6))
      .monitoring(true)
      .collisionLayer(FighterBits.hit)
      .collisionMask(FighterBits.hurt)
      .ref(\DinoFighter.hitbox)
    } make: {
      DinoFighter(isCpu: isCpu)
    }
    .position(position)
    .collisionLayer(FighterBits.body)
    .collisionMask(FighterBits.body)
  }
}

struct DinoGameView: GView {
  init() {
    GodotRegistry.append(contentsOf: [AseSprite.self, DinoFighter.self])
    inputs.install()
  }

  var body: some GView {
    Node2D$ {
      Dinoview("Mort", position: Vector2(x: 32, y: 100), isCpu: false)
      Dinoview("TARD", position: Vector2(x: 160, y: 100))
    }
  }
}
