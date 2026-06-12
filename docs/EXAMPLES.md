# Exemplos de Saída do War Room

Para ver os **artefatos completos** de uma execução, abra o exemplo commitado no repositório:

➡️ [`examples/sample-orders/.warroom/`](../examples/sample-orders/.warroom/)

```
examples/sample-orders/.warroom/
├── architecture.md     # saída do /warroom (Recon)
├── manifest.json       # arquivos analisados + hashes + commit
├── findings.json       # achados estruturados (severidade, evidência, status)
└── audit/06-report.md  # Report de Confiança consolidado
```

> O exemplo é **ilustrativo** (sistema de pedidos sintético) — serve para mostrar o formato. Gere um
> exemplo real apontando o plugin para qualquer repositório.

---

## Como gerar

```
/warroom                       # Recon: doc viva + manifest
/warroom-audit                 # War Room completo: findings + audit/*
/warroom-audit Autenticação    # focando numa feature
```

---

## O que cada agente produz (resumo)

| Agente | Entregável | Destaque |
|--------|-----------|----------|
| **Recon** | `architecture.md` | Stack, fluxo com diagrama Mermaid, regras de negócio, minas terrestres |
| **Scalability Architect** | Inventário de gargalos | Ponto de ruptura + simulação de carga |
| **Concurrency Specialist** | Mapa de escritas | Race conditions com sequência temporal (T1, T2) |
| **Chaos Engineer / SRE** | Catálogo de desastres | Sequência de falha (T+0, T+30s, T+5min) + plano de resiliência |
| **Security Auditor** | Catálogo de vulnerabilidades | OWASP + vetor de ataque passo a passo + correção |
| **Quality & Stability Lead** | Report de Confiança + `findings.json` | Tradução para negócio + plano de ação priorizado |

Cada achado vira uma entrada estruturada em `findings.json` (id, agente, severidade 1-10, evidência
`arquivo:linha`, status), pronta para ser consumida por dashboards e visões de portfólio (roadmap).

---

## Report HTML (opcional)

Você ainda pode gerar um HTML navegável a partir dos Markdown gerados:

```bash
./generate-report.sh .warroom/audit/
```
