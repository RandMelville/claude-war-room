# War Room Output Examples

To see the **full artifacts** of a run, open the example committed to the repository:

➡️ [`examples/sample-orders/.warroom/`](../examples/sample-orders/.warroom/)

```
examples/sample-orders/.warroom/
├── architecture.md     # output of /warroom (Recon)
├── manifest.json       # analyzed files + hashes + commit
├── findings.json       # structured findings (severity, evidence, status)
└── audit/06-report.md  # consolidated Confidence Report
```

> The example is **illustrative** (a synthetic orders system) — it's there to show the format. Generate a real
> example by pointing the plugin at any repository.

---

## How to generate

```
/warroom                       # Recon: living documentation + manifest
/warroom-audit                 # full War Room: findings + audit/*
/warroom-audit Authentication  # focusing on a feature
```

---

## What each agent produces (summary)

| Agent | Deliverable | Highlight |
|--------|-----------|----------|
| **Recon** | `architecture.md` | Stack, flow with Mermaid diagram, business rules, landmines |
| **Scalability Architect** | Bottleneck inventory | Breaking point + load simulation |
| **Concurrency Specialist** | Write map | Race conditions with temporal sequence (T1, T2) |
| **Chaos Engineer / SRE** | Disaster catalog | Failure sequence (T+0, T+30s, T+5min) + resilience plan |
| **Security Auditor** | Vulnerability catalog | OWASP + step-by-step attack vector + fix |
| **Quality & Stability Lead** | Confidence Report + `findings.json` | Business translation + prioritized action plan |

Each finding becomes a structured entry in `findings.json` (id, agent, severity 1-10, evidence
`file:line`, status), ready to be consumed by dashboards and portfolio views (roadmap).

---

## HTML Report (optional)

You can still generate a navigable HTML report from the generated Markdown:

```bash
./generate-report.sh .warroom/audit/
```
