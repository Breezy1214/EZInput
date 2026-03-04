---
phase: 01-foundation
plan: "01"
subsystem: infra
tags: [rokit, rojo, wally, stylua, selene, luau, toolchain]

# Dependency graph
requires: []
provides:
  - "rokit.toml pinning rojo@7.6.1, wally@0.3.2, stylua@2.3.1, selene@0.29.0"
  - "wally.toml package manifest for charlesnwabuike/ezinput v0.1.0"
  - "default.project.json Rojo project file mapping src/ as EZInput root"
  - ".luaurc strict mode Luau type checking project-wide"
  - "stylua.toml formatter config (120 col, Tabs, AutoPreferDouble)"
  - "selene.toml linter config with roblox stdlib"
  - "roblox.yml selene standard library for offline CI lint"
affects: [all subsequent phases — toolchain required for all build/lint/package steps]

# Tech tracking
tech-stack:
  added: [rojo@7.6.1, wally@0.3.2, stylua@2.3.1, selene@0.29.0, rokit@1.0.0]
  patterns:
    - "Rokit for toolchain version pinning (replaces aftman)"
    - "Wally for Roblox package management"
    - "Rojo minimal library project pattern (src/ mapped as package root)"
    - "Strict Luau mode enforced via .luaurc"

key-files:
  created:
    - rokit.toml
    - wally.toml
    - default.project.json
    - .luaurc
    - stylua.toml
    - selene.toml
    - roblox.yml
  modified: []

key-decisions:
  - "Package scope charlesnwabuike/ezinput in wally.toml (matches user decision from research)"
  - "EZInput as the Rojo project name so consumers get EZInput in their Packages/ folder"
  - "roblox.yml committed to repo so CI lint works offline without internet access"
  - "selene.toml uses std=roblox for full Roblox API awareness in the linter"

patterns-established:
  - "Toolchain pinning: all tools pinned to exact versions in rokit.toml"
  - "Strict Luau: .luaurc languageMode=strict enforced project-wide from day one"
  - "Formatter standard: 120 col width, Tabs, AutoPreferDouble quotes"

requirements-completed: [DEVX-03]

# Metrics
duration: 1min
completed: "2026-03-04"
---

# Phase 1 Plan 01: Toolchain Scaffold Summary

**Rokit + Wally + Rojo project scaffold with strict Luau config, stylua/selene formatters, and all four tools installed at exact pinned versions**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-04T17:31:48Z
- **Completed:** 2026-03-04T17:32:53Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Created all six required config files (rokit.toml, wally.toml, default.project.json, .luaurc, stylua.toml, selene.toml)
- Ran `rokit install` — all four tools downloaded and verified at exact pinned versions (rojo@7.6.1, wally@0.3.2, stylua@2.3.1, selene@0.29.0)
- Generated and committed `roblox.yml` via `selene generate-roblox-std` for offline CI Roblox globals

## Task Commits

Each task was committed atomically:

1. **Task 1: Create toolchain and package config files** - `a0d36b6` (chore)
2. **Task 2: Install Rokit tools and verify toolchain** - `d7e28be` (chore)

**Plan metadata:** (docs commit — pending)

## Files Created/Modified

- `rokit.toml` - Pins rojo, wally, stylua, selene to exact versions via Rokit
- `wally.toml` - Package manifest for charlesnwabuike/ezinput v0.1.0 with src include
- `default.project.json` - Rojo project file: EZInput package name, $path points to src/
- `.luaurc` - Strict Luau language mode project-wide
- `stylua.toml` - Formatter: 120 col, Tabs, AutoPreferDouble quotes
- `selene.toml` - Linter: roblox standard library
- `roblox.yml` - Selene Roblox standard library (544KB, generated from selene generate-roblox-std)

## Decisions Made

- Committed `roblox.yml` to the repo so CI lint runs offline without network access to Roblox API definitions
- Used `EZInput` (not lowercase) as the Rojo project name per the plan spec — this is what consumers see in their `Packages/` folder

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. All tools install via `rokit install`.

## Next Phase Readiness

- Toolchain fully operational: `rojo`, `wally`, `stylua`, `selene` all available
- Package identity established: `charlesnwabuike/ezinput` ready for `wally publish`
- Strict Luau mode active for all subsequent source files in `src/`
- Ready for Plan 02: source file scaffold and core module structure

## Self-Check: PASSED

All 7 files confirmed on disk: rokit.toml, wally.toml, default.project.json, .luaurc, stylua.toml, selene.toml, roblox.yml
All task commits confirmed: a0d36b6, d7e28be

---
*Phase: 01-foundation*
*Completed: 2026-03-04*
