# Pitfalls Research

**Domain:** Roblox input wrapper package (IAS/InputContext/InputAction/InputBinding)
**Researched:** 2026-03-04
**Confidence:** HIGH — backed by official Roblox DevForum bug reports, engine changelogs, and official documentation

---

## Critical Pitfalls

### Pitfall 1: Exclusive-Binding Breaking Change (February 24, 2026)

**What goes wrong:**
As of February 24, 2026, Roblox changed InputBinding to support only one input source at a time. Before this date, a single InputBinding could hold both a KeyCode and a UIButton. After the change, the system silently prioritizes KeyCode and ignores additional sources. Any wrapper API that allows one binding object to hold multiple input sources (e.g., `bind(KeyCode.E, someButton)`) will silently drop the secondary source.

**Why it happens:**
Developers and library authors design multi-source bindings because it feels ergonomic: "bind keyboard E and a button to the same action." The IAS API used to permit this. The breaking change removed it without an error — it just stops working.

**How to avoid:**
Design EZInput so each `.bind()` call produces one and only one InputBinding instance. If a developer wants to bind both a KeyCode and a UIButton to the same action, they must call `.bind()` twice. Document this constraint explicitly. Do not attempt to pack multiple input sources into a single InputBinding wrapper object.

**Warning signs:**
- UIButton bindings silently stop working while KeyCode bindings on the same action still fire
- Inputs fire for one platform but not another despite appearing to be configured together

**Phase to address:**
Core binding implementation phase (when InputBinding creation is first built). Enforce one-source-per-binding at the API level from the start.

---

### Pitfall 2: IAS Instances Replicate to Server — Events Fire Globally

**What goes wrong:**
InputAction Pressed, Released, and StateChanged events replicate and fire on the server for all players, not just the player who pressed the key. Simultaneously, when the server window has focus in Studio, pressing any key activates all InputActions for all contexts, ignoring player ownership entirely. This makes it appear that IAS is broken or that input events are cross-contaminating between players.

**Why it happens:**
IAS instances are automatically replicated from client to server (especially when `Workspace.NextGenerationReplication` is enabled). The replication was designed to allow server-authoritative gameplay, but the event propagation was not correctly scoped at the time of research (Roblox acknowledged this was still being fixed as of February 2026).

**How to avoid:**
EZInput's onPressed/onReleased callbacks must be scoped to client-only. Do not document or support server-side event listeners on IAS events. EZInput scripts must run with `RunContext = Client`. Add a guard in the library that asserts `RunService:IsClient()` at initialization and errors fast if called from the server.

**Warning signs:**
- In Studio multi-client testing, pressing a key in one client fires callbacks in all clients
- `Pressed` callback fires unexpectedly when no physical input occurred
- Studio server window keypresses trigger actions

**Phase to address:**
Foundation/architecture phase. The `RunService:IsClient()` guard and client-only design constraint should be part of the initial module structure before any feature work.

---

### Pitfall 3: InputContext.Sink Behavior Broken by Hidden Threshold Properties

**What goes wrong:**
InputContext.Sink is supposed to block lower-priority contexts from receiving the same input. In practice, if an InputBinding's hidden `PressedThreshold` property is set to 0 (which happens when creating a binding for a digital key after previously configuring an analog key in the same binding), Pressed events fire for lower-priority sunk contexts anyway.

**Why it happens:**
Roblox's binding editor sets `PressedThreshold` and `ReleasedThreshold` based on the last-configured keycode type. Switching from analog to digital leaves these at 0, which causes the Pressed signal to fire regardless of Sink settings. This is a Roblox engine bug, acknowledged but not fully fixed.

**How to avoid:**
When EZInput creates an InputBinding for a digital KeyCode, explicitly set `PressedThreshold = 0.5` and `ReleasedThreshold = 0.2` on the binding instance to match the expected defaults for analog keycodes. This ensures Sink behaves correctly regardless of creation order. Test context priority and Sink in every platform combination during development.

**Warning signs:**
- Lower-priority contexts receive input events even when a higher-priority Sink context uses the same key
- Actions fire twice — once per context — when only the higher-priority action should fire

**Phase to address:**
Context management phase (when enable/disable, priority, and Sink are implemented). Include Sink behavior in the integration test checklist.

---

### Pitfall 4: StarterGui vs. PlayerGui — Wrong Instance Reference Breaks GetState

**What goes wrong:**
If InputContext instances are placed in or referenced from StarterGui, `:GetState()` on the InputAction silently fails. StarterGui is a template: Roblox clones it into each player's PlayerGui on spawn. The live InputAction instances are in PlayerGui, not StarterGui. Code that references `game.StarterGui.SomeFolder.InputContext` will not receive events and GetState will return stale or nil data.

**Why it happens:**
It is a common Roblox pattern to reference things in StarterGui for convenience. Developers don't always notice that the operational instance is in PlayerGui because the cloning is automatic and silent.

**How to avoid:**
EZInput must create all InputContext, InputAction, and InputBinding instances at runtime in the player's PlayerGui (accessed via `game.Players.LocalPlayer.PlayerGui`) or in another purely client-side container. Never reference StarterGui in the library internals. Document that if consumers want to place a container in StarterGui for organization, EZInput must still reference the PlayerGui clone at runtime.

**Warning signs:**
- Events never fire despite bindings appearing configured correctly
- `:GetState()` returns false/nil when a key is visibly held
- Works in Studio Play Solo but not in multi-player or published game

**Phase to address:**
Foundation/architecture phase, when deciding where to parent created instances. Lock down the parent path before any feature work builds on top of it.

---

### Pitfall 5: Context Toggle Race Condition — First Input After Re-Enable Drops

**What goes wrong:**
When an InputContext is toggled from Enabled=false back to Enabled=true, the first input after re-enabling frequently fails to fire the Pressed event. Subsequent inputs work correctly. The behavior is intermittent, making it appear as if input is "slow" or "laggy" on context activation.

**Why it happens:**
This was a confirmed Roblox engine bug: "disabling actions not properly resetting the action state." Roblox released a fix, but the behavior may resurface in edge cases or if the library rapidly toggles contexts.

**How to avoid:**
Do not toggle contexts at extremely high frequency (e.g., inside a per-frame loop). After calling `.enable()` or `.disable()` on an EZInput context, add at least one Heartbeat yield before treating the context as fully active. Document this limitation prominently. In the future, if the bug resurfaces, provide a workaround that checks `:GetState()` on the first frame after enabling.

**Warning signs:**
- First press after context activation appears to be eaten
- Reproducible by rapidly disabling then enabling a context and immediately pressing the bound key
- Flaky behavior that is hard to reproduce consistently

**Phase to address:**
Context management phase (enable/disable implementation). Add a note in the implementation and in docs.

---

### Pitfall 6: Nested InputContext Instances Have No Effect

**What goes wrong:**
If an InputContext is parented inside another InputContext, it is silently ignored. The nested context will not receive or process any input. Developers who try to model a hierarchy of contexts (e.g., "Combat > Melee") by nesting instances will end up with only the top-level context functional.

**Why it happens:**
The IAS documentation states "Nested InputContext instances will have no effect." Priority and context ordering are managed through the Enabled, Priority, and Sink properties — not through instance parentage. This is unintuitive for developers accustomed to hierarchical game object trees.

**How to avoid:**
EZInput must enforce a flat structure where all contexts are siblings. The internal store should be a flat table of contexts keyed by name. Never parent one EZInput-created InputContext inside another. If consumers request "sub-contexts," implement the concept through Priority values and Sink flags, not Instance nesting.

**Warning signs:**
- A context that is programmatically configured but never fires any events
- No Luau error — it simply does nothing

**Phase to address:**
Foundation/architecture phase. Design the internal context registry as a flat structure from the beginning.

---

### Pitfall 7: Gamepad Thumbstick1 and ButtonA Broken by Default Character Scripts

**What goes wrong:**
Thumbstick1, GamepadA (ButtonA), ButtonR2, and Shift are sunk by Roblox's default character control scripts. An EZInput binding for any of these inputs may silently fail — no events fire, no errors thrown. This affects the most common gamepad actions (jump = ButtonA, move = Thumbstick1).

**Why it happens:**
The default Roblox PlayerScripts (which handle character movement) register high-priority IAS contexts internally. Until Roblox migrates the PlayerScripts fully to IAS, these inputs are consumed at the platform level. Roblox acknowledged this and noted that full resolution requires new PlayerScripts, which are pending.

**How to avoid:**
Document these four inputs as restricted/unreliable in v1: Thumbstick1, ButtonA (GamepadA), ButtonR2, Shift. Provide clear warnings in EZInput docs and optionally in Luau type annotations if those keycodes are passed. Suggest developers test any gamepad binding for these keys with a dedicated test place. Do not block the API from accepting these bindings — just document them.

**Warning signs:**
- Gamepad bindings work for ButtonB and Thumbstick2 but not for ButtonA and Thumbstick1
- No errors thrown — events simply never fire

**Phase to address:**
Gamepad binding phase. Add to the known-limitations section of the README when gamepad support is built.

---

### Pitfall 8: IAS Still in Beta — API Surface May Change

**What goes wrong:**
The IAS entered Client Beta in August 2025. The February 24, 2026 update introduced a breaking change (exclusive bindings). More changes are possible before full release. A wrapper library that tightly couples to current IAS Instance property names will break when Roblox renames or removes properties.

**Why it happens:**
Beta APIs are inherently unstable. Roblox has already changed IAS behavior at least once (exclusive bindings) with minimal migration path. The community has raised concerns about incomplete features (no mouse movement/scroll wheel support, no equivalent to `gameProcessedEvent`).

**How to avoid:**
Isolate all direct IAS Instance creation and property access inside dedicated adapter modules (e.g., `ContextAdapter.luau`, `ActionAdapter.luau`, `BindingAdapter.luau`). The public EZInput API should never directly depend on IAS property names. When Roblox changes a property name, only the adapter module needs updating — not the entire library or consumer code. Pin the IAS API surface that EZInput depends on in a single constants/types file.

**Warning signs:**
- Roblox DevForum IAS announcements thread has a new update
- Engine update changes `wally.lock` or causes unexplained runtime errors
- IAS-specific properties start throwing "unknown property" errors in strict mode

**Phase to address:**
Foundation/architecture phase. The adapter pattern must be established before any IAS Instance creation code is written.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Directly assigning IAS Instance properties throughout the library | Faster initial build | Every IAS beta change requires grep-and-replace across the whole codebase | Never — use adapter modules |
| Skipping `RunService:IsClient()` guard | One less boilerplate check | Server-side calls produce confusing nil errors instead of clear messages | Never — add it at library init |
| Single InputBinding holds multiple input sources | API feels simpler | Silently broken since Feb 24 2026 exclusive-binding change | Never — one source per binding |
| Using `StarterGui` as the parent container for IAS instances | Familiar pattern | `GetState()` and events silently fail; works in Solo but breaks in multiplayer | Never — always use PlayerGui at runtime |
| Not tracking connections in a cleanup table | Less upfront code | Memory leaks accumulate when contexts or actions are destroyed | Never — track from day one |
| Exposing raw IAS Instance references to consumers | Simpler API surface to document | Consumers form dependencies on IAS internals; library can't change adapter internals | Only for power-user escape hatch; document clearly |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Roblox default PlayerScripts | Binding Thumbstick1/ButtonA and expecting events to fire | Document as restricted; advise players to test; cannot fix at library level |
| UIButton touch binding | Placing the UIButton in StarterGui and passing a StarterGui reference | Require consumer to pass the PlayerGui-side UIButton reference, or resolve it automatically at runtime |
| Workspace.NextGenerationReplication | Leaving it enabled and expecting client-only events | Guard with `RunService:IsClient()`; document that events must only be consumed client-side |
| Wally package consumers using `require(script.Parent.Packages.EZInput)` | Path assumptions break if consumer's Packages folder is in a non-standard location | Export all public types; ensure the package entry point is a single well-named `init.luau` |
| Multi-binding for keyboard + gamepad on same action | Calling `.bind(KeyCode.E, GamepadButtonEnum.ButtonX)` expecting one binding | Enforce two separate `.bind()` calls; error or warn if multiple sources are passed to one call |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Polling `GetState()` every frame instead of using events | Hitching, frame drops in CPU-bound games | Use Pressed/Released events; only use GetState for one-shot state checks | At 10+ active contexts polled per frame |
| Creating new InputBinding instances on every rebind instead of updating properties | Memory growth during play session if rebinding is frequent | Update existing InputBinding instance properties in-place; destroy old binding before creating new one | After 50+ rebind operations |
| Connecting multiple redundant listeners to the same action (e.g., re-connecting on re-enable without disconnecting) | Callbacks fire multiple times per input | Track all connections in a cleanup registry; disconnect before reconnecting | After 3+ context toggles without cleanup |
| Storing large closure upvalues in Pressed callbacks | Memory retained even after action is destroyed | Keep callback closures small; do not capture large tables | Hard to notice — degrades gradually |

---

## Security Mistakes

This domain (client-side input wrapper) has limited traditional security surface, but there are Roblox-specific concerns:

| Mistake | Risk | Prevention |
|---------|------|------------|
| Trusting IAS events on the server for game-critical logic | Exploiters can fire RemoteEvents to mimic server-replicated IAS events | Never use IAS events as server-side authority; always validate game state server-side via RemoteEvents with proper sanity checks |
| Exposing raw InputAction references to server scripts | Server can observe client input state, creating cheating detection risks or false positives | Keep IAS entirely client-side; server never directly references IAS instances |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Chat opens while holding movement key — Released event sunk | Character continues moving in last direction after chat opens | Document this as a known Roblox limitation; advise consumers to hook CharacterAdded and reset action state on chat focus |
| No `gameProcessedEvent` equivalent in IAS | Cannot distinguish "player is typing in chat" from "player is pressing E to interact" | Combine IAS bindings with `UserInputService:GetFocusedTextBox()` check inside the onPressed callback; document this pattern |
| Rebinding an action while it is pressed | Input can get "stuck" — Pressed fired, old binding removed, Released never fires | Always release/reset action state before changing bindings; document this in the rebinding API |

---

## "Looks Done But Isn't" Checklist

- [ ] **Gamepad support:** Appears configured but silently broken — verify ButtonA and Thumbstick1 actually fire events in a published experience with default PlayerScripts active
- [ ] **Sink behavior:** Appears to block lower-priority contexts — verify with PressedThreshold explicitly set; do not rely on editor defaults
- [ ] **Context re-enable:** Appears to work — verify first input after toggle actually fires (not just second and subsequent)
- [ ] **Multi-client:** Works in Solo Play — verify in actual multi-player test that events do not cross-contaminate between players
- [ ] **Cleanup:** Destroy() appears to clean up — verify connections are disconnected and IAS instances are actually garbage collected (check Developer Console memory tab)
- [ ] **Touch binding:** UIButton binding appears configured — verify the reference is PlayerGui-side, not StarterGui-side
- [ ] **Strict Luau types:** `luau-lsp` reports no errors — verify exported types work correctly when consumers use `--!strict` in their own scripts

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Multi-source binding (pre-Feb 2026 code) | MEDIUM | Audit all `.bind()` calls; split any that passed multiple sources into two calls; regression-test all platforms |
| StarterGui reference instead of PlayerGui | LOW | Find all `StarterGui` references in library code; replace with `LocalPlayer.PlayerGui` lookup; test GetState and events |
| Memory leak from untracked connections | HIGH | Add cleanup registry to all connection-creating paths; call `:Disconnect()` on Destroy; profile with memory dump before/after context lifecycle |
| Nested InputContext (silently ignored) | LOW | Flatten the context registry; re-parent instances to a single flat container; no API change needed for consumers |
| IAS breaking change after Roblox update | MEDIUM (with adapters) / HIGH (without) | If adapters were used: update adapter module only. If not: grep all IAS property names and update; re-test full feature matrix |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Exclusive-binding (one source per InputBinding) | Core binding implementation | Test KeyCode + UIButton as two separate bindings; confirm both fire |
| IAS events fire on server / replication | Foundation — client guard | `assert(RunService:IsClient())` at module init; test in server context, expect error |
| Sink broken by hidden thresholds | Context management (Sink/Priority) | Write a two-context test: high-priority Sink=true; verify low-priority never fires |
| StarterGui vs. PlayerGui parent | Foundation — instance creation | All IAS Instance creation paths reference PlayerGui; grep for any StarterGui usage |
| Context toggle race condition | Context management (enable/disable) | Rapid toggle test: disable/enable/immediately press; verify first event fires |
| Nested InputContext ignored | Foundation — context registry design | Enforce flat structure; assert parent is never an InputContext |
| Gamepad Thumbstick1 / ButtonA sunk | Gamepad binding phase | Document in README; add warning comment in source; test in published experience |
| IAS beta API changes | Foundation — adapter pattern | All IAS property access in adapter modules; zero direct property access in feature modules |
| Memory leaks from connections | Foundation + all feature phases | Destroy context after use; verify in memory profiler that connections are cleaned up |
| ChatTextBox interfering with Released | Documentation phase | Known limitation note in docs; provide `GetFocusedTextBox()` pattern example |

---

## Sources

- [InputBinding/InputAction broken for gamepad Thumbstick1 and ButtonA](https://devforum.roblox.com/t/inputbinding-inputaction-broken-for-gamepad-thumbstick1-and-buttona/4451342) — MEDIUM confidence (bug report, partially platform-version dependent)
- [InputContext Sink property doesn't behave properly](https://devforum.roblox.com/t/inputcontext-sink-property-doesnt-behave-properly/4110680) — HIGH confidence (Roblox staff acknowledged, root cause identified)
- [Input action not firing reliably when context toggled](https://devforum.roblox.com/t/input-action-not-being-fire-reliably-when-input-context-being-toggled-on-and-off/4015442) — HIGH confidence (Roblox confirmed fix released)
- [InputAction weird behavior — events fire on server](https://devforum.roblox.com/t/input-action-have-weird-behavior/4433713) — HIGH confidence (multiple reporters, Roblox acknowledged)
- [IAS actions fire from server point of view](https://devforum.roblox.com/t/ias-actions-fire-when-pressing-keys-from-the-servers-point-of-view/4164638) — HIGH confidence (Roblox staff acknowledged as of Feb 2026)
- [How to prevent IAS replication](https://devforum.roblox.com/t/how-to-prevent-ias-replication/4155560) — MEDIUM confidence (community workaround, not official fix)
- [Client Beta IAS — page 10 (Feb 24 2026 exclusive binding change)](https://devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979?page=10) — HIGH confidence (official Roblox announcement)
- [Studio Beta IAS — page 8 (parenting, boilerplate, design tensions)](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214?page=8) — HIGH confidence (official thread with staff responses)
- [PSA: Connections can memory leak Instances](https://devforum.roblox.com/t/psa-connections-can-memory-leak-instances/90082) — HIGH confidence (well-established Roblox fundamentals)
- [Input Action System Help — StarterGui vs PlayerGui](https://devforum.roblox.com/t/input-action-system-help/3667194) — HIGH confidence (common mistake confirmed by community)
- [InputContext API Reference](https://create.roblox.com/docs/reference/engine/classes/InputContext) — HIGH confidence (official docs)

---
*Pitfalls research for: EZInput — Roblox IAS wrapper package*
*Researched: 2026-03-04*
