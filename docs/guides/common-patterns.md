---
sidebar_position: 3
---

# Common Patterns

## Pattern 1: Modifier Keys

```lua
EZInput.context("Combat")
    :action("HeavyAttack")
        :bind(Enum.KeyCode.F)
            :withModifier(Enum.KeyCode.LeftShift)
        :action()
        :onPressed(function()
            print("Heavy attack")
        end)
```

## Pattern 2: Separate UI and Gameplay Input

```lua
local gameplay = EZInput.context("Gameplay")
    :setPriority(1)
    :setSink(false)
    :enable()

local menu = EZInput.context("Menu")
    :setPriority(10)
    :setSink(true)
```

When menu opens:

```lua
menu:enable()
gameplay:disable()
```

When menu closes:

```lua
menu:disable()
gameplay:enable()
```

## Pattern 3: Shared Action Callback Helpers

```lua
local function logPressed(actionName)
    print("Pressed:", actionName)
end

EZInput.context("Debug")
    :action("Ping")
        :bind(Enum.KeyCode.P)
        :action()
        :onPressed(logPressed)
```

## Pattern 4: Raw Instance Access (Advanced)

```lua
local ctx = EZInput.context("Debug")
local rawContext = ctx:getRawInstance()
print(rawContext.Name)
```

Use this only when you need behavior not exposed by the builder API.
