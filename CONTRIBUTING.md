# Contributing Guide

Thanks for your interest in contributing to Claude War Room! This guide explains how to take part in the project.

---

## Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-war-room.git
   cd claude-war-room
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b feat/my-new-agent
   ```

---

## Agent Structure

Every agent must follow this structure in its `.md` file:

### YAML frontmatter (required)

```yaml
---
name: my-agent
description: "Short description of what the agent does. Used by Claude Code to decide when to invoke it."
model: opus
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
---
```

**Required fields:**
- `name` — **kebab-case** slug (must match the name used in `commands/` and the `agent` enum in `schemas/findings.schema.json`)
- `description` — What it does and when to use it (Claude Code uses this for routing)
- `model` — `opus`, `sonnet`, or `haiku` (Recon uses `sonnet`; specialists use `opus`)
- `tools` — List of tools the agent is allowed to use

### Agent body (required)

Sections every agent must have:

```markdown
# Agent Title

## Role
{Who the agent is and what their specialty is}

## Analysis Focus
{Numbered list of what to pay attention to}

## Execution Protocol
### Phase 1: {Name}
### Phase 2: {Name}
### Phase 3: Delivery

## Mandatory Response Structure
{Template inside ``` with the exact sections the agent must produce}

## Persona & Tone of Voice
{How the agent communicates}

## Non-Negotiable Guidelines
{Rules the agent must never break}
```

### Conventions

- **Mermaid diagrams are mandatory** in the response structure
- **Tables** for structured data (bottlenecks, risks, actions)
- **`file:line` references** whenever you assert something about the code
- **Language-adaptive output** — the agent answers in the language of the analyzed repository / user request, defaulting to English
- **The last guideline** must be: "Respect the analyzed repository's `CLAUDE.md`, if present."

---

## How to Test an Agent

1. Install the plugin from your local checkout (use your fork's path as the marketplace):
   ```
   /plugin marketplace add /path/to/your/claude-war-room
   /plugin install claude-war-room
   ```

2. Open Claude Code in a real project:
   ```bash
   cd /path/to/project
   claude
   ```

3. Invoke the agent directly (without the full War Room):
   - Claude Code will use the agent automatically when its description matches the task
   - Or mention it explicitly: "Use the [Name] agent to analyze..."

4. Check:
   - Does the agent follow the phased protocol?
   - Does the output follow the mandatory structure?
   - Do the Mermaid diagrams render correctly?
   - Are the `file:line` references accurate?

---

## Adding to the Pipeline

If the agent should be part of the War Room flow:

1. **Create** `agents/my-agent.md` with a kebab-case `name`.
2. **Register** the path in `.claude-plugin/plugin.json` under the `agents[]` array.
3. **Add** the `name` to the `agent` enum in `schemas/findings.schema.json`.
4. **Wire it** into the fan-out in `commands/warroom-audit.md` (one more parallel `Agent` call).
5. **Update** the docs: `docs/ARCHITECTURE.md` and the README.

---

## Commit Conventions

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Security Auditor agent to the pipeline
fix: correct frontmatter validation in CI
docs: update SRE-CHAOS output examples
chore: update markdownlint config
```

**Types:**
- `feat` — New agent, new feature
- `fix` — Bug fix
- `docs` — Documentation only
- `chore` — CI, configs, maintenance
- `refactor` — Restructuring without behavior change

---

## Pull Request Process

1. Make your changes on the branch
2. Run the linters locally (if possible):
   ```bash
   # Markdown lint
   npx markdownlint-cli2 "**/*.md"

   # ShellCheck
   shellcheck install.sh
   ```
3. Open a PR against `main`
4. Fill out the PR template
5. Wait for review and CI to pass

---

## What NOT to Do

- Don't remove agents from the pipeline without discussion (open an issue first)
- Don't rename the slash commands (`/warroom`, `/warroom-audit`) without consensus
- Don't add external runtime dependencies (the plugin is zero-dependency)
- Don't include real project data in the examples
- Don't push directly to `main` (use a PR)

---

## Contribution Ideas

- Create new **domain packs** (`packs/fintech`, `packs/healthtech`, …)
- Create new agents (Performance Profiler, Accessibility Auditor)
- Add real (anonymized) examples under `examples/`
- Improve the agents' output templates
- Work on roadmap items (v2.1: ✅ adversarial verifier shipped — next up: severity rubric, eval harness)
