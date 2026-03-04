# Roadmap: EZInput

## Overview

EZInput ships as a three-phase Wally package. Phase 1 establishes the project scaffold, strict-type skeleton, and IAS architectural guardrails that all subsequent work depends on. Phase 2 delivers the entire core value proposition: the fluent builder chain for Bool actions on keyboard/mouse with full context management. Phase 3 extends input coverage to gamepad and touch, adds modifier key support, and ships the programmatic rebinding and named registry APIs that make EZInput production-ready for keybind settings UIs.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Wally package scaffold, strict-type skeleton, IAS architectural guardrails (completed 2026-03-04)
- [ ] **Phase 2: Core Builder** - Fluent builder chain for Bool actions, keyboard/mouse bindings, full context management
- [ ] **Phase 3: Input Extensions and DX** - Gamepad/touch bindings, modifier keys, rebinding API, named registry

## Phase Details

### Phase 1: Foundation
**Goal**: A Wally-installable package skeleton exists with strict Luau types, the IAS client guard, and adapter-layer stubs that protect all subsequent work from IAS beta breakage
**Depends on**: Nothing (first phase)
**Requirements**: DEVX-01, DEVX-02, DEVX-03
**Success Criteria** (what must be TRUE):
  1. Developer can add EZInput to a Roblox project via `wally install` and require it without errors
  2. `Types.luau` exports typed interfaces that Luau's strict mode resolves without errors at the call site
  3. Requiring EZInput on the server throws a clear error (RunService:IsClient() guard)
  4. All source files pass StyLua and Selene without warnings
**Plans**: 2 plans

Plans:
- [x] 01-01: Rokit + Rojo + Wally project scaffold (wally.toml, default.project.json, .luaurc, rokit.toml)
- [ ] 01-02: Types.luau skeleton and IAS adapter stubs (client guard, adapter modules, CI workflow)

### Phase 2: Core Builder
**Goal**: Developer can write a single fluent expression to create a context, define a Bool action, bind a keyboard or mouse key, and receive Pressed/Released/StateChanged callbacks — with context enable/disable, priority, and sink working correctly
**Depends on**: Phase 1
**Requirements**: BLDR-01, BLDR-02, BLDR-03, BLDR-04, BLDR-05, BLDR-06, CTXT-01, CTXT-02, CTXT-03, INPT-01, INPT-02
**Success Criteria** (what must be TRUE):
  1. Developer can call `EZInput.context("Combat"):action("Attack"):bind(Enum.KeyCode.F):onPressed(fn)` in one expression and receive the callback when F is pressed
  2. A context with higher priority receives input before a lower-priority context bound to the same key
  3. A context with Sink enabled prevents lower-priority contexts from receiving the same input
  4. Calling `:destroy()` on a context removes all child instances and disconnects all callbacks without memory leaks
  5. Pressing a bound key fires Pressed; releasing fires Released; both fire StateChanged
**Plans**: TBD

Plans:
- [ ] 02-01: ContextBuilder and ActionBuilder with Trove cleanup and back-reference chaining
- [ ] 02-02: BindingBuilder for keyboard/mouse KeyCodes with explicit threshold defaults (Sink fix)
- [ ] 02-03: Context enable/disable, priority, and sink wiring; onPressed/onReleased/onStateChanged callbacks

### Phase 3: Input Extensions and DX
**Goal**: Developer can bind gamepad buttons, modifier key combos, and UIButton touch inputs using the same chain, and can rebind any action by name at runtime without rewriting setup code
**Depends on**: Phase 2
**Requirements**: INPT-03, INPT-04, INPT-05, DEVX-04, DEVX-05
**Success Criteria** (what must be TRUE):
  1. Developer can bind a gamepad button (e.g., Enum.KeyCode.ButtonA) using the same `:bind()` call as keyboard
  2. Developer can call `:modifier(Enum.KeyCode.LeftShift)` on a binding and the callback only fires when both keys are held
  3. Developer can pass a UIButton instance to `:bind()` and the callback fires on mobile tap
  4. Developer can call `EZInput.getContext("Combat"):getAction("Attack"):rebind(Enum.KeyCode.G)` to change the key at runtime without re-creating the context
  5. Developer can look up a context or action by the name string used at creation time
**Plans**: TBD

Plans:
- [ ] 03-01: Gamepad button binding support and known-limitations documentation
- [ ] 03-02: Modifier key support (PrimaryModifier/SecondaryModifier on BindingBuilder)
- [ ] 03-03: UIButton touch binding support
- [ ] 03-04: Programmatic rebinding API and named action/context registry

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete   | 2026-03-04 |
| 2. Core Builder | 0/3 | Not started | - |
| 3. Input Extensions and DX | 0/4 | Not started | - |
