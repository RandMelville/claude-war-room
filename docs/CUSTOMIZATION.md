# Customizing the War Room

The agent core is **domain-agnostic**. The orchestration (`commands/`) works for any
system. This guide shows how to adapt it to your context.

---

## 1. Domain Packs (instead of find-and-replace)

In v1 you manually edited the agents to reintroduce domain terms. In v2, this became a
**domain pack**: an optional overlay of terms, scale metrics, and regulations.

- See [`packs/edtech`](../packs/edtech/README.md) as an example and template.
- To activate it, paste the pack's block into the target repository's `CLAUDE.md` (or pass it as context when
  running `/warroom` / `/warroom-audit`). The agents are instructed to incorporate the active pack.

To create a new pack (e.g. FinTech), copy `packs/edtech/` to `packs/fintech/` and swap:

| Generic (core)        | FinTech                         |
|-----------------------|---------------------------------|
| user / customer       | operator / account holder       |
| order / transaction   | financial transaction / invoice |
| critical record       | ledger entry, balance           |
| load peak             | monthly closing                 |
| PII / sensitive data  | financial data (PCI-DSS)        |

---

## 2. Model Tiers

Each agent sets `model` in its frontmatter. The v2 defaults:

| Agent                     | Model   | Why                              |
|---------------------------|---------|----------------------------------|
| `recon`                   | sonnet  | High frequency, cheap            |
| 4 specialists + lead      | opus    | Depth where it matters           |

Adjust freely. To reduce the cost of an audit, swap `opus` → `sonnet` on the specialists
(less depth). For maximum depth on Recon, swap `sonnet` → `opus`.

---

## 3. Narrowing the scope

Both commands accept a scope argument — the cheapest way to control cost and context:

```
/warroom src/billing
/warroom-audit Authentication
```

---

## 4. Adding an agent to the pipeline

1. Create `agents/my-agent.md` (frontmatter with a kebab-case `name`).
2. Register the path in `.claude-plugin/plugin.json` → `agents[]`.
3. Add the `name` to the `agent` enum in `schemas/findings.schema.json`.
4. Wire it into the parallel fan-out in `commands/warroom-audit.md` (one more `Agent` call).
5. Update `docs/ARCHITECTURE.md` and the README.

> The `quality-stability-lead` must remain the **reduce** step (last), since it consolidates everything and emits
> `findings.json`.

---

## 5. Removing/shortening the pipeline

For faster audits, edit `commands/warroom-audit.md` and dispatch fewer specialists in the
fan-out. Examples of a minimal pipeline:

- **Concurrency focus:** Recon → `concurrency-specialist` → `quality-stability-lead`
- **Resilience focus:** Recon → `chaos-engineer-sre` → `quality-stability-lead`

`/warroom` on its own (Recon only) is already a minimal 1-agent pipeline for understanding a codebase.

---

## 6. Adapting the response structure

Each agent has a "Mandatory Response Structure" section with table templates. You can
add sections (e.g. "Compliance Check"), remove irrelevant ones, or change columns. **Keep the
Mermaid diagrams** and the lead's emission of `findings.json` — they are the most valuable parts.
