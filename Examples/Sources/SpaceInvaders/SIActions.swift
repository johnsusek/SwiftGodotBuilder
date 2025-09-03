import SwiftGodotBuilder

let SIActions = Actions {
  ActionRecipes.axisLR(
    namePrefix: "si",
    device: 0,
    axis: .leftX,
    dz: 0.2,
    keyLeft: .left,
    keyRight: .right,
    btnLeft: .dpadLeft,
    btnRight: .dpadRight
  )

  Action("si_fire") {
    Key(.space)
    JoyButton(.a, device: 0)
    MouseButton(0)
  }
}
