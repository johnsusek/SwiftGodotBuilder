import SwiftGodot
import SwiftGodotBuilder
import SwiftGodotPatterns

@Godot
final class DinoFighter: CharacterBody2D {
  private enum Anim: String { case idle, move, crouch, kick, hurt }
  private enum State: String { case idle, move, crouch, attack, hurt }

  let sprite = Ref<AseSprite>()
  let hitbox = Ref<Area2D>()
  let hurtbox = Ref<Area2D>()
  let hitShape = Ref<CollisionShape2D>()

  var moveSpeed: Float = 60
  var isCpu = false

  private var machine = StateMachine()
  private var inputs = InputSnapshot()
  private let attack = AbilityRunner()
  private var facing = 1
  private var time = 0.0
  private var didHitThisAttack = false
  private let actionNames = ["move_left", "move_right", "crouch", "kick"]
  private let kickSpec = AbilitySpec(Anim.kick.rawValue, startup: 0.08, active: 0.12, recovery: 0.20, hitboxOffset: Vector2(7, 6))
  private var animator: AnimationMachine?

  convenience init(isCpu: Bool) {
    self.init()
    self.isCpu = isCpu
  }

  override func _ready() {
    guard let spriteNode = sprite.node else { return }

    attack.onBegan = { [weak self] _ in
      guard let self else { return }
      didHitThisAttack = false
      setHitActive(false)
    }

    attack.onActive = { [weak self] spec in
      guard let self else { return }
      setHitActive(true)
      syncFacing(facing, baseOffset: spec.hitboxOffset)
    }

    attack.onEnded = { [weak self] _ in
      self?.setHitActive(false)
    }

    buildStates()

    machine.start(in: State.idle)

    let rules = AnimationMachineRules {
      When(State.idle, play: Anim.idle)
      When(State.move, play: Anim.move)
      When(State.crouch, play: Anim.crouch)
      When(State.attack, play: Anim.kick, loop: false)
      When(State.hurt, play: Anim.hurt, loop: false)
      OnFinish(Anim.hurt, go: State.idle)
    }

    let stateAnimator = AnimationMachine(machine: machine, sprite: spriteNode, rules: rules)
    stateAnimator.activate()

    animator = stateAnimator
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
    machine.add(State.idle, .init(
      onUpdate: { [weak self] _ in
        guard let self else { return }

        if inputs.down("crouch") {
          machine.transition(to: State.crouch)
          return
        }

        if inputs.pressed("kick") {
          machine.transition(to: State.attack)
          beginKick()
          return
        }

        if inputs.down("move_left") != inputs.down("move_right") {
          machine.transition(to: State.move)
          return
        }

        velocity.x = 0
      }
    ))

    machine.add(State.move, .init(
      onUpdate: { [weak self] _ in
        guard let self else { return }

        if inputs.down("crouch") {
          machine.transition(to: State.crouch)
          return
        }

        if inputs.pressed("kick") {
          machine.transition(to: State.attack)
          beginKick()
          return
        }

        let left = inputs.down("move_left"), right = inputs.down("move_right")
        if left == right {
          machine.transition(to: State.idle)
          return
        }

        let dir: Float = left ? -1 : 1
        velocity.x = dir * moveSpeed
        if left { sprite.node?.flipH = true }
        if right { sprite.node?.flipH = false }
      }
    ))

    machine.add(State.crouch, .init(
      onUpdate: { [weak self] _ in
        guard let self else { return }
        velocity.x = 0
        if !inputs.down("crouch") { machine.transition(to: State.idle) }
      }
    ))

    machine.add(State.attack, .init(
      onUpdate: { [weak self] _ in
        guard let self else { return }
        velocity.x = 0
        if !attack.busy { machine.transition(to: State.idle) }
      }
    ))

    machine.add(State.hurt, .init(
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
            let otherDino = otherHurt.getParents().first as? DinoFighter,
            otherDino !== self else { continue }

      otherDino.takeHit(from: self)
      didHitThisAttack = true
      return
    }
  }

  private func beginKick() { attack.begin(kickSpec) }

  func takeHit(from _: DinoFighter) { machine.transition(to: State.hurt) }
}
