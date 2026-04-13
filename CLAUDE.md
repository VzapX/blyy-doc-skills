# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`blyy-doc-skills` is a **meta-skills package**. It does not contain application code — there is nothing to build, test, or lint. Every file under `skills/` is Markdown that gets installed into *other* projects' AI-tool skill directories (`.agents/skills/` or `.claude/skills/`), where an AI coding assistant reads it as instructions.

That means when you're editing this repo, you're editing instructions that another Claude (Gemini / Codex / Cursor / Claude Code) will execute against an unknown target project. Every rule you write must be mechanically checkable and must not rely on the authoring LLM's intuition.

## Commands

There is no build / test / lint command for this repo itself. The only executables are the two install scripts:

```bash
# Linux / macOS — installs skill into a target project (auto-detects AI tool)
./install.sh /path/to/target-project
./install.sh /path/to/target-project --tool claude           # force tool
./install.sh /path/to/target-project --skills blyy-ai-docs   # explicit

# Windows PowerShell
.\install.ps1 -TargetProject "C:\path\to\target-project"
```

When you modify anything in `skills/<name>/`, the install scripts' default `SKILLS` list (`install.sh:23`, `install.ps1:24`) must still resolve — verify by running `./install.sh /tmp/blyy-test` against an empty directory.

## Single skill: blyy-ai-docs

| Skill | Output dir | Audience | Self-invalidation |
|-------|------------|----------|-------------------|
| `blyy-ai-docs` | `ai-docs/` (gitignored) | **AI only** | 4-tier (file existence → sha256 → symbol body sha256 → range fallback) |

`blyy-ai-docs` is a single skill with three auto-dispatched modes (Init / Sync / Audit). It carries its own tech-stack matrix, query recipes, anti-hallucination rules, and self-invalidation algorithm. It produces a flat `ai-docs/` directory (7 files + MANIFEST.yaml) that AI tools consume as a fast index layer.

**Four core principles** (filter for all edits):

1. **AI quick indexing** — help AI locate code entry points fast, not full-project scan
2. **Record invisible facts** — business logic, flows, design intent that code can't express directly
3. **Never repeat code facts** — entity lists, config tables, API inventories belong in `code-queries.md` as executable `fd`/`rg` recipes, not in prose docs
4. **Long-term freshness** — self-invalidation mechanism ensures docs don't drift

## Progressive loading is a hard constraint

Every `SKILL.md` is loaded in full on every invocation, so it's the hot path. Anything verbose lives in `resources/*.md` and gets loaded on demand. Two rules:

1. **`SKILL.md` must be self-contained.** If the AI never reads a single resource file, it must still be able to do a degraded but correct run. Every resource has a "何时读取" / "When to read" line at the top stating its trigger — add one whenever you create a new resource.
2. **Resources never `Read` each other.** SKILL.md is the only router. A resource referencing another resource is a code smell — the graph must stay a star, not a web.

See `docs/architecture.md` for the full loading map.

## How facts get into docs

The skill uses the **T1 / T2 / T3** fact classification model. T1 = grep-verifiable code fact. T2 = strong inference backed by ≥2 independent signals. T3 = weak speculation, **must** pass a one-shot user-confirmation "Pre-Fill Review Gate" before being written to a real doc (otherwise it gets wrapped in `<!-- UNVERIFIED: ... -->`).

Corollary rules you'll run into when editing templates or resources:

- **No enumeration lists.** Any table / bullet list of "all entities / all endpoints / all files" belongs in `code-queries.md` as a deterministic `fd` / `rg` recipe, not in any prose doc. Lists > 20 rows are rejected by the self-check gate.
- **Every non-boilerplate claim carries an anchor.** Anchor format priority: `[file#Symbol]` > `[file#Symbol:42-58]` > `[file:42-58]` > `[file]`. Symbol anchors survive line drift; range-only anchors are a reluctant fallback.
- **File hashes use `git hash-object`.** Never `sha256sum` / `Get-FileHash` — `git hash-object` is zero-dep, cross-platform, and matches git's own blob hash so tooling can cross-check.

## Module complexity tiers

`blyy-ai-docs` grades each identified module by a shell-computable score and controls **analysis depth** (not file structure — ai-docs is always flat):

- **Core** (≥3 pts): sub-agent full business analysis (5 categories: business summary, terms, flows, decisions, dependencies)
- **Standard** (1–2 pts): moderate analysis (3 categories: business summary, terms, dependencies)
- **Lightweight** (0 pts): main agent writes 1-line business summary, skips sub-agent

Scoring signals (all deterministic): source file count, presence of entities, presence of controllers/handlers, inbound module dependency count. Mode B only upgrades tiers; Mode C re-evaluates bidirectionally. Details in `resources/module-tiering.md`.

## Versioning & changelog discipline

- Every release bumps `docs/CHANGELOG.md` with a dated `[x.y.z]` section and appends a link at the bottom.
- The last tag in `git log` is the source of truth for what's released; CHANGELOG headings may be ahead.
- The MANIFEST schema hasn't been through a real breaking change yet, so prefer additive changes over field renames.

## Where to look when something's confusing

- `README.md` — user-facing install & overview (bilingual EN/中文)
- `docs/architecture.md` — the actual map of this repo: progressive-loading layout, state contracts, version strategy
- `docs/usage-guide.md` — walks through what each mode *does* from a user's perspective
- `docs/customization.md` — template placeholders, front-matter fields, extension points
- `skills/blyy-ai-docs/SKILL.md` — the entry point; read this before any resource under it
