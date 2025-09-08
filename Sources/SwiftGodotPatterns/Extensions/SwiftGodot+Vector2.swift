import SwiftGodot

/// Convenience extensions for Godot Vector math.

public extension Vector2 {
  @inlinable static func + (lhs: Self, rhs: Self) -> Self { Self(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
  @inlinable static func - (lhs: Self, rhs: Self) -> Self { Self(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }

  @inlinable static func * (lhs: Self, rhs: Float) -> Self { Self(x: lhs.x * rhs, y: lhs.y * rhs) }
  @inlinable static func * (lhs: Float, rhs: Self) -> Self { rhs * lhs }

  @inlinable static func * <S: BinaryFloatingPoint>(lhs: Self, rhs: S) -> Self { Self(x: lhs.x * Float(rhs), y: lhs.y * Float(rhs)) }
  @inlinable static func * <S: BinaryFloatingPoint>(lhs: S, rhs: Self) -> Self { rhs * lhs }

  @inlinable static func * <S: BinaryInteger>(lhs: Self, rhs: S) -> Self { lhs * Float(rhs) }
  @inlinable static func * <S: BinaryInteger>(lhs: S, rhs: Self) -> Self { rhs * lhs }

  @inlinable static func += (lhs: inout Self, rhs: Self) { lhs = lhs + rhs }
  @inlinable static func -= (lhs: inout Self, rhs: Self) { lhs = lhs - rhs }
  @inlinable static func *= (lhs: inout Self, rhs: Float) { lhs = lhs * rhs }
  @inlinable static func *= <S: BinaryFloatingPoint>(lhs: inout Self, rhs: S) { lhs = lhs * rhs }
  @inlinable static func *= <S: BinaryInteger>(lhs: inout Self, rhs: S) { lhs = lhs * rhs }
}
