# Stack Research

**Domain:** Roblox Luau Wally package (input wrapper library)
**Researched:** 2026-03-04
**Confidence:** MEDIUM — core toolchain verified via official sources; IAS-specific ecosystem is thin (Beta API, few wrappers exist yet)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Luau | Built-in (Roblox) | Implementation language | No choice — Roblox packages must be Luau. Use `--!strict` throughout; it's the de-facto standard for published packages and enables consumer autocomplete |
| Wally | 0.3.2 | Package registry and dependency manager | The dominant Roblox package manager. Has stable link generation, dev-dependencies support (since 0.3.2), and is the registry consumers expect. Not actively developed but the ecosystem is built around it |
| Rojo | 7.6.x (stable) | File sync: maps `.luau` files to Roblox Studio instances | Required for any serious external-editor workflow. v7 is the standard; the `default.project.json` in the package root tells Rojo how to expose the `src/` directory as a ModuleScript tree |
| Rokit | 1.2.0 | Toolchain manager: pins versions of Rojo, Wally, StyLua, Selene | Replaces the abandoned Aftman. Maintained by the rojo-rbx org, compatible with existing `aftman.toml` files, and installs tools from GitHub Releases automatically |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| StyLua | 2.3.1 | Deterministic Luau code formatter | Always — run in CI and as pre-commit hook. Eliminates style debates. v2.x is stable; output is consistent across minor bumps |
| selene | 0.30.1 | Static analysis / linter for Luau | Always — catches unused variables, deprecated API usage, shadowing. Configure `selene.toml` with `std = "roblox"` so it understands Roblox globals |
| luau-lsp | 1.44.x | Language server for editor support during development | Dev tooling only; not bundled in the package. Enables type-aware autocomplete in VS Code |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `rokit.toml` | Pins exact tool versions for all contributors | Commit this file; it ensures CI and local dev use identical tool versions. Format: `[tools] rojo = "rojo-rbx/rojo@7.6.1"` |
| `selene.toml` | Configures Selene rules | Minimum: `std = "roblox"`. Add `[rules] unused_variable.severity = "warning"` |
| `stylua.toml` | Configures StyLua formatting | Minimum: `column_width = 120`, `indent_type = "Tabs"`, `indent_width = 4`. Matches Roblox style guide |
| `.luaurc` | Enables strict mode project-wide | Set `{ "languageMode": "strict" }` — this applies `--!strict` to all files without requiring the comment in each file |
| `default.project.json` | Rojo project definition | Points Rojo at `src/` so the package root syncs as a single ModuleScript (or folder) — critical for how Wally consumers `require()` the package |
| GitHub Actions | CI: lint, format check, type check | Run `selene src/` and `stylua --check src/` on every PR. Optionally add `luau-lsp analyze` for type checking in CI |

## Installation

```bash
# 1. Install Rokit (macOS/Linux)
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash

# 2. Add tools to rokit.toml
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene

# 3. Install the pinned tools
rokit install

# 4. Initialize Wally package manifest
wally init

# 5. Install Wally dependencies (if any)
wally install
```

## Project File Structure

A standard Wally package for a pure Luau library:

```
EZInput/
├── src/
│   ├── init.luau          # Package entry point — what consumers require
│   ├── Context.luau       # InputContext builder
│   ├── Action.luau        # InputAction builder
│   ├── Binding.luau       # InputBinding builder
│   └── Types.luau         # Exported type definitions
├── .github/
│   └── workflows/
│       └── ci.yml         # Lint + format check
├── .luaurc                # { "languageMode": "strict" }
├── default.project.json   # Rojo project: maps src/ into Roblox
├── rokit.toml             # Tool version pins
├── selene.toml            # Selene config
├── stylua.toml            # StyLua config
├── wally.toml             # Package manifest
└── wally.lock             # Lockfile (commit this)
```

### Minimal `wally.toml` for EZInput

```toml
[package]
name = "yourusername/ezinput"
description = "Fluent builder API over Roblox's Input Action System"
version = "0.1.0"
license = "MIT"
authors = ["Your Name"]
realm = "shared"
registry = "https://github.com/UpliftGames/wally-index"
exclude = [".github", "tests"]

[dependencies]
# No Wally dependencies needed for v1 — IAS is a native Roblox API
```

### Minimal `default.project.json`

```json
{
  "name": "EZInput",
  "tree": {
    "$path": "src"
  }
}
```

This causes Wally consumers to get the `src/` folder as the required module. With `src/init.luau` as the entry point, `require(EZInput)` resolves to `init.luau`.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Wally 0.3.2 | pesde 0.7.x | If targeting both Roblox and Lune runtimes, or if Wally's registry goes down. pesde can consume Wally packages but has its own registry and is less widely adopted as of early 2026 |
| Rokit 1.2.0 | Aftman (any version) | Never for new projects — Aftman is abandoned and its maintainer has left Roblox development |
| StyLua 2.3.1 | lua-fmt, prettier-plugin-lua | Never — StyLua is the only formatter that handles Luau syntax correctly |
| Selene 0.30.1 | Luacheck | Never for Luau — Luacheck doesn't understand Luau types or Roblox globals without heavy config; Selene has native `std = "roblox"` support |
| Rojo 7.x | Argon, Lync | Only if consumers require alternative sync tools. Rojo 7 is the standard; Argon is an emerging alternative but has a smaller user base |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Aftman | Abandoned — maintainer left Roblox development, uncertain future, no new releases | Rokit 1.2.0 |
| `.lua` file extension | Rojo and the Roblox ecosystem now defaults to `.luau`. Using `.lua` causes ambiguity with standard Lua | `.luau` extension throughout |
| `--!nonstrict` or no type mode | Defeats the consumer DX benefit; consumers can't get autocomplete or type safety from the package | `--!strict` in every file, or set via `.luaurc` |
| `_G` globals or shared tables | Makes the package impossible to use in strict mode and creates hidden coupling | Return explicit module tables from `require()` |
| Server realm dependencies | IAS is client-only; server-realm Wally packages would be incompatible with client scripts | Use `realm = "shared"` in `wally.toml` |
| Embedding dependencies via copy-paste | Breaks consumer version management and inflates package size | Use Wally `[dependencies]` or document as peer deps |
| TestEZ (official Roblox repo) | The official Roblox/testez repo is archived and unmaintained | testez-luau fork (lrockreal) or defer tests entirely for v1 as per PROJECT.md |

## Stack Patterns by Variant

**If publishing to Wally registry (wally.run):**
- Set `private = false` (omit private field)
- Set `realm = "shared"` — IAS instances only exist client-side but the wrapper code is shared
- Run `wally publish` from the project root after authenticating with `wally login`

**If distributing as a GitHub release (no Wally registry):**
- Consumers add as a Git dependency: `EZInput = "github:yourusername/EZInput@v0.1.0"`
- Still include `wally.toml` so the format is upgrade-compatible

**If adding tests later (post-v1):**
- Use Lune (standalone Luau runtime) to run tests outside Studio
- Add `testez-luau` (the community fork of TestEZ) as a `[dev-dependencies]` entry
- Do NOT use the archived `roblox/testez` package

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Wally 0.3.2 | Rojo 7.x | Both read `default.project.json`; no conflicts |
| Rokit 1.2.0 | Existing aftman.toml | Rokit can read aftman.toml for migration, but new projects should use rokit.toml |
| StyLua 2.x | Luau (all versions) | v2.0 committed to stable output; minor bumps won't change formatting |
| selene 0.30.1 | `std = "roblox"` | The `roblox` std bundle is included; no extra download needed |
| luau-lsp 1.44.x | VS Code 1.80+ | Editor-only; not part of the built package |

## Sources

- [github.com/UpliftGames/wally](https://github.com/UpliftGames/wally) — Wally README, wally.toml format (HIGH confidence)
- [github.com/UpliftGames/wally/releases](https://github.com/UpliftGames/wally/releases) — Confirmed v0.3.2 as latest stable (HIGH confidence)
- [github.com/rojo-rbx/rokit](https://github.com/rojo-rbx/rokit) — Rokit as Aftman successor, v1.2.0 confirmed latest (HIGH confidence)
- [github.com/rojo-rbx/rojo/releases](https://github.com/rojo-rbx/rojo/releases) — Rojo v7.6.x current stable (HIGH confidence)
- [github.com/JohnnyMorganz/StyLua](https://github.com/JohnnyMorganz/StyLua) — StyLua v2.3.1 confirmed via docs.rs (HIGH confidence)
- [github.com/Kampfkarren/selene/releases](https://github.com/Kampfkarren/selene/releases) — selene v0.30.1 confirmed (HIGH confidence)
- [github.com/JohnnyMorganz/luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) — v1.44.0 confirmed as of Apr 2025; likely newer by now (MEDIUM confidence)
- [github.com/takoyakisoft/roblox-rojo-wally-template](https://github.com/takoyakisoft/roblox-rojo-wally-template) — Reference for canonical project structure using Rokit + Rojo + Wally + Selene (MEDIUM confidence)
- [github.com/rojo-rbx/vscode-rojo/issues/98](https://github.com/rojo-rbx/vscode-rojo/issues/98) — Confirms Rokit is "the new standard" replacing Aftman (MEDIUM confidence)
- [github.com/pesde-pkg/pesde](https://github.com/pesde-pkg/pesde) — pesde as Wally alternative; assessed but not recommended for v1 (MEDIUM confidence)
- [devforum.roblox.com — InputSystem community wrapper](https://devforum.roblox.com/t/inputsystem-robloxs-new-input-action-system-without-instances/3768911) — Existing community IAS wrappers use functional composition, confirms demand (MEDIUM confidence)
- [create.roblox.com/docs/luau/type-checking](https://create.roblox.com/docs/luau/type-checking) — Official Luau strict mode and exported types guidance (HIGH confidence)

---
*Stack research for: Roblox Luau Wally package (EZInput — Input Action System wrapper)*
*Researched: 2026-03-04*
