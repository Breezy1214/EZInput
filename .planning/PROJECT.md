# EZInput

## What This Is

A Wally package that provides a clean, fluent builder-pattern API over Roblox's new Input Action System (InputContext → InputAction → InputBinding). EZInput eliminates the boilerplate of creating and configuring Instance hierarchies while exposing the full power of contexts, actions, and bindings. It targets Roblox game developers who want ergonomic input handling across keyboard/mouse, gamepad, and touch.

## Core Value

Developers can define input contexts, actions, and bindings in a readable chainable API — without manually creating and parenting Instance trees — while retaining full access to context switching, priority, and sinking.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Builder-pattern API: `EZInput.context("Combat"):action("Attack"):bind(KeyCode.F):onPressed(fn)`
- [ ] Context management with enable/disable, priority, and sink support
- [ ] Bool (button) action type support (Pressed, Released, StateChanged events)
- [ ] Keyboard/mouse binding support
- [ ] Gamepad binding support (buttons, triggers, thumbsticks)
- [ ] Touch binding support via UIButton property
- [ ] Modifier key support (PrimaryModifier, SecondaryModifier)
- [ ] Rebinding API (programmatic — change bindings at runtime, no UI)
- [ ] Full --!strict Luau typing with exported types for consumers
- [ ] Wally package structure (wally.toml, proper src layout)
- [ ] Modular architecture (separate modules for Context, Action, Binding, etc.)

### Out of Scope

- Direction1D/2D/3D action types — v1 focuses on Bool; directional types deferred
- Built-in rebinding UI — devs build their own using the rebinding API
- Unit tests — deferred for v1
- Composite direction bindings (WASD → Vector2) — tied to directional types
- Server-side input handling — IAS is client-only

## Context

- Roblox's Input Action System (IAS) is in Client Beta as of August 2025 and can be published in live experiences
- IAS replaces UserInputService and ContextActionService for input mapping
- The IAS hierarchy: InputContext (container) → InputAction (gameplay mechanic) → InputBinding (hardware mapping)
- Community feedback highlights the system is boilerplate-heavy and needs wrapper libraries
- InputAction.Type determines state shape (Bool → boolean, Direction2D → Vector2, etc.)
- InputContext.Priority controls execution order; InputContext.Sink blocks lower-priority contexts
- InputBinding supports KeyCode, modifiers, UIButton, thresholds, response curves, and scaling
- Scripts must use RunContext = Client

## Constraints

- **Runtime**: Client-only — IAS instances only work on the client
- **Roblox API**: Must use InputAction, InputBinding, InputContext Instances (not reimplementing)
- **Package format**: Wally package with standard structure
- **Luau**: --!strict throughout, exported types
- **IAS Beta**: API surface may change; design for adaptability

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Builder pattern API | Chainable calls are readable and reduce boilerplate vs config tables | — Pending |
| Bool-only for v1 | Covers majority of game actions; directional types add complexity | — Pending |
| No built-in rebinding UI | Keep package focused; expose API for devs to build their own | — Pending |
| Strict Luau typing | Better DX with autocomplete and type safety | — Pending |

---
*Last updated: 2026-03-04 after initialization*
