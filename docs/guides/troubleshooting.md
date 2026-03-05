---
sidebar_position: 4
---

# Troubleshooting

## Nothing Happens When Pressing a Key

Check these first:

1. Context is enabled: `context:enable()`
2. Script runs on client
3. Action has at least one binding
4. Callback is attached after action creation

## Duplicate Context Name

Context names are unique in runtime registry.

Fix by using unique names:

- good: `Gameplay`, `Menu`, `Inventory`
- bad: creating `Menu` twice without destroying first

## Duplicate Binding On Action

You cannot bind the exact same key twice to one action.

Fix by:

- removing duplicate `:bind(...)`
- or use a different key/button

## Input Conflicts Between Systems

Use priority + sink:

```lua
ui:setPriority(10):setSink(true)
gameplay:setPriority(1):setSink(false)
```

## Memory/Connection Leaks

Always destroy contexts you no longer need:

```lua
context:destroy()
```
