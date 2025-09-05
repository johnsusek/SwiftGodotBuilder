import SwiftGodot

/// Layout helpers for `Control` nodes that are **not** managed by a container.
///
/// These APIs wrap Godot’s anchor/offset system. They are useful when the
/// control’s parent is a plain `Node2D`, `CanvasLayer`, or another `Control` that
/// is not a container (e.g. `Control` or `Panel` used as a canvas).
public extension GNode where T: Control {
  /// Applies a Godot **layout preset** to both anchors and offsets.
  ///
  /// This is a convenience over `Control.setAnchorsAndOffsetsPreset(_:)`.
  ///
  /// ```swift
  /// // Pin a button to the top-right of its non-container parent.
  /// Button$().text("Pause")
  ///   .offsets(.topRight)
  /// ```
  func offsets(_ preset: Control.LayoutPreset) -> Self {
    var s = self
    s.ops.append { $0.setAnchorsAndOffsetsPreset(preset) }
    return s
  }

  /// Applies a Godot **layout preset** to both anchors and offsets.
  ///
  /// ```swift
  /// // Center a label in its non-container parent.
  /// Label$().text("Ready?")
  ///   .anchors(.center)
  /// ```
  func anchors(_ preset: Control.LayoutPreset) -> Self {
    var s = self
    s.ops.append { $0.setAnchorsAndOffsetsPreset(preset) }
    return s
  }

  /// Manually sets individual **offsets** (pixels) relative to the current anchors.
  ///
  /// ```swift
  /// // Inset 12 px from each edge after applying a full-rect preset.
  /// Panel$()
  ///   .anchors(.fullRect)
  ///   .offset(top: 12, right: -12, bottom: -12, left: 12)
  /// ```
  ///
  /// - Parameters:
  ///   - top: Top inset in pixels.
  ///   - right: Right inset in pixels (negative values inset from the right).
  ///   - bottom: Bottom inset in pixels (negative values inset from the bottom).
  ///   - left: Left inset in pixels.
  func offset(top: Double? = nil,
              right: Double? = nil,
              bottom: Double? = nil,
              left: Double? = nil) -> Self
  {
    var s = self
    s.ops.append { c in
      if let left { c.offsetLeft = left }
      if let top { c.offsetTop = top }
      if let right { c.offsetRight = right }
      if let bottom { c.offsetBottom = bottom }
    }
    return s
  }
}

/// Layout helpers for `Control` nodes **inside container parents**
/// (e.g. `VBoxContainer`, `HBoxContainer`, `CenterContainer`, etc.).
///
/// These APIs set size flags that container layouts read to determine how much
/// a child should expand, fill, or center along an axis. They do **not** affect
/// anchor/offset layout.
public extension GNode where T: Control {
  /// Sets the **horizontal** size flags for use by container parents.
  ///
  /// Typical values include `.shrinkBegin`, `.shrinkCenter`, `.fill`, `.expand`,
  /// and combinations like `.expandFill`.
  ///
  /// ```swift
  /// // In an HBox, let the text field grow while siblings stay compact.
  /// LineEdit$().sizeH(.expandFill)
  /// ```
  func sizeH(_ flags: Control.SizeFlags) -> Self {
    var s = self
    s.ops.append { $0.sizeFlagsHorizontal = flags }
    return s
  }

  /// Sets the **vertical** size flags for use by container parents.
  ///
  /// ```swift
  /// // In a VBox, let this button expand vertically to fill remaining space.
  /// Button$().text("Play").sizeV(.expandFill)
  /// ```
  func sizeV(_ flags: Control.SizeFlags) -> Self {
    var s = self
    s.ops.append { $0.sizeFlagsVertical = flags }
    return s
  }

  /// Convenience to set **both** horizontal and vertical size flags.
  ///
  /// ```swift
  /// // Expand and fill in both axes inside a container.
  /// ColorRect$().size(.expandFill, .expandFill)
  /// ```
  @inlinable
  func size(_ h: Control.SizeFlags, _ v: Control.SizeFlags) -> Self { sizeH(h).sizeV(v) }

  /// Convenience to set the **same** size flags for both axes.
  ///
  /// ```swift
  /// // Center in both axes within a container.
  /// Label$().text("Hello").size(.shrinkCenter)
  /// ```
  @inlinable
  func size(_ s: Control.SizeFlags) -> Self { sizeH(s).sizeV(s) }
}
