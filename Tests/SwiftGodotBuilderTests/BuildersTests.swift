import SwiftGodot
@testable import SwiftGodotBuilder
import XCTest

final class BuildersTests: XCTestCase {
  func testInputEventBuilderComposition() {
    @InputEventBuilder
    func evs() -> [InputEventSpec] {
      Key(.space)
      if true { JoyButton(0, .a) }
      for v in [-1.0, 1.0] {
        JoyAxis(0, .leftX, v)
      }
    }
    let built = evs()
    XCTAssertEqual(built.count, 4)
  }

  func testActionBuilderArray() {
    @ActionBuilder
    func actions() -> [ActionSpec] {
      Action("jump") { Key(.space) }
      if true { Action("shoot") { MouseButton(1) } }
      for i in 0 ..< 2 {
        Action("slot_\(i)") { JoyButton(0, .a) }
      }
    }
    let a = actions()
    XCTAssertEqual(a.count, 4)
    XCTAssertEqual(a.map(\.name), ["jump", "shoot", "slot_0", "slot_1"])
  }
}
