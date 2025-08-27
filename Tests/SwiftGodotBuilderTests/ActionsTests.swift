import SwiftGodot
@testable import SwiftGodotBuilder
import XCTest

final class ActionsTests: XCTestCase {
  func testEventSugarHelpers() {
    let a = Key(.space)
    let b = JoyButton(0, .b)
    let c = JoyAxis(0, .leftY, 1.0)
    let d = MouseButton(2)
    XCTAssertEqual([a, b, c, d].count, 4)
  }

  func testActionBuilderAndActionFunction() {
    let moveLeft = Action("move_left") {
      Key(.a)
      JoyAxis(0, .leftX, -1)
    }
    XCTAssertEqual(moveLeft.name, "move_left")
    XCTAssertNil(moveLeft.deadzone)
    XCTAssertEqual(moveLeft.events.count, 2)
  }

  func testActionGroupAndActionBuilder() {
    let actions = Actions {
      Action("fire") { MouseButton(1) }
      ActionGroup {
        Action("left") { Key(.a) }
        Action("right") { Key(.d) }
      }
    }
    XCTAssertEqual(actions.actions.map(\.name), ["fire", "left", "right"])
  }

  func testActionRecipesAxisUD() {
    let pair = ActionRecipes.axisUD(
      namePrefix: "thrust",
      device: 0,
      axis: .leftY,
      dz: 0.3,
      keyDown: .s,
      keyUp: .w,
      btnDown: .a,
      btnUp: .b
    )
    XCTAssertEqual(pair.count, 2)
    XCTAssertEqual(pair[0].name, "thrust_down")
    XCTAssertEqual(pair[1].name, "thrust_up")
    XCTAssertEqual(pair[0].deadzone, 0.3)
    XCTAssertEqual(pair[1].deadzone, 0.3)
    XCTAssertEqual(pair[0].events.count, 3) // axis + keyDown + btnDown
    XCTAssertEqual(pair[1].events.count, 3) // axis + keyUp + btnUp
  }

  func testActionRecipesAxisLR() {
    let pair = ActionRecipes.axisLR(
      namePrefix: "move",
      device: 1,
      axis: .leftX,
      dz: 0.2,
      keyLeft: .a,
      keyRight: .d
    )
    XCTAssertEqual(pair.map(\.name), ["move_left", "move_right"])
    XCTAssertEqual(pair[0].events.count, 2)
    XCTAssertEqual(pair[1].events.count, 2)
  }
}
