---
sidebar_position: 1
---

# EZInput Docs

EZInput is a fluent builder for Roblox Input Action System (IAS).

## Read This In Order

1. [Quick Start](./guides/quick-start)
2. [Core Concepts](./guides/core-concepts)
3. [Common Patterns](./guides/common-patterns)
4. [Full Example: Gameplay + Menu](./guides/full-example)
5. [Troubleshooting](./guides/troubleshooting)
6. [API Cheat Sheet](/cheat-sheet)

## Mental Model

You build input in 3 layers:

1. Context: a group of related controls (for example: `Combat`, `Menu`)
2. Action: a named intent (for example: `Attack`, `OpenInventory`)
3. Binding: one key or button that triggers the action

Example chain:

```lua
EZInput.context("Combat")
    :action("Attack")
        :bind(Enum.KeyCode.F)
        :action()
        :onPressed(function(actionName)
            print(actionName)
        end)
```

When in doubt, remember this navigation rule:

- `:bind(...)` moves you to `BindingBuilder`
- `:action()` moves you back to `ActionBuilder`
- `:context()` moves you back to `ContextBuilder`
