# Best Practices

## Modifiers

- Order your modifers least specific to most specfic, then special
```swift
  $Sprite2D()
    .position(...) // generic Node2D
    .res(\.texture, "") // specfic to Sprite2D
    .ref(\Player.sprite) // special
```

## Naming

- State names - use progressive verbs: `Idling`, `Moving`, `Crouching`, `Attacking`.

- Animation names - use the base form: `Idle`, `Move`, `Crouch`, `Kick`.

## Anti-Patterns

- `addNode` in game class - use a View.
- `getNode` in game class - use Ref to loosely couple
