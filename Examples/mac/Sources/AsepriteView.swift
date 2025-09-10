import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

struct AsepriteView: GView {
  let bottomX: Float = 240 - 48

  init() {
    GodotRegistry.append(AseSprite.self)
  }

  var body: some GView {
    let mort = Ref<AseSprite>()
    let anims = ["idle", "move", "kick", "hurt", "crouch", "sneak"]

    return Node2D$ {
      HBoxContainer$ {
        for anim in anims {
          Button$()
            .text(anim.capitalized)
            .on(\.pressed) { _ in
              mort.node?.play(name: StringName(anim))
            }
        }
      }

      AseSprite$(path: "DinoSprites", layer: "MORT", autoplay: "idle")
        .ref(mort)
        .position(Vector2(160, 120))
    }
  }
}
