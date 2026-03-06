# EZInput

A fluent, chainable builder API for Roblox's [Input Action System](https://create.roblox.com/docs/reference/engine/classes/InputAction). Define input contexts, actions, and key bindings in one readable expression — no boilerplate, no manual Instance wiring.

## Features

- **Fluent Builder Pattern** — chain methods to define your entire input setup in a single expression
- **Full IAS Power** — contexts, actions, bindings, priorities, sinks, and modifier keys
- **Event Callbacks** — `onPressed`, `onReleased`, and `onStateChanged` with clean signatures
- **Context Management** — enable, disable, set priority, and control input sinking
- **Modifier Keys** — Shift+F, Ctrl+G, and other key combos via `withModifier`
- **Automatic Cleanup** — built on [Janitor](https://github.com/howmanysmall/Janitor) for leak-free destruction
- **Fully Typed** — `--!strict` Luau type annotations throughout

## Installation

### Wally

Add to your `wally.toml`:

```toml
[dependencies]
EZInput = "breezy1214/ezinput@0.1.1"
```

## Quick Start

```lua
local EZInput = require(path.to.EZInput)

-- Create a combat context with an attack action bound to F
local combat = EZInput.context("Combat")
    :action("Attack")
        :bind(Enum.KeyCode.F)
        :action()
        :onPressed(function(actionName)
            print(actionName .. " triggered!")
        end)
        :context()
    :enable()
```

## Usage

### Contexts

Contexts group related input actions and control when they're active.

```lua
local menu = EZInput.context("Menu")
    :setPriority(10)       -- higher priority = processed first
    :setSink(true)         -- block lower-priority contexts
    :enable()

menu:disable()             -- pause input processing
menu:enable()              -- resume
menu:destroy()             -- clean up everything
```

### Actions & Callbacks

Actions represent player intents. Attach callbacks to respond to input.

```lua
EZInput.context("Combat")
    :action("Attack")
        :bind(Enum.KeyCode.F)
        :action()
        :onPressed(function(actionName)
            print("Pressed:", actionName)
        end)
        :onReleased(function(actionName)
            print("Released:", actionName)
        end)
        :onStateChanged(function(actionName, isPressed)
            print("State:", actionName, isPressed)
        end)
```

### Modifier Keys

Bind key combos using `withModifier` and `withSecondaryModifier`.

```lua
EZInput.context("Combat")
    :action("HeavyAttack")
        :bind(Enum.KeyCode.F)
            :withModifier(Enum.KeyCode.LeftShift)    -- Shift + F
        :action()
        :onPressed(function(actionName)
            print("Heavy attack!")
        end)
```

### Multiple Bindings

An action can have multiple key bindings.

```lua
EZInput.context("Movement")
    :action("Jump")
        :bind(Enum.KeyCode.Space)
        :bind(Enum.KeyCode.ButtonA)     -- gamepad support
        :action()
        :onPressed(function(actionName)
            print("Jump!")
        end)
```

### Raw Instance Access

Access the underlying Roblox Instances when you need direct IAS control.

```lua
local ctx = EZInput.context("Debug")
local rawContext = ctx:getRawInstance()  -- InputContext instance
```

## API Reference

### `EZInput.context(name: string) -> ContextBuilder`

Creates a new input context.

### ContextBuilder

| Method | Returns | Description |
|---|---|---|
| `action(name)` | `ActionBuilder` | Create an input action |
| `enable()` | `ContextBuilder` | Enable input processing |
| `disable()` | `ContextBuilder` | Disable input processing |
| `setPriority(n)` | `ContextBuilder` | Set context priority (higher = first) |
| `setSink(bool)` | `ContextBuilder` | Block lower-priority contexts when active |
| `destroy()` | `nil` | Clean up all actions, bindings, and connections |
| `getRawInstance()` | `InputContext` | Access the underlying Roblox instance |

### ActionBuilder

| Method | Returns | Description |
|---|---|---|
| `bind(keyCode)` | `BindingBuilder` | Create a key binding |
| `onPressed(callback)` | `ActionBuilder` | Register press callback `(actionName) -> ()` |
| `onReleased(callback)` | `ActionBuilder` | Register release callback `(actionName) -> ()` |
| `onStateChanged(callback)` | `ActionBuilder` | Register state change callback `(actionName, isPressed) -> ()` |
| `getState()` | `boolean` | Get current action state |
| `context()` | `ContextBuilder` | Navigate back to parent context |
| `getRawInstance()` | `InputAction` | Access the underlying Roblox instance |

### BindingBuilder

| Method | Returns | Description |
|---|---|---|
| `withModifier(keyCode)` | `BindingBuilder` | Set primary modifier key |
| `withSecondaryModifier(keyCode)` | `BindingBuilder` | Set secondary modifier key |
| `action()` | `ActionBuilder` | Navigate back to parent action |
| `context()` | `ContextBuilder` | Navigate back to root context |
| `getRawInstance()` | `InputBinding` | Access the underlying Roblox instance |

## License

MIT
