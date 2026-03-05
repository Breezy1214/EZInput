---
sidebar_position: 5
---

# Full Example: Gameplay + Menu

This is a practical setup you can copy as a starting point.

Goal:

- gameplay controls active during play
- menu controls take over when menu opens
- clean teardown when done

## Complete Example

```lua
local EZInput = require(path.to.EZInput)

local gameplay = EZInput.context("Gameplay")
    :setPriority(1)
    :setSink(false)
    :action("Jump")
        :bind(Enum.KeyCode.Space)
        :bind(Enum.KeyCode.ButtonA)
        :action()
        :onPressed(function(actionName)
            print(actionName, "pressed")
        end)
        :context()
    :action("Attack")
        :bind(Enum.KeyCode.F)
            :withModifier(Enum.KeyCode.LeftShift)
        :action()
        :onPressed(function()
            print("Heavy attack")
        end)
        :context()
    :enable()

local menu = EZInput.context("Menu")
    :setPriority(10)
    :setSink(true)
    :action("CloseMenu")
        :bind(Enum.KeyCode.Escape)
        :action()
        :onPressed(function()
            menu:disable()
            gameplay:enable()
            print("Menu closed")
        end)

local function openMenu()
    gameplay:disable()
    menu:enable()
    print("Menu opened")
end

-- Call this from your UI logic
actionOpenInventoryButton.MouseButton1Click:Connect(openMenu)

-- Optional cleanup when leaving the place/screen
local function cleanupInput()
    menu:destroy()
    gameplay:destroy()
end
```

## Why This Works

- `Menu` has higher priority, so it processes shared keys first.
- `Menu` uses sink, so gameplay does not also consume menu inputs.
- enabling/disabling contexts keeps logic simple and explicit.
- `destroy()` prevents leaked bindings/connections.

## Tip

If input behavior feels random, print when contexts are enabled/disabled.
Most issues come from the wrong context being active.
