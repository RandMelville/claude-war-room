---
description: "Full War Room — multi-agent risk audit. Reuses the Recon map, runs 4 specialists IN PARALLEL (scalability, concurrency, chaos/SRE, security), consolidates them in the Lead and persists findings.json + audit/*.md. Pass a path/feature to focus."
argument-hint: "[optional path|feature]"
---

# /warroom-audit — Multi-agent audit (map → fan-out → reduce)

A 360° risk audit on top of the Recon map. **Pattern: map → parallel fan-out → reduce.**
Follow it to the letter.

## Step 0 — Scope, map and progress

- Scope = `$ARGUMENTS` (empty ⇒ whole repo `.`).
- **Ensure the Recon map exists:** if `.warroom/architecture.md` does **not** exist, first run the
  `recon` subagent (same as `/warroom`) and persist `architecture.md` + `manifest.json`. If it
  already exists, reuse it as context.
- Create a task list (TaskCreate): `Recon (if needed)`, `Specialists (parallel)`, `Consolidation`,
  `Persist findings`.

## Step 1 — PARALLEL fan-out (4 specialists)

Fire off the **4 subagents in parallel — emitting the 4 `Agent` tool calls in a single message**
(not sequentially). Each one receives as context: the contents of `.warroom/architecture.md` and the
scope.

1. `scalability-architect` — infrastructure bottlenecks and breaking point.
2. `concurrency-specialist` — race conditions, deadlocks, locking.
3. `chaos-engineer-sre` — disaster scenarios and resilience.
4. `security-auditor` — OWASP vulnerabilities, secrets, authz, privacy.

> Running in parallel cuts time and **avoids blowing up the context window** that the old sequential
> mode caused. They are independent: all of them analyze the same map.

Wait for the 4 outputs.

## Step 2 — Reduce (consolidation)

Invoke the **`quality-stability-lead`** subagent via `Agent`, passing as context **the 4 specialist
outputs + the `architecture.md`**. It MUST produce:
- the **Confidence Report** in Markdown; and
- the final **`findings.json`** block, valid against `schemas/findings.schema.json`.

## Step 3 — Persist

In the target repository's `.warroom/` folder:
1. `audit/02-scalability.md`, `audit/03-concurrency.md`, `audit/04-chaos.md`,
   `audit/05-security.md` — one output per specialist.
2. `audit/06-report.md` — the Lead's Confidence Report.
3. `findings.json` — the JSON block emitted by the Lead (write only the JSON, no code fences).
4. Update `manifest.json` with `mode: "audit"` and `model: "opus"` (reuse the
   `commit_sha`/`generated_at`/`files` collection described in `/warroom`).

Mark the tasks as you complete them.

## Step 4 — Wrap-up

Reply to the user with:
- **Confidence Index** (🔴/🟡/🟢) and the consolidated **Severity Table**.
- Number of findings per severity (e.g. 3 critical, 5 high…).
- The path to the artifacts (`.warroom/audit/`, `.warroom/findings.json`).

## Rules

- **Truly parallel:** the 4 `Agent` calls from Step 1 go in the same message.
- **findings.json is mandatory** and must validate against the schema (severity integer 1-10, status
  `open`, verified `false`).
- **Adversarial verification** of findings (killing false positives) lands in v2.1; for now every
  finding ships with `verified: false`.
- **Respect the target repository's CLAUDE.md**, if one exists.
- **Reply to the user in their language** (match the language of their request); the generated artifacts follow the agents' language-adaptive rule.
