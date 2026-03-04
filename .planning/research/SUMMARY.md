# Project Research Summary

**Project:** EZInput
**Domain:** Roblox Luau Wally package — Input Action System (IAS) fluent builder wrapper
**Researched:** 2026-03-04
**Confidence:** MEDIUM — IAS is in Client Beta; toolchain and patterns are well-established, but the underlying engine API has already shipped one breaking change and has active bugs

## Executive Summary

EZInput is a focused Luau library that wraps Roblox's Input Action System (IAS) with a fluent builder API. The product need is real: raw IAS requires manually constructing and parenting Instance trees across 3-5 statements per action, and no existing community wrapper is both IAS-native and Wally-installable with full `--!strict` type coverage. The target audience is Rojo-based Roblox developers who expect Wally packaging, strict types, and a low-ceremony call site — a niche that none of the researched alternatives (InputContextHandler, UserInput Module, MasterInputManager) fills completely.

The recommended approach is a three-layer builder API: `ContextBuilder` → `ActionBuilder` → `BindingBuilder`, each wrapping the corresponding IAS Instance directly. This is not a reimplementation — EZInput delegates all input processing to the IAS engine and simply provides ergonomic construction. The v1 scope is intentionally narrow: Bool action type only, keyboard/mouse/gamepad button bindings, context enable/disable/priority/sink, and a cleanup story built on Trove. Directional action types (Direction2D/1D/3D), rebinding APIs, and touch bindings are explicitly v1.x/v2 scope based on active engine bugs and API surface complexity.

The dominant risk is IAS's beta status. Roblox shipped a silent breaking change on February 24, 2026 (exclusive bindings), has active bugs in Sink behavior and gamepad thumbstick handling, and has confirmed that IAS events replicate to the server in ways that can cause cross-player event contamination. All of these risks are mitigable through an adapter-layer architecture, an early `RunService:IsClient()` guard, and deliberate threshold-setting on bindings — but they must be addressed in the foundation phase before any feature work, not retroactively.

## Key Findings

### Recommended Stack

The toolchain for a Wally package is well-established and should require no deliberation. Rokit (v1.2.0) manages tool versions, replacing the abandoned Aftman. Rojo (v7.6.x) handles file sync. Wally (v0.3.2) is the package registry all target consumers use. StyLua (v2.3.1) and Selene (v0.30.1) enforce code quality and should run in CI on every PR. The entire project needs zero Wally dependencies for v1 — IAS is a native Roblox API, but Trove should be added as a Wally dependency for lifecycle management. The project can be published to the Wally registry or distributed as a GitHub release; both are valid distribution strategies.

**Core technologies:**
- Luau (`--!strict` via `.luaurc`): implementation language — strict mode is mandatory for consumer autocomplete and type safety
- Wally 0.3.2: package registry — the standard Rojo-based developers use; no viable alternative for v1
- Rojo 7.6.x: file sync — required for external-editor workflow; `default.project.json` maps `src/` as the require target
- Rokit 1.2.0: toolchain manager — replaces abandoned Aftman; pins tool versions for reproducible CI
- StyLua 2.3.1 + Selene 0.30.1: code quality — run in CI; non-negotiable for a published package
- Trove (Sleitnick/RbxUtil): lifecycle cleanup — the community standard for Instance + signal cleanup in Roblox; avoids reinventing cleanup logic

### Expected Features

The v1 feature set is driven by what makes EZInput useful over raw IAS and distinct from existing wrappers. The highest-leverage differentiator is collapsing context + action + binding + handler into a single chainable expression. No existing wrapper achieves this fully. The second differentiator is Wally packaging with strict types — no competitor offers this. Modifier key support (PrimaryModifier/SecondaryModifier, added to IAS in February 2026) is low-cost and provides immediate first-mover advantage.

**Must have (table stakes):**
- Fluent builder chain: `EZInput.context("X"):action("Y"):bind(KeyCode.F):onPressed(fn)` — the entire value proposition
- Bool action type (Pressed / Released / StateChanged) — covers 90%+ of real game actions (jump, attack, sprint, interact)
- Keyboard and mouse KeyCode bindings — required for PC, Roblox's largest platform segment
- Gamepad button bindings (ButtonA, ButtonB, triggers — not thumbstick axes) — required for cross-platform claim
- Context enable / disable, priority, sink — the IAS context management primitives; without these it is just boilerplate reduction
- Cleanup / destroy on context and action objects — memory leaks are the most-cited flaw in existing wrappers
- Full `--!strict` Luau types with exported consumer types — non-negotiable for modern published packages
- Wally package structure (`wally.toml`, `src/` layout, `default.project.json`) — required for target audience

**Should have (competitive, v1.x):**
- Modifier key support (PrimaryModifier / SecondaryModifier) — IAS-native, low-cost, no competitor has it via the native API
- Programmatic rebinding API — the #1 missing IAS feature; enables keybind settings UIs
- Named action registry — enables consumers to look up and rebind by name; pairs with rebinding API
- Touch binding via UIButton — fills mobile gap; no existing wrapper exposes this

**Defer (v2+):**
- Direction2D action type — active engine bugs in gamepad thumbstick handling; complex API surface
- Direction1D and Direction3D action types — builds on Direction2D; defer until that is stable
- ViewportPosition action type — specialized; most games use existing mouse APIs
- Built-in rebinding UI — anti-feature; couples package to a UI style; expose the API and document instead
- DataStore persistence for keybinds — out of scope; expose serializable get/set API and let devs own persistence

### Architecture Approach

The architecture is a three-class builder stack — `ContextBuilder`, `ActionBuilder`, `BindingBuilder` — each wrapping its corresponding IAS Instance. A `Types.luau` module holds all exported type definitions with no runtime logic, enabling `--!strict` throughout. The `init.luau` entry point is a thin factory that calls `ContextBuilder.new()` and re-exports types. Each builder uses the back-reference pattern (child holds reference to parent) so that chaining can traverse back up the tree (e.g., define a second action after fully configuring the first without re-assigning a variable). Lifecycle cleanup is managed by a Trove instance per builder. A critical architectural addition from PITFALLS.md: all direct IAS Instance property access should be isolated in adapter sub-modules so that IAS beta changes only require updating adapters, not rebuilding the feature layer.

**Major components:**
1. `init.luau` (EZInput entry point) — thin factory; single public entry point for consumers
2. `ContextBuilder` — wraps `InputContext`; manages enable/disable/priority/sink; owns flat registry of child ActionBuilders
3. `ActionBuilder` — wraps `InputAction`; connects Pressed/Released/StateChanged events via Trove; exposes `.bind()` chain
4. `BindingBuilder` — wraps `InputBinding`; sets KeyCode/UIButton/modifiers/thresholds; deferred parenting until chain seals
5. `Types.luau` — exported `--!strict` interface types; no runtime logic; prevents circular requires between builder modules
6. Trove (external, via Wally) — bulk cleanup of Instances and signal connections on `:destroy()`

**Build order (dependency-driven):**
Types → BindingBuilder → ActionBuilder → ContextBuilder → init.luau

### Critical Pitfalls

1. **IAS events fire on server / cross-player contamination** — add `assert(RunService:IsClient())` at module init, enforce client-only design; never document server-side event listeners. Must be done in the foundation phase, not retroactively.

2. **Exclusive-binding breaking change (Feb 24, 2026)** — one InputBinding instance may only hold one input source. Design `.bind()` to create one InputBinding per call. If a dev wants keyboard E and a UIButton, they must call `.bind()` twice. Enforce this at the API level from day one.

3. **Sink broken by hidden threshold defaults** — when creating a digital KeyCode binding, always explicitly set `PressedThreshold = 0.5` and `ReleasedThreshold = 0.2` on the InputBinding. Do not rely on engine defaults. Missing this makes context priority and Sink silently misbehave.

4. **StarterGui vs. PlayerGui — wrong parent breaks everything** — all IAS Instance creation must target `LocalPlayer.PlayerGui` (or another runtime-accessible client container), never StarterGui. StarterGui is a template; the live clone is in PlayerGui. Events and GetState silently fail on the template. Must be locked down in the foundation phase.

5. **IAS is a beta API — adapter pattern is mandatory** — Roblox already broke multi-source bindings silently. Isolate all direct IAS property access in adapter modules. The public EZInput API should never reference IAS property names directly. Future Roblox changes then require updating only the adapter layer.

## Implications for Roadmap

Based on combined research, the correct build order is bottom-up through the dependency chain, with all architectural guardrails established before any feature work.

### Phase 1: Foundation and Project Scaffold

**Rationale:** All subsequent phases depend on the toolchain, package structure, and architectural guardrails established here. IAS pitfalls 2, 4, and 5 (server replication guard, StarterGui/PlayerGui parent, adapter pattern) must be in place before any IAS Instance creation code is written. Doing this last would require grepping and restructuring the entire codebase.

**Delivers:** Working Wally package structure; Rokit/Rojo/StyLua/Selene toolchain; CI workflow; `.luaurc` strict mode; `RunService:IsClient()` guard in `init.luau`; flat context registry design; IAS adapter module stubs; `Types.luau` skeleton with exported interface shapes.

**Addresses:** Wally-installable package (table stakes), `--!strict` Luau types (table stakes)

**Avoids:** Server-side event replication (Pitfall 2), StarterGui parent bug (Pitfall 4), IAS beta breakage without adapter isolation (Pitfall 8), nested InputContext ignored silently (Pitfall 6)

**Research flag:** Standard patterns — Wally/Rojo/Rokit toolchain setup is well-documented; no phase-level research needed.

### Phase 2: Core Builder Chain (Bool Actions, Keyboard/Mouse)

**Rationale:** This is the entire core value proposition. Without the fluent chain, EZInput has no reason to exist. Bool action type covers 90%+ of real game actions. Keyboard/mouse is required to be useful on PC. This phase validates the builder API design before expanding to more input surfaces.

**Delivers:** `ContextBuilder`, `ActionBuilder`, `BindingBuilder` implemented with back-reference chaining; `onPressed` / `onReleased` / `onStateChanged` callbacks via Trove; context enable/disable/priority/sink (with explicit PressedThreshold/ReleasedThreshold to fix Sink bug); Trove-per-builder cleanup; `:destroy()` on all builders.

**Addresses:** Fluent builder chain (P1), Bool action type (P1), keyboard/mouse binding (P1), context management primitives (P1), cleanup/destroy (P1)

**Avoids:** Exclusive-binding design (Pitfall 1 — one source per `.bind()` call enforced structurally), Sink threshold bug (Pitfall 3 — explicit threshold setting), connecting events before parenting bindings (Architecture anti-pattern 2), rebuilding contexts on state change instead of toggling (Architecture anti-pattern 4)

**Research flag:** May need targeted research on Trove API if integration with IAS Instance lifecycle is unclear. Otherwise patterns are established.

### Phase 3: Gamepad Button Binding

**Rationale:** Gamepad support is a table-stakes requirement for cross-platform "write once, play everywhere" positioning. Gamepad button bindings (ButtonA, ButtonB, triggers) use the same Bool action type and KeyCode system as keyboard — low additional complexity. However, Pitfall 7 (Thumbstick1/ButtonA sunk by default PlayerScripts) requires documentation work and known-limitations notes. This is separated from Phase 2 to allow validation of the keyboard API first.

**Delivers:** Verified gamepad button binding support; known-limitations documentation for Thumbstick1, ButtonA, ButtonR2, Shift; optional warning comments in source for restricted keycodes.

**Addresses:** Gamepad button binding (P1 table stakes)

**Avoids:** Gamepad thumbstick broken by PlayerScripts (Pitfall 7 — document restricted inputs, do not defer the phase, just the axis types)

**Research flag:** Standard patterns for this phase. Verification must be done in a published experience, not just Studio Solo — note this in the phase plan.

### Phase 4: Modifier Key Support

**Rationale:** IAS added `PrimaryModifier` and `SecondaryModifier` to `InputBinding` in February 2026. This is a property on the BindingBuilder level, so it costs almost nothing to implement once Phase 2's BindingBuilder is in place. It provides immediate competitive differentiation — no existing wrapper exposes native IAS modifier support. First-mover advantage justifies adding it before the more complex Phase 5 work.

**Delivers:** `.modifier(primaryKey, secondaryKey?)` or equivalent method on the builder chain; exposed through the existing BindingBuilder; updated Types.luau with modifier-aware binding types.

**Addresses:** Modifier key support (P1 differentiator per feature research)

**Avoids:** No new pitfalls — modifier support piggybacks on the BindingBuilder already built in Phase 2.

**Research flag:** Skip research-phase. Well-defined IAS properties; low complexity.

### Phase 5: Context Toggle Race Condition Mitigation and Hardening

**Rationale:** Pitfall 5 (first input after context re-enable drops) requires a documented workaround and potentially a one-Heartbeat yield after `.enable()`. This is separate from Phase 2 because it is discovered through testing, not design. This phase is about hardening the existing implementation based on edge-case behavior, and producing a "Looks Done But Isn't" verification pass matching the checklist from PITFALLS.md.

**Delivers:** Context re-enable hardening; Heartbeat yield mechanism or documentation; full "Looks Done But Isn't" checklist pass (Sink behavior, multi-client, cleanup memory profiling, strict types consumer test).

**Addresses:** Context toggle race (Pitfall 5), multi-client contamination verification (Pitfall 2 final check), cleanup verification

**Avoids:** Shipping with silent first-event-drop after context activation

**Research flag:** No additional research needed — pitfall is documented with confirmed fix strategy.

### Phase 6: v1.x Extensions (Rebinding, Registry, Touch, Direction1D)

**Rationale:** These features add significant value but depend on the core builder API being validated and stable first. The programmatic rebinding API and named action registry are paired (rebinding is most useful when actions can be looked up by name). Touch binding via UIButton slots into the existing BindingBuilder. Direction1D is the simplest directional type and a natural extension of the Bool chain. These are deferred until core adoption confirms the v1 API design is correct.

**Delivers:** `context:rebind(actionName, newKeyCode)` API; named action registry (`EZInput.getContext(name)`, `context.getAction(name)`); UIButton binding via `.bindButton(uiButton)` on the chain; Direction1D action type support.

**Addresses:** Programmatic rebinding (P2), named action registry (P2), touch binding (P2), Direction1D (P2)

**Avoids:** Rebinding-while-pressed stuck-state bug (PITFALLS.md UX section — reset action state before changing bindings), UIButton StarterGui reference (Pitfall 4 extension — document that UIButton must be PlayerGui-side)

**Research flag:** Touch binding via UIButton needs targeted research — IAS UIButton parenting behavior is documented but not widely tested in wrappers. Flag for per-feature research during Phase 6 planning.

### Phase Ordering Rationale

- **Foundation first:** Pitfalls 2, 4, 6, and 8 must be baked into the initial architecture. All four are significantly more expensive to retrofit than to build in from the start.
- **Types before builders:** The ARCHITECTURE.md build order (Types → BindingBuilder → ActionBuilder → ContextBuilder → init.luau) is dependency-driven. Reversing this order would require circular require hacks.
- **Keyboard before gamepad:** Phase 2 validates the builder API on the simpler surface before adding gamepad-specific verification complexity in Phase 3.
- **Modifier keys before rebinding:** Modifier key support (Phase 4) is a BindingBuilder property addition — nearly free given Phase 2. Rebinding (Phase 6) is a registry + lifecycle concern — higher complexity that deserves its own phase.
- **Hardening phase before extensions:** Phase 5 verifies the core before v1.x features are added. This prevents the "Looks Done But Isn't" problems from being masked by new feature work.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 6 (Touch binding):** UIButton binding with IAS at runtime is sparsely documented and untested by any existing wrapper. Needs per-feature research before implementation planning.
- **Phase 6 (Direction1D):** IAS analog action types have a different state shape and binding topology than Bool. While simpler than Direction2D, the API design should be researched before implementation to ensure the builder chain extends cleanly.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Toolchain):** Wally/Rojo/Rokit/StyLua/Selene setup is thoroughly documented in official sources. Follow STACK.md directly.
- **Phase 2 (Core builder chain):** Builder pattern with back-references and Trove cleanup is established in the community and validated by reference implementations. ARCHITECTURE.md provides sufficient detail.
- **Phase 3 (Gamepad buttons):** Uses identical API surface to keyboard. No new patterns required — add known-limitations documentation only.
- **Phase 4 (Modifier keys):** IAS `PrimaryModifier`/`SecondaryModifier` are documented properties. Direct implementation from FEATURES.md findings.
- **Phase 5 (Hardening):** Workarounds are documented in PITFALLS.md. No new research needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All tool versions verified via official GitHub releases; toolchain is stable independent of IAS beta status |
| Features | HIGH | IAS API confirmed via official creator-docs; competitor feature gaps confirmed by source code review (InputContextHandler) and DevForum posts |
| Architecture | MEDIUM | Builder pattern and back-reference approach are well-established; Trove integration is confirmed; IAS-specific parenting behavior (PlayerGui vs StarterGui) confirmed by bug reports. Adapter pattern is a recommendation, not a tested implementation |
| Pitfalls | HIGH | All critical pitfalls backed by official Roblox DevForum bug reports with staff acknowledgments; February 2026 exclusive-binding change confirmed via official announcement thread |

**Overall confidence:** MEDIUM-HIGH — the toolchain and patterns are solid; the primary uncertainty is IAS beta API stability, which is mitigated architecturally rather than eliminated.

### Gaps to Address

- **IAS beta changes post-research:** No protection against future breaking changes beyond the adapter pattern recommendation. Monitor the IAS Client Beta DevForum announcement thread actively during development. Budget time in each phase for potential IAS updates.
- **Trove integration with IAS Instance cleanup ordering:** ARCHITECTURE.md recommends Trove but doesn't verify that `trove:Destroy()` correctly handles the `InputContext` → `InputAction` → `InputBinding` parent-child destruction order. Validate in Phase 2 that destroying the Trove on ContextBuilder does not cause double-destroy errors on child instances.
- **UIButton parenting in IAS at runtime:** No existing wrapper has implemented this. The PITFALLS.md guidance (use PlayerGui-side reference) is correct in principle but untested for UIButton specifically. Flag for Phase 6 research.
- **Modifier key behavior with Sink:** The interaction between `PrimaryModifier` bindings and `InputContext.Sink` is undocumented. Test in Phase 4 whether a modified binding (Shift+F) in a high-priority Sink context correctly blocks a lower-priority context bound to bare F.
- **Context registry namespacing:** If two scripts create contexts with the same name, the v1.x named action registry will have a collision. Design the registry key format (e.g., `"ContextName.ActionName"`) before Phase 6 implementation to avoid a breaking API change later.

## Sources

### Primary (HIGH confidence)
- [create.roblox.com — IAS Client Beta Announcement](https://devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979) — official API surface, February 2026 modifier key additions, exclusive-binding change
- [create.roblox.com — InputBinding API Reference](https://create.roblox.com/docs/reference/engine/classes/InputBinding) — official property documentation
- [github.com/UpliftGames/wally](https://github.com/UpliftGames/wally) — Wally README and wally.toml format
- [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit) — Rokit as Aftman successor, v1.2.0
- [github.com/JohnnyMorganz/StyLua](https://github.com/JohnnyMorganz/StyLua) — StyLua v2.3.1
- [github.com/Kampfkarren/selene/releases](https://github.com/Kampfkarren/selene/releases) — selene v0.30.1
- [devforum.roblox.com — InputContext Sink bug](https://devforum.roblox.com/t/inputcontext-sink-property-doesnt-behave-properly/4110680) — Sink threshold pitfall, staff acknowledged
- [devforum.roblox.com — IAS events fire on server](https://devforum.roblox.com/t/ias-actions-fire-when-pressing-keys-from-the-servers-point-of-view/4164638) — server replication pitfall, staff acknowledged
- [devforum.roblox.com — Context toggle race condition](https://devforum.roblox.com/t/input-action-not-being-fire-reliably-when-input-context-being-toggled-on-and-off/4015442) — Roblox confirmed fix released
- [sleitnick.github.io/RbxUtil/api/Trove](https://sleitnick.github.io/RbxUtil/api/Trove/) — Trove lifecycle management
- [roblox.github.io/lua-style-guide](https://roblox.github.io/lua-style-guide/) — official Roblox Lua style guide
- [create.roblox.com — Luau type checking](https://create.roblox.com/docs/luau/type-checking) — strict mode and exported types guidance

### Secondary (MEDIUM confidence)
- [github.com/ivasmigins/InputContextHandler](https://github.com/ivasmigins/InputContextHandler) — reference implementation; validates builder-per-IAS-type pattern and confirms gap in Wally publishing
- [devforum.roblox.com — MasterInputManager](https://devforum.roblox.com/t/masterinputmanager-advanced-keybind-system-with-priority-input-sinking-multi-key-support/3660444) — competitor analysis; multi-key via UIS hack vs. native IAS PrimaryModifier
- [devforum.roblox.com — UserInput Module](https://devforum.roblox.com/t/introducing-userinput-module/3868398) — competitor analysis; not IAS-native
- [devforum.roblox.com — BetterInput](https://devforum.roblox.com/t/betterinput-a-better-userinputservice/2270466) — anti-pattern analysis; memory leak criticism
- [devforum.roblox.com — IAS gamepad thumbstick bug](https://devforum.roblox.com/t/inputbinding-inputaction-broken-for-gamepad-thumbstick1-and-buttona/4451342) — Thumbstick1/ButtonA sunk by PlayerScripts
- [devforum.roblox.com — InputSystem instance-free wrapper](https://devforum.roblox.com/t/inputsystem-robloxs-new-input-action-system-without-instances/3768911) — validates demand for programmatic IAS wrappers
- [devforum.roblox.com — Method chaining in Luau](https://devforum.roblox.com/t/method-chaining-in-lua-oop/1786788) — builder back-reference pattern validation

### Tertiary (LOW confidence)
- [robloxapi.github.io/ref/class/InputContext.html](https://robloxapi.github.io/ref/class/InputContext.html) — unofficial API mirror; used to cross-check InputContext properties against official docs

---
*Research completed: 2026-03-04*
*Ready for roadmap: yes*
