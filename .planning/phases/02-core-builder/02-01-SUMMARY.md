---
phase: 02-core-builder
plan: 01
subsystem: builder
tags: [luau, roblox, ias, trove, builder-pattern, fluent-api]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Types.luau type contracts, IASAdapter.luau Instance.new() wrappers, init.luau entry point

provides:
  - ContextBuilder with action(), enable(), disable(), setPriority(), setSink(), destroy(), getRawInstance()
  - ActionBuilder with bind(), onPressed(), onReleased(), onStateChanged(), context(), destroy(), getRawInstance()
  - Trove-managed lifecycle with cascading destroy from context to all child actions
  - Shared context registry for duplicate name detection
  - Working EZInput.context() entry point in init.luau

affects:
  - 02-02 (BindingBuilder implements bind() stub, gets contextBuilder reference passed through)
  - 03-x (all future phases depend on this builder chain)

# Tech tracking
tech-stack:
  added: [sleitnick/trove@1.8.0]
  patterns:
    - Lazy require pattern for circular dependency breaking (ContextBuilder <-> ActionBuilder, ActionBuilder <-> BindingBuilder)
    - Trove:Extend() child troves for cascading cleanup
    - Shared registry table passed from init.luau for duplicate detection
    - selene inline suppression for IAS beta enums not yet in stdlib

key-files:
  created:
    - src/ContextBuilder.luau
    - src/ActionBuilder.luau
  modified:
    - src/Types.luau (added :context() to BindingBuilder)
    - src/init.luau (wired real ContextBuilder.new() replacing stub)
    - wally.toml (added Trove dependency)
    - default.project.json (mapped Packages/ into Rojo tree)

key-decisions:
  - "Trove:Extend() used for child troves so context:destroy() cascades to all child action troves automatically"
  - "Lazy require pattern (local var + getter function) breaks ContextBuilder <-> ActionBuilder circular dependency"
  - "Wally resolved 1.1.0 constraint to sleitnick/trove@1.8.0 — this is correct behavior, kept"
  - "InputContext parented to LocalPlayer.PlayerGui — standard IAS parent for client contexts"
  - "selene inline allow comment used for Enum.InputActionSinkBehavior (IAS beta enum not in selene stdlib)"
  - "Callback storage in arrays now; IAS event connection deferred to Plan 02 when BindingBuilder exists"

patterns-established:
  - "Destroyed guard: all methods error with 'Cannot use destroyed [type] [name]' before operating"
  - "Duplicate detection: registry/table lookup at context level, action level, and binding level"
  - "IASAdapter indirection: builders never call Instance.new() directly"
  - "Builder returns self for chaining on configure methods, returns child builder on structural methods"

requirements-completed: [BLDR-01, BLDR-02, BLDR-06]

# Metrics
duration: 3min
completed: 2026-03-04
---

# Phase 2 Plan 01: ContextBuilder and ActionBuilder Summary

**Trove-backed ContextBuilder and ActionBuilder with cascading destroy, duplicate detection, and lazy-require circular dependency breaking**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-04T18:49:07Z
- **Completed:** 2026-03-04T18:51:43Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- ContextBuilder implements all 7 type contract methods with Trove lifecycle, destroyed guard, and duplicate context name detection
- ActionBuilder implements all 7 type contract methods, stores callbacks for Plan 02 wiring, and passes contextBuilder reference through for :context() chain support
- EZInput.context() in init.luau now returns a real ContextBuilder (replacing the Phase 1 stub) with a shared context registry

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Trove dependency and update Types.luau** - `3335288` (chore)
2. **Task 2: Implement ContextBuilder.luau** - `f17f0e3` (feat)
3. **Task 3: Implement ActionBuilder.luau** - `699f72f` (feat)

## Files Created/Modified

- `src/ContextBuilder.luau` — Full ContextBuilder implementation with Trove, lazy require, registry, destroyed guard
- `src/ActionBuilder.luau` — Full ActionBuilder with child Trove (Extend), callback storage, lazy require for BindingBuilder
- `src/Types.luau` — Added :context() method to BindingBuilder type
- `src/init.luau` — Wired real ContextBuilder.new() replacing Phase 1 stub, added shared contextRegistry
- `wally.toml` — Added sleitnick/trove@1.1.0 dependency (resolved to 1.8.0 by Wally)
- `default.project.json` — Added Packages/ path mapping for Rojo tree so Trove is accessible

## Decisions Made

- Used `Trove:Extend()` for ActionBuilder's child trove so `context:destroy()` automatically cascades cleanup to all child actions without explicit iteration
- Used lazy require getter functions to break circular dependency between ContextBuilder/ActionBuilder and ActionBuilder/BindingBuilder
- Parented InputContext to `LocalPlayer.PlayerGui` — this is standard IAS convention for client contexts
- Used `-- selene: allow(incorrect_standard_library_use)` inline for `Enum.InputActionSinkBehavior` since it's an IAS beta enum not yet in selene's roblox stdlib

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] StyLua formatting fixed on multi-line if-expression**
- **Found during:** Task 2 (ContextBuilder.luau creation)
- **Issue:** StyLua requires `if sink then ... else ...` on one line — multi-line format failed `--check`
- **Fix:** Collapsed the if-expression to a single line per StyLua's style rules
- **Files modified:** src/ContextBuilder.luau
- **Verification:** `stylua --check src/ContextBuilder.luau` passes
- **Committed in:** f17f0e3 (Task 2 commit)

**2. [Rule 3 - Blocking] StyLua formatting fixed on multi-line error() call in ActionBuilder**
- **Found during:** Task 3 (ActionBuilder.luau creation)
- **Issue:** StyLua requires the error message string concatenation on one line
- **Fix:** Collapsed to single-line error() call
- **Files modified:** src/ActionBuilder.luau
- **Verification:** `stylua --check src/ActionBuilder.luau` passes
- **Committed in:** 699f72f (Task 3 commit)

**3. [Rule 3 - Blocking] Selene unknown enum suppression for IAS beta Enum.InputActionSinkBehavior**
- **Found during:** Task 2 (Selene lint of ContextBuilder.luau)
- **Issue:** `Enum.InputActionSinkBehavior.Sink` and `.PassThrough` unknown to selene's roblox stdlib (IAS is still beta)
- **Fix:** Added `-- selene: allow(incorrect_standard_library_use)` inline comment before the assignment
- **Files modified:** src/ContextBuilder.luau
- **Verification:** `selene src/` passes with 0 errors
- **Committed in:** f17f0e3 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 3 blocking)
**Impact on plan:** All auto-fixes were formatting/linting issues from linter tool behavior. No scope creep. All plan objectives met exactly.

## Issues Encountered

- Wally resolved `sleitnick/trove@1.1.0` constraint to `1.8.0` (latest compatible semver). This is correct Wally behavior — kept as-is since it's a more recent stable release.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ContextBuilder and ActionBuilder fully implemented and ready for BindingBuilder to attach to (Plan 02-02)
- `bind()` on ActionBuilder is stubbed correctly: creates BindingBuilder via lazy require, passes keyCode + actionBuilder + contextBuilder + trove
- Callbacks stored in arrays ready for Plan 02 event wiring
- All files pass StyLua and Selene — CI will pass

## Self-Check: PASSED

All files and commits verified present.

---
*Phase: 02-core-builder*
*Completed: 2026-03-04*
