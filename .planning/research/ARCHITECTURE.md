# Architecture Research

**Domain:** Roblox Luau input wrapper Wally package (IAS builder API)
**Researched:** 2026-03-04
**Confidence:** MEDIUM — IAS is in Client Beta; API surface confirmed via official Roblox API reference and DevForum. Luau OOP patterns confirmed via community resources and Roblox style guide.

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Consumer API (Public Surface)                  │
│                                                                   │
│   EZInput.context("Combat")                                       │
│       :priority(10)                                               │
│       :sink(true)                                                 │
│       :action("Attack")                                           │
│           :bind(KeyCode.F)                                        │
│           :onPressed(fn)                                          │
│       :enable()                                                   │
└─────────────────────────┬───────────────────────────────────────┘
                          │ returns builder objects
┌─────────────────────────▼───────────────────────────────────────┐
│                    Builder Layer (3 classes)                      │
│                                                                   │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │ ContextBuilder  │  │  ActionBuilder   │  │ BindingBuilder │  │
│  │                 │  │                  │  │                │  │
│  │ .priority()     │  │ .bind()          │  │ .modifier()    │  │
│  │ .sink()         │  │ .onPressed()     │  │ .threshold()   │  │
│  │ .enable()       │  │ .onReleased()    │  │ .curve()       │  │
│  │ .disable()      │  │ .onChange()      │  │                │  │
│  │ .action()──────►│  │ .context()◄─────│  │                │  │
│  │ .rebind()       │  │ .rebind()        │  │                │  │
│  │ .destroy()      │  │ .destroy()       │  │ .apply()       │  │
│  └────────┬────────┘  └────────┬─────────┘  └───────┬────────┘  │
└───────────┼────────────────────┼────────────────────┼───────────┘
            │ wraps              │ wraps               │ wraps
┌───────────▼────────────────────▼────────────────────▼───────────┐
│                 Roblox IAS Instance Layer                         │
│                                                                   │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  InputContext   │  │   InputAction    │  │  InputBinding  │  │
│  │                 │  │                  │  │                │  │
│  │ .Enabled        │  │ .Enabled         │  │ .KeyCode       │  │
│  │ .Priority       │  │ .Type (Bool)     │  │ .UIButton      │  │
│  │ .Sink           │  │                  │  │ .PrimaryMod    │  │
│  │                 │  │ [events]         │  │ .SecondaryMod  │  │
│  │ :GetInputActions│  │ .Pressed         │  │ .PressedThresh │  │
│  │                 │  │ .Released        │  │ .ReleasedThresh│  │
│  │                 │  │ .StateChanged    │  │ .ResponseCurve │  │
│  └─────────────────┘  └──────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          │ lifecycle cleanup
┌─────────────────────────▼───────────────────────────────────────┐
│                    Support Layer                                  │
│                                                                   │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐  │
│  │      Types module        │  │       Trove (optional)       │  │
│  │                          │  │                              │  │
│  │ ContextBuilder type      │  │ Cleans up signal connections │  │
│  │ ActionBuilder type       │  │ and Instances on :destroy()  │  │
│  │ BindingBuilder type      │  │                              │  │
│  │ ContextConfig type       │  │                              │  │
│  │ ActionConfig type        │  │                              │  │
│  │ BindingConfig type       │  │                              │  │
│  └──────────────────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Key Boundary |
|-----------|----------------|--------------|
| `EZInput` (init.luau) | Public entry point; factory function `EZInput.context()` | Only export — consumers never touch builder internals directly |
| `ContextBuilder` | Wraps one `InputContext` instance; manages enable/disable, priority, sink; owns child ActionBuilders; exposes `.action()` to chain downward | Does NOT touch InputBinding; delegates to ActionBuilder |
| `ActionBuilder` | Wraps one `InputAction` instance; manages Pressed/Released/StateChanged signal connections; exposes `.bind()` to chain downward | Does NOT create InputContext; holds back-reference to parent ContextBuilder |
| `BindingBuilder` | Wraps one `InputBinding` instance; configures KeyCode, UIButton, modifiers, thresholds, response curves | Does NOT connect events; only sets properties and parents the instance |
| `Types` | Exported `--!strict` type definitions for all three builders; enables external consumer type safety | Pure type module — no logic |
| `Trove` (dependency) | Tracks Instances and signal connections for deferred bulk cleanup | Used internally by each builder; not exposed to consumers |

## Recommended Project Structure

```
EZInput/
├── wally.toml                  # Package manifest (name, version, realm, dependencies)
├── wally.lock                  # Lockfile (committed)
├── default.project.json        # Rojo project file (maps src → ReplicatedStorage.EZInput)
├── src/
│   ├── init.luau               # Public entry point — exports EZInput table + types
│   ├── Types.luau              # Exported --!strict type definitions
│   ├── ContextBuilder.luau     # InputContext wrapper + builder methods
│   ├── ActionBuilder.luau      # InputAction wrapper + builder methods
│   └── BindingBuilder.luau     # InputBinding wrapper + builder methods
├── Packages/                   # Wally-installed dependencies (gitignored in lockfile)
│   └── _Index/
│       └── sleitnick_trove.../
└── pesde.toml / aftman.toml    # Toolchain version locks (Rojo, Wally, etc.)
```

### Structure Rationale

- **`src/init.luau`:** Single require point for consumers (`local EZInput = require(path.to.EZInput)`). Re-exports the public API and all types. Wally resolves `require(pkg)` to `pkg/init.luau`.
- **`src/Types.luau`:** Separating types prevents circular requires when ContextBuilder needs to reference ActionBuilder's type and vice versa.
- **One file per builder:** Each IAS instance type maps to exactly one builder class. Keeps files focused and searchable.
- **`Packages/` excluded from src:** Wally installs dependencies outside `src/`; the Rojo project.json maps them into the datamodel alongside EZInput.

## Architectural Patterns

### Pattern 1: Builder with Back-reference (Parent Pointer)

**What:** Each child builder holds a reference to its parent builder so that terminal chain calls (e.g., `.action()` called again after `.bind()`) can traverse back up the tree.

**When to use:** Any time chaining needs to cross builder boundaries — e.g., defining a second action after fully configuring the first.

**Trade-offs:** Slight added state per object. Necessary for ergonomic chaining (`context:action("A"):bind(K.E):action("B"):bind(K.F)`). Without it, consumers must store intermediate references.

**Example:**
```luau
--!strict
-- ActionBuilder holds reference to its parent ContextBuilder
-- so that chaining back up works:
--
-- ctx:action("Jump"):bind(K.Space):action("Sprint"):bind(K.LeftShift)
--                            ^ here, .action() is called on ContextBuilder

function ActionBuilder.action(self: ActionBuilder, name: string): ActionBuilder
    return self._context:action(name) -- delegate back to parent
end
```

### Pattern 2: Lazy Instance Creation (Deferred Parenting)

**What:** `BindingBuilder` creates and configures the `InputBinding` instance but does NOT parent it to the `InputAction` until `.apply()` (or the next chain call) is invoked. `ContextBuilder` similarly defers parenting `InputContext` to `LocalScript.Parent` until `.enable()` is called.

**When to use:** Lets consumers configure all properties before the instance becomes active in the IAS engine, avoiding partial-state input registration.

**Trade-offs:** Slightly more complex internal state (a "pending" flag). Prevents the IAS from firing events on a half-configured binding.

**Example:**
```luau
-- BindingBuilder collects properties, parents on seal:
function BindingBuilder._seal(self: BindingBuilder)
    self._instance.Parent = self._action._instance
end
```

### Pattern 3: Trove-per-Builder for Cleanup

**What:** Each builder owns a `Trove` instance. Signal connections are added to the trove at connection time. Calling `:destroy()` on a builder cleans its trove (disconnects signals, destroys Instances).

**When to use:** Required whenever a module creates Roblox Instances or connects to signals — both leak if not explicitly cleaned up.

**Trade-offs:** Dependency on Trove (Sleitnick/RbxUtil). Adds a Wally dependency. Alternative is manual `table` of connections, but Trove is battle-tested and already used by the reference implementations in this domain.

**Example:**
```luau
-- ActionBuilder connects events through its trove:
self._trove:Connect(self._instance.Pressed, function()
    self._onPressedCallback()
end)

-- On destroy, everything cleans up:
function ActionBuilder.destroy(self: ActionBuilder)
    self._trove:Destroy()  -- disconnects signals, destroys InputAction
end
```

### Pattern 4: Strict-Typed Class with Exported Interface Types

**What:** Each builder is a `--!strict` Luau class using the metatype pattern. The `Types.luau` module exports the public-facing interface types so consumers can annotate their own variables. Constructors are internal (no `new()` exposed on the public API — only `EZInput.context()` is the entry point).

**When to use:** Always, for a public Wally package. Without exported types, consumers get `any` everywhere and lose autocomplete.

**Example:**
```luau
-- Types.luau
export type ContextBuilder = {
    priority: (self: ContextBuilder, value: number) -> ContextBuilder,
    sink: (self: ContextBuilder, value: boolean) -> ContextBuilder,
    action: (self: ContextBuilder, name: string) -> ActionBuilder,
    enable: (self: ContextBuilder) -> ContextBuilder,
    disable: (self: ContextBuilder) -> ContextBuilder,
    destroy: (self: ContextBuilder) -> (),
}

-- Consumer usage:
local EZInput = require(path)
local ctx: EZInput.ContextBuilder = EZInput.context("Combat")
```

## Data Flow

### Build-Time Flow (configuration)

```
EZInput.context("Combat")
    │
    ▼
ContextBuilder.new("Combat")
    creates InputContext Instance (Priority=1000, Sink=false, Enabled=false)
    stores in self._instance
    │
    ▼ :action("Attack")
ActionBuilder.new("Attack", contextBuilder)
    creates InputAction Instance (Type=Bool, Enabled=true)
    parents to self._context._instance
    │
    ▼ :bind(KeyCode.F)
BindingBuilder.new(contextBuilder, actionBuilder)
    creates InputBinding Instance
    sets .KeyCode = KeyCode.F
    parents to self._action._instance  ← IAS binding is now live
    returns actionBuilder (for chaining)
    │
    ▼ :onPressed(fn)
ActionBuilder stores fn in self._onPressedCallback
    connects self._trove:Connect(self._instance.Pressed, fn)
    │
    ▼ :enable()   (called on ContextBuilder)
ContextBuilder sets self._instance.Enabled = true
    IAS engine begins routing hardware input → InputContext → InputAction → InputBinding → Pressed event → fn
```

### Runtime Event Flow (input received)

```
Hardware Key Press (e.g., F key)
    │
    ▼
Roblox IAS Engine
    Checks active InputContexts by Priority (highest first)
    Checks Sink: if true, stops propagation to lower-priority contexts
    │
    ▼
InputContext.Enabled == true → InputAction lookup
    │
    ▼
InputBinding.KeyCode matches → InputAction.Pressed fires
    │
    ▼
ActionBuilder signal connection (via Trove)
    │
    ▼
Consumer callback fn()
```

### Rebinding Flow (runtime rebind)

```
contextBuilder:rebind("Attack", KeyCode.G)
    │
    ▼
ContextBuilder looks up ActionBuilder by name ("Attack")
    │
    ▼
ActionBuilder.rebind(KeyCode.G)
    destroys existing BindingBuilder (trove cleanup)
    creates new BindingBuilder with KeyCode.G
    re-parents to InputAction
    re-connects no new signal (Pressed event is on InputAction, unchanged)
```

### Key Data Flows

1. **Configuration flows downward:** Consumer calls chain `context → action → binding`, each level creating and owning the next IAS Instance.
2. **Events fire upward:** Roblox IAS fires on `InputAction.Pressed`; the ActionBuilder's trove connection dispatches to consumer callbacks.
3. **Rebinding is lateral:** ContextBuilder navigates its action registry to locate the ActionBuilder, which then replaces only the BindingBuilder beneath it.
4. **Cleanup is top-down:** `context:destroy()` cascades — ContextBuilder trove destroys InputContext, which removes child InputAction and InputBinding instances from the tree.

## Scaling Considerations

This is a single-client Luau library, not a server/network system. "Scale" here means number of contexts × actions × bindings and developer ergonomics at larger game codebases.

| Scale | Considerations |
|-------|----------------|
| 1-5 contexts, 5-20 actions | Default architecture is fine. No registration overhead. |
| 10+ contexts, 50+ actions | Consider a context registry (`EZInput.getContext(name)`) to retrieve previously created contexts without holding references. |
| Multiple scripts needing same context | Shared module pattern: define contexts in one ModuleScript, require it from multiple LocalScripts. The EZInput API itself stays unchanged. |

### Scaling Priorities

1. **First concern:** Memory leaks from unreleased signal connections. Trove pattern eliminates this.
2. **Second concern:** Context name collisions across scripts. A registry pattern (`EZInput.getContext(name) → ContextBuilder?`) mitigates, but is a v2 concern.

## Anti-Patterns

### Anti-Pattern 1: Parenting InputContext to a Script

**What people do:** `inputContext.Parent = script` — attaches the InputContext to the LocalScript itself.

**Why it's wrong:** When the script is destroyed or reloaded, the InputContext and all children are destroyed with no cleanup callback. Also, Roblox IAS docs indicate InputContext should live under `StarterPlayerScripts`, `StarterGui`, or `ReplicatedStorage` to work correctly.

**Do this instead:** The ContextBuilder should parent `InputContext` to `script.Parent` (the container script placed by the game) or a dedicated folder in `StarterPlayerScripts`. Document this placement requirement clearly.

### Anti-Pattern 2: Connecting Events Before Parenting Bindings

**What people do:** Connect to `InputAction.Pressed` immediately after creating the InputAction, before any InputBindings are parented.

**Why it's wrong:** The IAS engine may not register the action until a binding exists. Partial-state configurations can result in silent failures where the event never fires.

**Do this instead:** Use the lazy sealing pattern (Pattern 2) — finalize binding configuration and parent the InputBinding before enabling the context.

### Anti-Pattern 3: Storing Builders as Global State

**What people do:** Put ContextBuilder instances in `_G` or a shared module-level table to access them across scripts.

**Why it's wrong:** Multiple LocalScripts accessing the same builder can create race conditions on enable/disable. The IAS is client-only and each client has its own memory space, but within a single client, shared mutable state across scripts is fragile.

**Do this instead:** Define contexts in a single dedicated ModuleScript (e.g., `InputContexts.luau`) and `require()` that module wherever context switching is needed.

### Anti-Pattern 4: Rebuilding Contexts on Every State Change

**What people do:** Call `context:destroy()` and recreate the entire context when switching game states (e.g., combat → menu).

**Why it's wrong:** Unnecessary Instance churn. The IAS has built-in `Enabled` toggling at the `InputContext` level specifically to avoid this.

**Do this instead:** Use `context:enable()` / `context:disable()` to switch contexts. Only call `:destroy()` when the context should never be used again (e.g., script cleanup on character removal).

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Roblox IAS (`InputContext`, `InputAction`, `InputBinding`) | `Instance.new()` + property assignment + event connections | Client-only (`RunContext = Client`). Beta API — wrap in pcall or guard with version checks if API changes. |
| `Trove` (Sleitnick/RbxUtil via Wally) | Wally dependency, require inside each builder | Handles Instance destruction and RBXScriptConnection cleanup. Verified community standard. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `init.luau` ↔ `ContextBuilder` | Direct require + `ContextBuilder.new()` | init.luau is the only file that creates ContextBuilders |
| `ContextBuilder` ↔ `ActionBuilder` | Direct require + `ActionBuilder.new(self, name)` | ContextBuilder passes itself as parent reference |
| `ActionBuilder` ↔ `BindingBuilder` | Direct require + `BindingBuilder.new(self, ...)` | ActionBuilder passes itself as parent reference |
| All builders ↔ `Types` | Require for type annotations only | Types module has no runtime logic; safe for any file to require |
| All builders ↔ `Trove` | Require + `Trove.new()` per builder instance | Each builder owns its own Trove; no shared Trove state |

## Suggested Build Order

Dependencies between components determine the order phases should implement them:

1. **Types module first** — No dependencies. Defines the shapes that all other modules reference. Blocking for strict typing everywhere else.
2. **BindingBuilder second** — Depends only on Types. Wraps InputBinding properties (KeyCode, UIButton, modifiers, thresholds). No IAS event connections at this level.
3. **ActionBuilder third** — Depends on BindingBuilder and Types. Wraps InputAction. Connects Pressed/Released/StateChanged events via Trove. Creates BindingBuilders via `:bind()`.
4. **ContextBuilder fourth** — Depends on ActionBuilder and Types. Wraps InputContext. Manages enable/disable/priority/sink. Creates ActionBuilders via `:action()`. Owns the rebinding registry.
5. **init.luau (EZInput entry point) fifth** — Depends on ContextBuilder and Types. Thin factory that calls `ContextBuilder.new()` and re-exports types.

This order means each phase has no forward dependencies — each module can be implemented and manually tested in isolation before the layer above it is built.

## Sources

- [Roblox InputContext API Reference — robloxapi.github.io](https://robloxapi.github.io/ref/class/InputContext.html) — MEDIUM confidence (unofficial mirror, matches official create.roblox.com)
- [Roblox InputBinding Documentation — create.roblox.com](https://create.roblox.com/docs/reference/engine/classes/InputBinding) — HIGH confidence (official)
- [IAS Client Beta Announcement — DevForum](https://devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979) — HIGH confidence (official Roblox announcement)
- [IAS Studio Beta Thread — DevForum](https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214) — HIGH confidence (official Roblox announcement)
- [InputContextHandler reference implementation — GitHub](https://github.com/ivasmigins/InputContextHandler) — MEDIUM confidence (community, validates builder-per-IAS-type pattern)
- [InputSystem (instance-free IAS wrapper) — DevForum](https://devforum.roblox.com/t/inputsystem-robloxs-new-input-action-system-without-instances/3768911) — MEDIUM confidence (community, validates programmatic approach)
- [Trove lifecycle management — Sleitnick/RbxUtil](https://sleitnick.github.io/RbxUtil/api/Trove/) — HIGH confidence (widely-used, actively maintained)
- [Roblox Lua Style Guide — roblox.github.io](https://roblox.github.io/lua-style-guide/) — HIGH confidence (official)
- [Method chaining in Luau — DevForum](https://devforum.roblox.com/t/method-chaining-in-lua-oop/1786788) — MEDIUM confidence (community tutorial, widely validated pattern)

---
*Architecture research for: Roblox Luau input wrapper Wally package (EZInput)*
*Researched: 2026-03-04*
