# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`blyy-doc-skills` is a **meta-skills package**. It does not contain application code — there is nothing to build, test, or lint. Every file under `skills/` is Markdown that gets installed into *other* projects' AI-tool skill directories (`.agents/skills/` or `.claude/skills/`), where an AI coding assistant reads it as instructions.

That means when you're editing this repo, you're editing instructions that another Claude (Gemini / Codex / Cursor / Claude Code) will execute against an unknown target project. Every rule you write must be mechanically checkable and must not rely on the authoring LLM's intuition.

## Commands

There is no build / test / lint command for this repo itself. The only executables are the two install scripts:

```bash
# Linux / macOS — installs skills into a target project (auto-detects AI tool)
./install.sh /path/to/target-project
./install.sh /path/to/target-project --tool claude           # force tool
./install.sh /path/to/target-project --skills blyy-ai-docs   # subset

# Windows PowerShell
.\install.ps1 -TargetProject "C:\path\to\target-project"
```

When you modify anything in `skills/<name>/`, the install scripts' default `SKILLS` list (`install.sh:23`, `install.ps1:24`) must still resolve — verify by running `./install.sh /tmp/blyy-test` against an empty directory.

## Three skills, three concerns — do not merge them

| Skill | Output dir | Audience | Self-invalidation |
|-------|------------|----------|-------------------|
| `blyy-init-docs` | `docs/` | human + AI | three defense lines (sync matrix / pre-commit gate / periodic audit) |
| `blyy-doc-sync` | `docs/` | human + AI | same, consumes `blyy-init-docs` baseline |
| `blyy-ai-docs` | `ai-docs/` (gitignored) | **AI only** | 4-tier (file existence → sha256 → symbol body sha256 → range fallback) |

- `blyy-init-docs` and `blyy-doc-sync` are a **pair**: init writes the baseline YAML into `docs/doc-maintenance.md`, sync reads/updates it. Don't touch one without checking whether the data contract still holds.
- `blyy-ai-docs` is **completely independent** — it carries its own trimmed tech-stack matrix, its own query recipes, its own anti-hallucination rules. Do not add `Read` calls into `blyy-init-docs/resources/` from this skill even when the content looks duplicated; duplication is deliberate.
- If you find yourself editing both `docs/` and `ai-docs/` concepts in one change, you're probably crossing a boundary — stop and split.

## Progressive loading is a hard constraint

Every `SKILL.md` is loaded in full on every invocation, so it's the hot path. Anything verbose lives in `resources/*.md` and gets loaded on demand. Two rules:

1. **`SKILL.md` must be self-contained.** If the AI never reads a single resource file, it must still be able to do a degraded but correct run. Every resource has a "何时读取" / "When to read" line at the top stating its trigger — add one whenever you create a new resource.
2. **Resources never `Read` each other.** SKILL.md is the only router. A resource referencing another resource is a code smell — the graph must stay a star, not a web.

See `docs/architecture.md` for the full loading map per skill.

## How facts get into docs

All three skills share the **T1 / T2 / T3** fact classification model. T1 = grep-verifiable code fact. T2 = strong inference backed by ≥2 independent signals. T3 = weak speculation, **must** pass a one-shot user-confirmation "Pre-Fill Review Gate" before being written to a real doc (otherwise it gets wrapped in `<!-- UNVERIFIED: ... -->`).

Corollary rules you'll run into when editing templates or resources:

- **No enumeration lists.** Any table / bullet list of "all entities / all endpoints / all files" belongs in `code-queries.md` as a deterministic `fd` / `rg` recipe, not in any prose doc. `blyy-ai-docs` enforces this structurally: lists > 20 rows are rejected by the self-check gate.
- **Every non-boilerplate claim carries an anchor.** Anchor format priority: `[file#Symbol]` > `[file#Symbol:42-58]` > `[file:42-58]` > `[file]`. Symbol anchors survive line drift; range-only anchors are a reluctant fallback.
- **File hashes use `git hash-object`.** Never `sha256sum` / `Get-FileHash` — `git hash-object` is zero-dep, cross-platform, and matches git's own blob hash so tooling can cross-check.

## Module complexity tiers (init-docs / doc-sync only)

`blyy-init-docs` grades each identified module by a shell-computable score and picks a doc form:

- **Core** (≥3 pts): full `modules/<m>/` directory (README + flow + code-map + data-model + api-reference + database)
- **Standard** (1–2 pts): single `modules/<m>.md`
- **Lightweight** (0 pts): inlined into `modules.md`

Scoring signals (all deterministic): source file count, presence of entities, presence of controllers, inbound module dependency count. `blyy-doc-sync` defense line 1 only upgrades tiers; defense line 3 re-evaluates bidirectionally. When editing `doc-guide.md`, `modules.md.template`, or the tier logic, keep all three in sync.

## Versioning & changelog discipline

- Every release bumps `docs/CHANGELOG.md` with a dated `[x.y.z]` section and appends a link at the bottom.
- The last tag in `git log` (currently `【v0.3.2】`) is the source of truth for what's released; CHANGELOG headings may be ahead.
- `blyy-ai-docs` is v0.4.0 (unreleased at time of writing) and is new ground — its MANIFEST schema hasn't been through a real breaking change yet, so prefer additive changes over field renames.

## Where to look when something's confusing

- `README.md` — user-facing install & scenarios (bilingual EN/中文)
- `docs/architecture.md` — the actual map of this repo: skill boundaries, data contracts between skills, progressive-loading layout, version strategy
- `docs/usage-guide.md` — walks through what each skill *does* from a user's perspective
- `docs/customization.md` — template placeholders, front-matter fields, extension points
- `skills/<name>/SKILL.md` — always the entry point for that skill; read this before any resource under it
