---
phase: 02-core-builder
plan: "02"
subsystem: input
tags: [luau, roblox, IAS, builder-pattern, event-wiring]

requires:
  - phase: 02-01
    provides: ContextBuilder, ActionBuilder skeletons with callback storage arrays

provides:
  - BindingBuilder implementation with full type contract (withModifier, withSecondaryModifier, action, context, destroy, getRawInstance)
  - ActionTriggered IAS event connection wired into ActionBuilder via lazy _wireEvents()
  - Full fluent chain complete: EZInput.context():action():bind():onPressed() structurally wired

affects:
  - 02-03 (context management and phase tests)
  - 03-01+ (any phase testing real input behavior)

tech-stack:
  added: []
  patterns:
    - Lazy event wiring: connect ActionTriggered only when first callback is registered
    - Trove child hierarchy: BindingBuilder creates child trove from ActionBuilder's trove for cascade destroy
    - Back-references: BindingBuilder holds references to both ActionBuilder and ContextBuilder for fluent chain navigation

key-files:
  created:
    - src/BindingBuilder.luau
  modified:
    - src/ActionBuilder.luau

key-decisions:
  - "Lazy _wireEvents(): IAS event only connected when first callback registered — avoids unnecessary listener until developer actually registers a handler"
  - "BindingBuilder receives contextBuilder reference through ActionBuilder — preserves fluent navigation chain without global state"
  - "withModifier/withSecondaryModifier set IAS InputBinding properties directly — future Phase 3 feature stubs that do not error, keeping type contract complete now"

patterns-established:
  - "Destroyed guard pattern: all public methods check _destroyed and error with [EZInput] prefix and level 2"
  - "Lazy wiring pattern: _eventsWired boolean prevents duplicate connections on repeated callback registrations"

requirements-completed: [BLDR-03, BLDR-04, BLDR-05, INPT-01, INPT-02]

duration: 4min
completed: 2026-03-04
---

# Phase 2 Plan 02: BindingBuilder and IAS Event Wiring Summary

**BindingBuilder with cascade trove destroy, ActionTriggered lazy wiring, and verified end-to-end fluent chain: EZInput.context():action():bind(KeyCode):onPressed(fn)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-04T18:54:22Z
- **Completed:** 2026-03-04T18:58:30Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 updated)

## Accomplishments

- Created BindingBuilder.luau implementing full type contract: 6 methods plus constructor
- Wired ActionTriggered IAS event into ActionBuilder with lazy connection strategy
- Verified EZInput.context() already had real ContextBuilder.new implementation from Plan 01
- Full fluent chain structurally complete: EZInput.context("Combat"):action("Attack"):bind(Enum.KeyCode.F):onPressed(fn) creates real IAS instances and wires callbacks

## Task Commits

1. **Task 1: Implement BindingBuilder.luau** - `80f34bb` (feat)
2. **Task 2: Wire ActionTriggered callbacks and verify EZInput.context()** - `0afa9c0` (feat)

## Files Created/Modified

- `src/BindingBuilder.luau` - Full BindingBuilder implementation: constructor takes (keyCode, actionBuilder, contextBuilder, parentTrove), creates child trove, wraps IASAdapter.newBinding(), implements withModifier/withSecondaryModifier/action/context/destroy/getRawInstance
- `src/ActionBuilder.luau` - Added _wireEvents() method with ActionTriggered connection, added _eventsWired flag, updated onPressed/onReleased/onStateChanged to call _wireEvents() lazily before storing callback

## Decisions Made

- Lazy _wireEvents() approach: ActionTriggered only connected when developer first registers a callback, keeping resource usage minimal for actions that only bind keys without callbacks
- BindingBuilder back-references: both _actionBuilder and _contextBuilder stored so developers can navigate back up the fluent chain from any level
- withModifier/withSecondaryModifier implemented as functional stubs that set IAS properties directly (Phase 3 feature, but method exists now for complete type contract)

## Deviations from Plan

None - plan executed exactly as written. init.luau already had the real ContextBuilder.new implementation from Plan 01's earlier work, which matched the expected state.

## Issues Encountered

None — all files passed StyLua and Selene on first attempt with 0 errors/warnings.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Full input-to-callback pipeline complete: context -> action -> bind -> onPressed/onReleased/onStateChanged
- Ready for Plan 02-03: context management methods (enable/disable, setPriority, setSink) already exist from Plan 01 work
- Keyboard KeyCodes and mouse button KeyCodes both accepted by bind() via IASAdapter.newBinding()
- Duplicate KeyCode detection on same action already implemented in ActionBuilder.bind()

---
*Phase: 02-core-builder*
*Completed: 2026-03-04*
