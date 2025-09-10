import Foundation
import SwiftGodot
import SwiftGodotPatterns

// MARK: - Extension for GNode builder

public extension GNode where T == AseSprite {
  /// Convenience initializer for creating an `AseSprite` within a `GNode` builder context.
  ///
  /// Example:
  /// ```swift
  /// let dinoView = GNode<AseSprite>(path: "DinoSprites", layer: "MORT")
  /// ```
  init(
    _ name: String? = UUID().uuidString,
    path: String,
    layer: String? = nil,
    options: AseOptions = .init(),
    autoplay: String? = nil,
    @NodeBuilder _ children: () -> [any GView] = { [] }
  ) {
    self.init(name, children, make: {
      let a = T()
      a.sourcePath = path
      a.layerName = layer
      a.aseOptions = options
      a.autoplayAnimation = autoplay
      return a
    })
  }
}

public typealias AseSprite$ = GNode<AseSprite>
