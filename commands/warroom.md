---
description: "Recon — reverse-engineers the repository/feature into living documentation. Maps the stack, flows, business rules and landmines, and persists everything under .warroom/ (architecture.md + manifest.json). Pass a path to focus (e.g. /warroom src/billing) or nothing to scan the whole repo."
argument-hint: "[optional path|feature]"
---

# /warroom — Recon (living documentation for a codebase)

You are going to rebuild trustworthy context from a legacy repository and **persist** the result so
the team can inherit it. Follow this protocol to the letter.

## Step 0 — Scope and progress

- The scope is the `$ARGUMENTS` argument. If empty, the scope is the whole repository (`.`).
- Create a visible task list (TaskCreate) with 3 items: `Recon`, `Persist doc`, `Generate manifest`.

## Step 1 — Run the Recon

Invoke the **`recon`** subagent via the `Agent` tool, instructing it to analyze the scope
(`$ARGUMENTS` or the whole repo) and produce the complete Architecture Document, **including the
mandatory section "7. Files Analyzed"**. Wait for the result.

## Step 2 — Persist the living documentation

1. Create the `.warroom/` directory at the root of the target repository (not in the plugin repo).
2. Write the Recon output to `.warroom/architecture.md`.

## Step 3 — Generate the manifest (drift baseline)

Build a `.warroom/manifest.json` that is valid against `schemas/manifest.schema.json`. To do this, use Bash:

```bash
# current commit (or null if not a git repo)
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")
# ISO-8601 UTC timestamp
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# hash of each file listed by the Recon in the "Files Analyzed" section:
shasum -a 256 <file>   # use the first field (64 hex) as sha256
```

Fill in:
- `warroom_version`: `"2.1.0"`
- `generated_at`: `$TS`
- `mode`: `"recon"`
- `model`: the model used by the Recon (`"sonnet"`)
- `scope`: `$ARGUMENTS` or `"."`
- `commit_sha`: `$COMMIT` (or `null` if empty)
- `files`: a `{path, sha256}` object for **each** file in the "Files Analyzed" section.

Write it to `.warroom/manifest.json`. Mark the tasks as completed as you progress.

## Step 4 — Wrap-up

Reply to the user with:
- The path to the generated artifacts (`.warroom/architecture.md`, `.warroom/manifest.json`).
- 3-5 bullets covering the most relevant **landmines** found by the Recon.
- Suggestion: run `/warroom-audit` for the full multi-agent risk audit.

## Rules

- **Don't make things up** — the Recon is already instructed to only assert what it can back with
  `file:line` evidence.
- **Committable:** the artifacts under `.warroom/` are designed to be versioned by the team.
- If `.warroom/manifest.json` already exists, warn that you are **overwriting** the previous
  analysis (in v2.2 this becomes an incremental diff via `/warroom-refresh`).
- **Reply to the user in their language** (match the language of their request); the generated artifacts follow the agents' language-adaptive rule.
