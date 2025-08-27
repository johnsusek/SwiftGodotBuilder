//
//  BuilderScene.swift
//
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

public struct Scene {
  private let content: any GView
  private let rootName: String
  private let assets = Assets()

  public init(_ name: String = "Main", @ViewBuilder _ content: () -> any GView) {
    rootName = name
    self.content = content()
  }

  @discardableResult public func makeNode() -> Node {
    let node = content.makeNode(ctx: .init(assets: assets))
    node.name = StringName(rootName)
    return node
  }
}
