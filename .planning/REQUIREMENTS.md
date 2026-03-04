# Requirements: EZInput

**Defined:** 2026-03-04
**Core Value:** Developers can define input contexts, actions, and bindings in a readable chainable API without manually creating Instance trees

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Core Builder API

- [ ] **BLDR-01**: Developer can create input context via `EZInput.context("name")` fluent call
- [ ] **BLDR-02**: Developer can chain action creation via `:action("name")` on a context
- [ ] **BLDR-03**: Developer can chain binding via `:bind(KeyCode)` on an action
- [ ] **BLDR-04**: Developer can attach callbacks via `:onPressed(fn)`, `:onReleased(fn)`, `:onStateChanged(fn)`
- [ ] **BLDR-05**: Bool action type fires Pressed/Released/StateChanged events correctly
- [ ] **BLDR-06**: Developer can destroy a context and all its children/connections are cleaned up

### Input Devices

- [ ] **INPT-01**: Developer can bind keyboard keys via `Enum.KeyCode`
- [ ] **INPT-02**: Developer can bind mouse buttons via `Enum.KeyCode`
- [ ] **INPT-03**: Developer can bind gamepad buttons and triggers via `Enum.KeyCode`
- [ ] **INPT-04**: Developer can specify modifier keys (Shift, Ctrl, Alt) on bindings
- [ ] **INPT-05**: Developer can bind a UIButton instance for touch input

### Context Management

- [ ] **CTXT-01**: Developer can enable/disable a context at runtime
- [ ] **CTXT-02**: Developer can set context priority (higher = fires first)
- [ ] **CTXT-03**: Developer can enable sink to block lower-priority contexts

### Developer Experience

- [ ] **DEVX-01**: All public APIs have `--!strict` Luau type annotations
- [ ] **DEVX-02**: Package exports consumer-facing types for autocomplete
- [x] **DEVX-03**: Package is installable via Wally with standard `wally.toml`
- [ ] **DEVX-04**: Developer can rebind an action to a different KeyCode at runtime
- [ ] **DEVX-05**: Developer can look up actions/contexts by name via a registry

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Directional Input

- **DIR-01**: Developer can create Direction1D actions (single-axis float)
- **DIR-02**: Developer can create Direction2D actions (WASD/thumbstick as Vector2)
- **DIR-03**: Developer can create Direction3D actions (6DOF input)
- **DIR-04**: Developer can use composite direction bindings (Up/Down/Left/Right keys → Vector2)

### Serialization

- **SRLZ-01**: Developer can export current bindings as a serializable table
- **SRLZ-02**: Developer can import bindings from a serializable table (for persistence)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Built-in rebinding UI | Couples package to opinionated visual style; devs build their own using rebinding API |
| Server-side input handling | IAS is client-only by engine design; RemoteEvents are game-specific |
| DataStore persistence for keybinds | Server-side concern outside input-wrapper scope; expose serializable API instead |
| Input combo/sequence detection | Stateful, timing-dependent, game-specific; better as separate package |
| Automatic gamepad icon/prompt display | Large separate problem; dedicated packages exist |
| Direction2D/3D in v1 | IAS gamepad thumbstick has active bugs (March 2026); triples API surface |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BLDR-01 | Phase 2 | Pending |
| BLDR-02 | Phase 2 | Pending |
| BLDR-03 | Phase 2 | Pending |
| BLDR-04 | Phase 2 | Pending |
| BLDR-05 | Phase 2 | Pending |
| BLDR-06 | Phase 2 | Pending |
| INPT-01 | Phase 2 | Pending |
| INPT-02 | Phase 2 | Pending |
| INPT-03 | Phase 3 | Pending |
| INPT-04 | Phase 3 | Pending |
| INPT-05 | Phase 3 | Pending |
| CTXT-01 | Phase 2 | Pending |
| CTXT-02 | Phase 2 | Pending |
| CTXT-03 | Phase 2 | Pending |
| DEVX-01 | Phase 1 | Pending |
| DEVX-02 | Phase 1 | Pending |
| DEVX-03 | Phase 1 | Complete (01-01) |
| DEVX-04 | Phase 3 | Pending |
| DEVX-05 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-04*
*Last updated: 2026-03-04 after 01-01 execution (DEVX-03 complete)*
