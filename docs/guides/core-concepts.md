---
sidebar_position: 2
---

# Core Concepts

## Context

A context is a container for related controls.

Use separate contexts for different gameplay states:

- `Gameplay`
- `Menu`
- `Vehicle`

Why this matters:

- easier to enable/disable whole control sets
- less input conflict between systems

## Action

An action is a named intent, not a physical key.

Good action names:

- `Jump`
- `Attack`
- `OpenMap`

Avoid naming actions after keys like `FKeyAction`, because keys can change.

## Binding

A binding maps a physical input to an action.

One action can have multiple bindings:

```lua
EZInput.context("Movement")
    :action("Jump")
        :bind(Enum.KeyCode.Space)
        :bind(Enum.KeyCode.ButtonA)
```

## Priority and Sink

Use `setPriority` when multiple contexts listen for the same key.

- higher priority runs first
- lower priority can be blocked when sink is true

```lua
EZInput.context("Menu")
    :setPriority(10)
    :setSink(true)
    :enable()
```

Common setup:

- menu/UI context: higher priority + sink true
- gameplay context: lower priority
