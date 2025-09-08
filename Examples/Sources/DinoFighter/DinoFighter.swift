import SwiftGodot
import SwiftGodotBuilder

import SwiftGodot
import SwiftGodotBuilder

@Godot
final class DinoFighter: CharacterBody2D {
  enum Anim: String { case idle, move, crouch, kick, hurt }

  let sprite = Slot<AseSprite>()
  let hitbox = Slot<Area2D>()
  let hurtbox = Slot<Area2D>()
  let hitShape = Slot<CollisionShape2D>()

  var moveSpeed: Float = 60
  var isCpu = false

  private var anim: Animator?
  private var machine = StateMachine()
  private var inputs = InputSnapshot()
  private let attack = AbilityRunner()
  private var facing = 1
  private var time = 0.0
  private var didHitThisAttack = false
  private let actionNames = ["move_left", "move_right", "crouch", "kick"]
  private let kickSpec = AbilitySpec("kick", startup: 0.08, active: 0.12, recovery: 0.20, hitboxOffset: Vector2(7, 6))

  convenience init(isCpu: Bool) {
    self.init()
    self.isCpu = isCpu
  }

  override func _ready() {
    guard let sprite = sprite.node else { return }
    anim = Animator(sprite)

    attack.onBegan = { [weak self] _ in
      guard let self else { return }
      didHitThisAttack = false
      anim?.play(Anim.kick.rawValue, loop: false)
      setHitActive(false)
    }

    attack.onActive = { [weak self] s in
      guard let self else { return }
      setHitActive(true)
      syncFacing(facing, baseOffset: s.hitboxOffset)
    }

    attack.onEnded = { [weak self] _ in
      self?.setHitActive(false)
    }

    buildStates()
    machine.start(in: "Idle")
  }

  override func _physicsProcess(delta: Double) {
    time += delta

    if !isCpu {
      inputs.poll(actionNames)
      updateFacingFromInput()
    }

    attack.tick(delta)
    machine.update(delta: delta)

    if !isCpu {
      resolveHitsOnce()
    }

    moveAndSlide()
  }

  public func syncFacing(_ facing: Int, baseOffset: Vector2) {
    hitbox.node?.position = Vector2(Float(facing), 1) * baseOffset
  }

  public func setHitActive(_ active: Bool) {
    hitShape.node?.disabled = !active
  }

  private func buildStates() {
    machine.add("Idle", .init(
      onEnter: { [weak self] in
        self?.anim?.play(Anim.idle.rawValue, loop: true)
      },

      onUpdate: { [weak self] _ in
        guard let self else { return }

        if inputs.down("crouch") {
          machine.transition(to: "Crouch")
          return
        }

        if inputs.pressed("kick") {
          machine.transition(to: "Attack")
          return
        }

        if inputs.down("move_left") != inputs.down("move_right") {
          machine.transition(to: "Move")
          return
        }

        velocity.x = 0
      }
    ))

    machine.add("Move", .init(
      onEnter: { [weak self] in
        self?.anim?.play(Anim.move.rawValue, loop: true)
      },

      onUpdate: { [weak self] _ in
        guard let self else { return }

        if inputs.down("crouch") {
          machine.transition(to: "Crouch")
          return
        }

        if inputs.pressed("kick") {
          machine.transition(to: "Attack")
          return
        }

        let left = inputs.down("move_left"), right = inputs.down("move_right")
        if left == right {
          machine.transition(to: "Idle")
          return
        }

        let dir: Float = left ? -1 : 1
        velocity.x = dir * moveSpeed
        if left { sprite.node?.flipH = true }
        if right { sprite.node?.flipH = false }
      }
    ))

    machine.add("Crouch", .init(
      onEnter: { [weak self] in
        self?.anim?.play(Anim.crouch.rawValue, loop: true)
      },

      onUpdate: { [weak self] _ in
        guard let self else { return }
        velocity.x = 0
        if !inputs.down("crouch") { machine.transition(to: "Idle") }
      }
    ))

    machine.add("Attack", .init(
      onEnter: { [weak self] in
        self?.beginKick()
      },

      onUpdate: { [weak self] _ in
        guard let self else { return }
        velocity.x = 0
        if !attack.busy { machine.transition(to: "Idle") }
      }
    ))

    machine.add("Hurt", .init(
      onEnter: { [weak self] in
        self?.anim?.play(Anim.hurt.rawValue, loop: false)
      },
      onUpdate: { [weak self] _ in
        self?.velocity.x = 0
      }
    ))
  }

  private func updateFacingFromInput() {
    if inputs.pressed("move_left") { facing = -1 }
    if inputs.pressed("move_right") { facing = 1 }
  }

  private func resolveHitsOnce() {
    guard attack.isActive, didHitThisAttack == false else { return }
    guard let hitAreas = hitbox.node?.getOverlappingAreas(), !hitAreas.isEmpty else { return }

    for node in hitAreas {
      guard let otherHurt = node,
            let otherDino: DinoFighter = otherHurt.getParents().first,
            otherDino !== self else { continue }

      otherDino.takeHit(from: self)
      didHitThisAttack = true

      return
    }
  }

  private func beginKick() { attack.begin(kickSpec) }

  func takeHit(from _: DinoFighter) { machine.transition(to: "Hurt") }
}

private class Animator {
  private let sprite: AnimatedSprite2D
  private var current: String = ""

  public init(_ sprite: AnimatedSprite2D) {
    self.sprite = sprite
  }

  public func play(_ name: String, loop: Bool) {
    guard current != name else { return }
    current = name
    sprite.spriteFrames?.setAnimationLoop(anim: StringName(name), loop: loop)
    sprite.play(name: StringName(name))
  }

  public func onFinished(_ f: @escaping () -> Void) {
    _ = sprite.animationFinished.connect { f() }
  }

  public func setFlip(left: Bool, right: Bool) {
    if left { sprite.flipH = true }
    if right { sprite.flipH = false }
  }
}
