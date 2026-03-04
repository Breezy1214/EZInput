# Feature Research

**Domain:** Roblox IAS input wrapper / handler package
**Researched:** 2026-03-04
**Confidence:** HIGH (IAS API from official Roblox creator-docs; community wrappers from DevForum and GitHub; pain points from live bug reports)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume any IAS wrapper has. Missing these and the package is incomplete for its stated purpose.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Builder / fluent chainable API | The whole reason to use a wrapper; raw IAS requires manually constructing and parenting Instance trees. Every community wrapper (InputContextHandler, UserInput Module, MasterInputManager) offers a cleaner call-site. | MEDIUM | Core design decision already made: `EZInput.context("X"):action("Y"):bind(KeyCode.F):onPressed(fn)` |
| Bool action type (Pressed / Released / StateChanged) | Bool is the dominant action type for game actions (jump, attack, sprint, interact). Every wrapper researched covers this. Omitting it means covering 0% of real use cases. | LOW | Covered by IAS `InputAction.Type = Enum.InputActionType.Bool`; events fire with boolean state |
| Keyboard / mouse binding support | The default input surface on PC — the largest Roblox platform segment. Any tool without KB/mouse support is unusable for most devs. | LOW | IAS `InputBinding.KeyCode` accepts `Enum.KeyCode`; mouse buttons are KeyCodes |
| Gamepad binding support | Roblox supports console and gamepad play; IAS was designed with cross-platform "write once, play everywhere" in mind. Community tools all include gamepad. | LOW | `Enum.KeyCode` covers `ButtonA`, triggers, thumbstick buttons; `Thumbstick1`/`Thumbstick2` are separate |
| Context enable / disable | IAS's primary organizational primitive. Without this a wrapper cannot expose context-scoped input switching (e.g., Combat vs. Menu vs. Vehicle). | LOW | `InputContext.Enabled` toggle; wrapper must surface this cleanly |
| Context priority control | Priority determines execution order when multiple contexts bind the same key. Essential for correct behavior (UI overlapping combat, dialogs blocking movement). | LOW | `InputContext.Priority` integer property |
| Context sink support | Sink prevents lower-priority contexts from firing for the same input. Without exposing this, a wrapper cannot fully model context exclusivity. | LOW | `InputContext.Sink` boolean; note: there is a known engine bug (Dec 2025) where sink misbehaves — worth documenting |
| Modular / per-context cleanup | Developers expect they can tear down a context (and its actions/bindings) without affecting others. Memory leaks in input wrappers are a documented criticism (see BetterInput). | MEDIUM | Must clean up Instances and connections; Trove/Maid pattern is standard in this ecosystem |
| Full --!strict Luau types with exported types | Roblox tooling (Luau LSP, autocomplete) requires proper type annotations for a good DX. Typed wrappers are now the community standard. InputContextHandler does this; untyped packages feel unprofessional. | LOW | All public types must be exported; builder chain return types must be correct |
| Wally-installable package | Roblox developers using Rojo-based workflows expect Wally. A package distributed only via Model files is a second-class citizen for modern toolchains. | LOW | Standard `wally.toml` + `src/` layout |

### Differentiators (Competitive Advantage)

Features that set EZInput apart. Not universally present in existing wrappers.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Single fluent expression per action | Existing wrappers (InputContextHandler, UserInput Module) still require 3-5 separate statements to wire one action. EZInput's chain collapses context + action + binding + handler into one readable expression, dramatically reducing LOC at the call site. | MEDIUM | Must return correctly-typed builder objects at each chain step |
| Programmatic rebinding API (no UI) | IAS has no native rebinding — it's the #1 requested missing feature per DevForum discussion. Wrappers that expose `rebind(newKeyCode)` unlock keybind settings UIs without the package prescribing any UI. InputContextHandler has this; most others don't. | MEDIUM | Store binding reference; call `InputBinding.KeyCode = newKey`; surface as named method |
| Modifier key support (Shift+F, Ctrl+E combos) | IAS added `PrimaryModifier` and `SecondaryModifier` to `InputBinding` in February 2026. MasterInputManager supports multi-key combos via UserInputService hacks; EZInput can expose this cleanly through the native IAS property. First-mover advantage as IAS-based modifier support. | LOW | Set `InputBinding.PrimaryModifier` and `InputBinding.SecondaryModifier` in the builder |
| Touch binding via UIButton property | IAS supports binding a `UIButton` instance to an `InputBinding`, enabling touch-platform support without a separate touch detection layer. Almost no existing wrapper exposes this. Fills a real gap for mobile-first games. | MEDIUM | Builder needs a `bindButton(uiButton)` or equivalent path; UIButton must be parented correctly |
| Strict mapping to IAS primitives (not a reimplementation) | Some wrappers (MasterInputManager, BetterInput) reimplementing input on top of UserInputService/ContextActionService are immediately obsolete as IAS matures. EZInput wraps IAS Instances directly, so engine improvements (new action types, bug fixes) benefit users automatically. | LOW | This is an architectural choice, not a feature, but should be marketed explicitly |
| Named action introspection / registry | Allow devs to look up a context or action by name at runtime (e.g., for a keybind settings screen that lists all registered actions). InputContextHandler does not expose a registry. | MEDIUM | A module-level registry table; must handle namespacing if two contexts define same action names |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Built-in rebinding UI (settings screen) | Developers want rebinding out of the box to save implementation time | Any opinionated UI couples the package to a specific visual style, screen layout, and UI framework. Makes EZInput unusable for games with custom UI systems. Bloats a focused package. Roblox's UI API surface makes a good default UI impossible to agree on. | Expose the programmatic rebinding API and document a reference implementation. Let devs wire their own UI. |
| Direction2D / Direction1D / Direction3D action types in v1 | WASD movement and analog stick input are extremely common | Each directional type has a different state shape (number, Vector2, Vector3), different binding topology (Up/Down/Left/Right keys), and different consumer API. Adding them to v1 triples the API surface and delays launch. IAS's gamepad thumbstick handling also has active bugs (March 2026). | Defer to v1.x. Design the builder chain with extension points so directional types slot in cleanly later. |
| Server-side input handling | Some devs want to centralize input logic on the server | IAS is client-only by engine design. InputContext/InputAction/InputBinding only work in client RunContext scripts. Building a server-side layer requires RemoteEvents and is game-architecture-specific. Not an input-wrapper responsibility. | Document that IAS is client-only. Provide guidance on firing RemoteEvents from `onPressed` callbacks. |
| Built-in DataStore persistence for keybinds | Players expect their rebinds to persist across sessions | DataStore is server-side; keybinds live client-side. Bridging them requires RemoteEvents, DataStore boilerplate, and error handling that is completely outside input-wrapper scope. KeyCode Enums also cannot be stored directly in DataStore (must be serialized to strings). | Expose a `getBindings()` / `setBindings()` API that returns/accepts a serializable table. Let devs own persistence. |
| Input combination detection ("hold E then press F") | Requested for complex abilities / combos in action games | Sequence detection is stateful, timing-dependent, and highly game-specific. IAS has no native combo support. Building this correctly requires a state machine. Better served by a dedicated combo library. | Document that `onPressed` / `onReleased` callbacks can be composed to detect combos. Do not build into EZInput. |
| Automatic gamepad icon / prompt display | Devs want "Press [A] to interact" prompts updated automatically when device changes | Device-agnostic icon lookup (Xbox vs. PS vs. Switch) is a large, separate problem. Several dedicated Roblox packages already solve this (e.g., GuiService-based approaches). Bundling this bloats scope. | Expose `onDeviceChanged` or let consumers observe which binding was triggered. Recommend a dedicated icon package. |

---

## Feature Dependencies

```
[Context Builder]
    └──requires──> [InputContext Instance lifecycle]
                       └──requires──> [Cleanup / destroy mechanism]

[Action Builder]
    └──requires──> [Context Builder]
                       └──requires──> [InputContext Instance lifecycle]

[Binding Builder]
    └──requires──> [Action Builder]
                       └──requires──> [Context Builder]

[onPressed / onReleased / onStateChanged callbacks]
    └──requires──> [Action Builder] (action must exist before events fire)

[Modifier key support]
    └──requires──> [Binding Builder] (PrimaryModifier is a property of InputBinding)

[Touch binding (UIButton)]
    └──requires──> [Binding Builder] (UIButton is an alternative to KeyCode in InputBinding)

[Programmatic rebinding API]
    └──requires──> [Binding Builder] (must hold reference to InputBinding instance)
    └──enhances──> [Named action registry] (registry enables looking up binding by action name)

[Named action registry]
    └──enhances──> [Programmatic rebinding API] (devs look up action then rebind)

[Context sink]
    └──requires──> [Context priority] (sink only meaningful when multiple contexts exist with different priorities)

[Direction2D / 1D / 3D action types]  ──conflicts──>  [v1 Bool-only scope]
    (deferred; different state shapes require separate builder paths)

[Built-in rebinding UI]  ──conflicts──>  [package focus]
    (anti-feature; expose API instead)
```

### Dependency Notes

- **Action Builder requires Context Builder:** An `InputAction` must be parented to an `InputContext`. The builder chain enforces this structurally.
- **Binding Builder requires Action Builder:** An `InputBinding` must be parented to an `InputAction`. Same structural enforcement.
- **Callbacks require Action Builder:** `InputAction.Pressed` / `Released` / `StateChanged` events are only accessible after the action Instance exists.
- **Modifier key support requires Binding Builder:** `PrimaryModifier` and `SecondaryModifier` are properties on the `InputBinding` Instance, so the binding step must be completed first.
- **Context sink requires Context priority:** `InputContext.Sink` blocks lower-priority contexts. Setting sink without also setting priority is valid but only useful relative to other contexts' priorities.
- **Programmatic rebinding enhances named action registry:** Without a registry, devs must hold their own references to rebind. With a registry, any part of the codebase can look up and rebind by name.

---

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept and deliver meaningful value over raw IAS.

- [ ] **Builder chain: context → action → bind → onPressed/onReleased/onStateChanged** — Without the fluent API, EZInput has no reason to exist. This is the entire core value proposition.
- [ ] **Bool action type only** — Covers jump, attack, sprint, interact, reload — 90%+ of real game actions. Keeps v1 scope tight.
- [ ] **Keyboard / mouse KeyCode binding** — Required to be useful on PC, Roblox's largest segment.
- [ ] **Gamepad KeyCode binding (buttons, triggers)** — Required for cross-platform "write once, play everywhere" claim. Thumbstick axis covered by Direction2D (deferred), but button bindings (ButtonA, ButtonB, etc.) are Bool and in scope.
- [ ] **Modifier key support (PrimaryModifier / SecondaryModifier)** — IAS added this in February 2026; it's in the native API and low-complexity to expose. Immediate differentiator.
- [ ] **Context enable / disable, priority, sink** — These are the IAS context-management primitives. Without them the package is just boilerplate-reduction, not a real context manager.
- [ ] **Cleanup / destroy on context and action objects** — Memory leaks are the most criticized flaw in existing wrappers (BetterInput, others). Must be correct on launch.
- [ ] **Full --!strict Luau types with exported consumer types** — Non-negotiable for modern Roblox packages. Enables autocomplete and catches type errors at author time.
- [ ] **Wally package structure (wally.toml, src/ layout)** — Required to be installable by the target audience (Rojo-based workflows).

### Add After Validation (v1.x)

Features to add once core builder API is proven and adopted.

- [ ] **Touch binding via UIButton** — Mobile-first games need this. Not complex, but requires knowing the UIButton parenting model works correctly with IAS at runtime. Add once core is stable.
- [ ] **Programmatic rebinding API** — High value; #1 missing IAS feature. Defer slightly to validate the core builder API is correct before layering rebinding on top.
- [ ] **Named action registry** — Enables rebinding settings UIs. Depends on rebinding API being present. Add together with rebinding.
- [ ] **Direction1D action type** — Analog inputs (accelerator, zoom). Simpler than Direction2D. Natural v1.x extension once Bool chain is proven.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Direction2D action type (WASD, analog stick)** — High demand but complex: requires Up/Down/Left/Right binding slots, Vector2 state shape, and IAS gamepad thumbstick currently has active bugs (March 2026). Wait for engine stability.
- [ ] **Direction3D action type** — Niche use case (airborne vehicles). Defer until Direction2D is solid.
- [ ] **ViewportPosition action type (mouse cursor / raycasting)** — Specialized; most games use existing mouse APIs. Defer.
- [ ] **Combo / sequence detection** — Out of scope for an input wrapper. If demand exists, build as a separate package that consumes EZInput callbacks.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Fluent builder chain (context → action → bind → callback) | HIGH | MEDIUM | P1 |
| Bool action type | HIGH | LOW | P1 |
| Keyboard / mouse binding | HIGH | LOW | P1 |
| Gamepad button binding | HIGH | LOW | P1 |
| Context enable / disable / priority / sink | HIGH | LOW | P1 |
| Cleanup / destroy | HIGH | MEDIUM | P1 |
| --!strict Luau types | HIGH | LOW | P1 |
| Wally package structure | HIGH | LOW | P1 |
| Modifier key support | MEDIUM | LOW | P1 |
| Touch binding (UIButton) | MEDIUM | MEDIUM | P2 |
| Programmatic rebinding API | HIGH | MEDIUM | P2 |
| Named action registry | MEDIUM | MEDIUM | P2 |
| Direction1D action type | MEDIUM | MEDIUM | P2 |
| Direction2D action type | HIGH | HIGH | P3 |
| Direction3D action type | LOW | HIGH | P3 |
| ViewportPosition action type | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | InputContextHandler (GitHub) | UserInput Module (DevForum) | MasterInputManager (DevForum) | EZInput Approach |
|---------|------------------------------|-----------------------------|---------------------------------|-----------------|
| IAS-native (wraps Instances directly) | YES | NO (UserInputService) | NO (UserInputService + CAS) | YES — non-negotiable |
| Fluent builder chain | Partial (multi-statement setup) | NO | Partial (method chaining on manager) | YES — single expression per action |
| Bool action type | YES | YES (via events) | YES | YES |
| Gamepad support | YES | YES | YES | YES |
| Keyboard / mouse | YES | YES | YES | YES |
| Touch / UIButton binding | NO | NO | NO | YES (v1.x) |
| Modifier key support | NO | NO | YES (hack via UIS) | YES (native IAS properties) |
| Context priority / sink | YES (passthrough) | NO | YES (custom impl) | YES (native IAS) |
| Programmatic rebinding | YES | YES (ChangeKeys) | YES (Rebind) | YES (v1.x) |
| Named action registry | NO | NO | NO | YES (v1.x) |
| --!strict Luau types | YES | NO | NO | YES |
| Wally installable | NO | NO | NO | YES |
| Active maintenance (2025/2026) | UNKNOWN | YES | YES | YES (new) |
| Cleanup / destroy | YES (Trove) | YES (Destroy) | YES (Destroy) | YES |
| Direction2D / 1D / 3D | YES | NO | NO | DEFERRED (v2+) |

---

## Sources

- [Roblox IAS Announcement (Studio Beta)](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214) — MEDIUM confidence (DevForum official announcement)
- [Roblox IAS Client Beta Announcement](https://devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979) — HIGH confidence (official Roblox announcement, current API surface including February 2026 modifier key additions)
- [Roblox creator-docs IAS reference (GitHub)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/input/input-action-system.md) — HIGH confidence (official documentation source)
- [InputContextHandler (GitHub)](https://github.com/ivasmigins/InputContextHandler) — HIGH confidence (source code reviewed)
- [Input Module for the IAS (DevForum)](https://devforum.roblox.com/t/input-module-for-the-input-action-system-ias/3659350) — MEDIUM confidence (community resource, DevForum)
- [UserInput Module (DevForum)](https://devforum.roblox.com/t/introducing-userinput-module/3868398) — MEDIUM confidence (community resource)
- [MasterInputManager (DevForum)](https://devforum.roblox.com/t/masterinputmanager-advanced-keybind-system-with-priority-input-sinking-multi-key-support/3660444) — MEDIUM confidence (community resource)
- [BetterInput (DevForum)](https://devforum.roblox.com/t/betterinput-a-better-userinputservice/2270466) — MEDIUM confidence (community resource; analyzed for anti-patterns)
- [InputContext Sink bug report (DevForum, Dec 2025)](https://devforum.roblox.com/t/inputcontext-sink-property-doesnt-behave-properly/4110680) — HIGH confidence (active engine bug report)
- [IAS Gamepad thumbstick bug (DevForum, March 2026)](https://devforum.roblox.com/t/inputbinding-inputaction-broken-for-gamepad-thumbstick1-and-buttona/4451342) — HIGH confidence (active engine bug report confirming Direction2D deferral rationale)

---
*Feature research for: Roblox IAS input wrapper package (EZInput)*
*Researched: 2026-03-04*
