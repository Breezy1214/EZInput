# EZInput Cheat Sheet

A fast reference for everyday use.

## Basic Flow

```lua
local ctx = EZInput.context("MyContext")
    :action("MyAction")
        :bind(Enum.KeyCode.F)
        :action()
        :onPressed(function(actionName)
            print(actionName)
        end)
        :context()
    :enable()
```

## Navigation Between Builders

- `context(...):action(...)` -> `ActionBuilder`
- `action:bind(...)` -> `BindingBuilder`
- `binding:action()` -> `ActionBuilder`
- `binding:context()` -> `ContextBuilder`

## ContextBuilder Methods

- `action(name)`
- `enable()`
- `disable()`
- `setPriority(priority)`
- `setSink(sink)`
- `destroy()`
- `getRawInstance()`

## ActionBuilder Methods

- `bind(keyCode)`
- `onPressed(callback)`
- `onReleased(callback)`
- `onStateChanged(callback)`
- `getState()`
- `context()`
- `destroy()`
- `getRawInstance()`

## BindingBuilder Methods

- `withModifier(keyCode)`
- `withSecondaryModifier(keyCode)`
- `action()`
- `context()`
- `destroy()`
- `getRawInstance()`

## Useful Snippets

Modifier combo:

```lua
:bind(Enum.KeyCode.F):withModifier(Enum.KeyCode.LeftShift)
```

Multi-input action:

```lua
:bind(Enum.KeyCode.Space)
:bind(Enum.KeyCode.ButtonA)
```

Cleanup:

```lua
ctx:destroy()
```
