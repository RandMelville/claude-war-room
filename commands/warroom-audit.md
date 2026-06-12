---
description: "War Room completo — auditoria multi-agente de riscos. Reusa o mapa do Recon, roda 4 especialistas EM PARALELO (escalabilidade, concorrência, chaos/SRE, segurança), consolida no Lead e persiste findings.json + audit/*.md. Passe um caminho/feature para focar."
argument-hint: "[caminho|feature opcional]"
---

# /warroom-audit — Auditoria multi-agente (map → fan-out → reduce)

Auditoria 360° de riscos sobre o mapa do Recon. **Padrão: map → fan-out paralelo → reduce.**
Siga à risca.

## Passo 0 — Escopo, mapa e progresso

- Escopo = `$ARGUMENTS` (vazio ⇒ repo inteiro `.`).
- **Garanta o mapa do Recon:** se `.warroom/architecture.md` **não** existir, rode primeiro o
  subagente `recon` (igual ao `/warroom`) e persista `architecture.md` + `manifest.json`. Se já
  existir, reuse-o como contexto.
- Crie task list (TaskCreate): `Recon (se preciso)`, `Especialistas (paralelo)`, `Consolidação`,
  `Persistir findings`.

## Passo 1 — Fan-out PARALELO (4 especialistas)

Dispare os **4 subagentes em paralelo — emitindo as 4 chamadas da ferramenta `Agent` numa única
mensagem** (não em sequência). Cada um recebe como contexto: o conteúdo de
`.warroom/architecture.md` e o escopo.

1. `scalability-architect` — gargalos de infra e ponto de ruptura.
2. `concurrency-specialist` — race conditions, deadlocks, locking.
3. `chaos-engineer-sre` — cenários de desastre e resiliência.
4. `security-auditor` — vulnerabilidades OWASP, secrets, authz, privacidade.

> Rodar em paralelo reduz tempo e **evita estourar a janela de contexto** que o modo sequencial
> antigo causava. Eles são independentes: todos analisam o mesmo mapa.

Aguarde as 4 saídas.

## Passo 2 — Reduce (consolidação)

Invoque o subagente **`quality-stability-lead`** via `Agent`, passando como contexto **as 4 saídas
dos especialistas + o `architecture.md`**. Ele DEVE produzir:
- o **Report de Confiança** em Markdown; e
- o bloco final **`findings.json`** válido contra `schemas/findings.schema.json`.

## Passo 3 — Persistir

Na pasta `.warroom/` do repositório-alvo:
1. `audit/02-scalability.md`, `audit/03-concurrency.md`, `audit/04-chaos.md`,
   `audit/05-security.md` — uma saída por especialista.
2. `audit/06-report.md` — o Report de Confiança do Lead.
3. `findings.json` — o bloco JSON emitido pelo Lead (grave apenas o JSON, sem cercas de código).
4. Atualize `manifest.json` com `mode: "audit"` e `model: "opus"` (reaproveite a coleta de
   `commit_sha`/`generated_at`/`files` descrita em `/warroom`).

Marque as tasks conforme conclui.

## Passo 4 — Fechamento

Responda ao usuário com:
- **Índice de Confiança** (🔴/🟡/🟢) e a **Tabela de Severidade** consolidada.
- Quantidade de achados por severidade (ex: 3 críticos, 5 altos…).
- Caminho dos artefatos (`.warroom/audit/`, `.warroom/findings.json`).

## Regras

- **Paralelo de verdade:** as 4 chamadas `Agent` do Passo 1 vão na mesma mensagem.
- **findings.json é obrigatório** e deve validar contra o schema (severity inteiro 1-10, status
  `open`, verified `false`).
- A **verificação adversarial** dos achados (matar falso-positivo) chega na v2.1; por ora todos os
  achados saem com `verified: false`.
- **Respeite o CLAUDE.md** do repositório-alvo, se existir.
