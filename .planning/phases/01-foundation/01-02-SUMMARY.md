---
phase: 01-foundation
plan: 02
subsystem: api
tags: [luau, roblox, ias, builder-pattern, github-actions, stylua, selene]

# Dependency graph
requires:
  - phase: 01-01
    provides: rokit.toml, stylua.toml, selene.toml, wally.toml toolchain config

provides:
  - src/Types.luau — complete builder type interface contracts (ContextBuilder, ActionBuilder, BindingBuilder + callback types)
  - src/IASAdapter.luau — IAS Instance.new() isolation adapter
  - src/init.luau — package entry point with client guard and type re-exports
  - .github/workflows/ci.yml — CI pipeline enforcing StyLua and Selene on push/PR

affects: [02-core-builders, 03-advanced-features]

# Tech tracking
tech-stack:
  added: [github-actions, roblox-ts/setup-rokit]
  patterns: [builder-pattern type contracts, adapter isolation pattern, client-guard pattern]

key-files:
  created:
    - src/Types.luau
    - src/IASAdapter.luau
    - src/init.luau
    - .github/workflows/ci.yml
  modified: []

key-decisions:
  - "Full interface definitions in Phase 1 so Phase 2 has complete contracts to implement against"
  - "getRawInstance() escape hatch on all three builders — IAS instances hidden by default"
  - "IASAdapter isolates all Instance.new() calls — one file to update if IAS API changes"
  - "Client guard errors immediately (level 2) when required from server context"

patterns-established:
  - "Type contracts pattern: Types.luau defines full interfaces; builders implement in Phase 2"
  - "Adapter isolation: all IAS Instance.new() calls go through IASAdapter, never direct"
  - "Back-reference methods: ActionBuilder.context() and BindingBuilder.action() allow fluent chain navigation"

requirements-completed: [DEVX-01, DEVX-02, DEVX-03]

# Metrics
duration: 3min
completed: 2026-03-04
---

# Phase 1 Plan 02: Type Skeleton, IAS Adapter, and CI Pipeline Summary

**ContextBuilder/ActionBuilder/BindingBuilder type contracts in Types.luau, IAS Instance.new() isolation adapter, client-guarded entry point, and GitHub Actions CI with StyLua + Selene checks**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-04T17:35:57Z
- **Completed:** 2026-03-04T17:38:30Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Created Types.luau with 6 strict exported types — 3 builders (ContextBuilder, ActionBuilder, BindingBuilder) and 3 callback types (OnPressed, OnReleased, OnStateChanged) using direct Roblox engine types
- Created IASAdapter.luau wrapping all IAS Instance.new() calls behind a single module for future API change resilience
- Created init.luau with client-side RunService guard, full type re-exports for consumer autocomplete, and stub EZInput.context()
- Created .github/workflows/ci.yml running StyLua check and Selene lint on push/PR via setup-rokit
- All source files pass `stylua --check` and `selene` with zero warnings locally

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Types.luau with full builder interface definitions** - `89e10c7` (feat)
2. **Task 2: Create IASAdapter, init entry point, and CI workflow** - `a061484` (feat)
3. **Task 3: Run linters and fix formatting** — no commit needed (files already correctly formatted)

## Files Created/Modified

- `src/Types.luau` — Complete type interface contracts for all three builders plus callback types; 35 lines; no `any` types
- `src/IASAdapter.luau` — Thin adapter with newContext/newAction/newBinding wrapping Instance.new(); 24 lines
- `src/init.luau` — Package entry point with client guard, type re-exports, and stub EZInput.context(); 24 lines
- `.github/workflows/ci.yml` — CI pipeline using roblox-ts/setup-rokit@v0.1.2 for StyLua check and Selene lint; 21 lines

## Decisions Made

- Used `roblox-ts/setup-rokit@v0.1.2` in CI — matches research recommendation for Roblox toolchain in GitHub Actions
- ContextBuilder includes back-reference method `context()` on ActionBuilder and `action()` on BindingBuilder — enables fluent chain navigation (`.bind().withModifier().action().onPressed()`)
- All builders expose `getRawInstance()` as escape hatch per user decision, keeping IAS instances hidden by default
- IASAdapter disables InputContext immediately on creation (`Enabled = false`) — must be explicitly activated

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — linters were available locally (via rokit installed in Plan 01-01) and both passed with zero warnings on first run.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Type contracts are complete — Phase 2 builders have clear interfaces to implement
- IASAdapter ready — Phase 2 builders call adapter methods, never Instance.new() directly
- CI pipeline active — every commit to main and every PR will be linted automatically
- Concern: IAS beta API may shift; adapter pattern ensures only IASAdapter.luau needs updating
