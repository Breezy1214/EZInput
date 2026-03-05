---
sidebar_position: 1
---

# Quick Start

This page gets you from zero to a working keybind in under 5 minutes.

## Step 1: Require EZInput on the Client

EZInput is client-only because Roblox IAS is client-only.

```lua
local EZInput = require(path.to.EZInput)
```

## Step 2: Create a Context and Action

```lua
local combat = EZInput.context("Combat")
    :action("Attack")
        :bind(Enum.KeyCode.F)
        :action()
        :onPressed(function(actionName)
            print(actionName .. " pressed")
        end)
        :context()
    :enable()
```

## Step 3: Test It

1. Run your game client.
2. Press `F`.
3. You should see `Attack pressed` in output.

## What Just Happened

- `context("Combat")`: creates a named input group
- `action("Attack")`: creates an action under that group
- `bind(Enum.KeyCode.F)`: maps key `F` to that action
- `onPressed(...)`: callback when key goes down
- `enable()`: context starts processing input

## Cleanup

When done with the context (for example leaving a mode/screen), destroy it:

```lua
combat:destroy()
```

This removes actions, bindings, and connections safely.
