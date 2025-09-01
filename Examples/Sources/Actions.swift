import SwiftGodotBuilder

let actions = Actions {
  ActionRecipes.axisUD(
    namePrefix: "left_move",
    device: 0,
    axis: .leftY,
    dz: 0.2,
    keyDown: .s,
    keyUp: .w,
    btnDown: .dpadDown,
    btnUp: .dpadUp
  )

  ActionRecipes.axisUD(
    namePrefix: "right_move",
    device: 1,
    axis: .leftY,
    dz: 0.2,
    keyDown: .down,
    keyUp: .up,
    btnDown: .dpadDown,
    btnUp: .dpadUp
  )
}
