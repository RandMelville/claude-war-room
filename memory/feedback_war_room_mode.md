---
name: Modo War Room
description: Comando interno ativado por 'ativar modo war room: [FEATURE]' — orquestra 6 agentes sequenciais para análise completa de uma feature
type: feedback
---

Quando o usuário digitar **"ativar modo war room: [NOME DA FEATURE]"**, executar o protocolo completo abaixo.

## Agentes e Ordem de Execução (sequencial)

1. **[DOC-REVERSE]** → Agente: *Reverse Engineering & Software Architect*
   - Mapeia fluxos e lógica de negócio a partir do código fornecido

2. **[ARQUITETO-INFRA]** → Agente: *Cloud Scalability Architect (EdTech)*
   - Identifica gargalos de infraestrutura, latência e limites de escala

3. **[DEV-CONCURRENCY]** → Agente: *Concurrency & Distributed Systems Specialist*
   - Analisa locks de banco de dados, threads e riscos de race condition

4. **[SRE-CHAOS]** → Agente: *Chaos Engineer SRE (EdTech)*
   - Simula falhas catastróficas e impacto de picos de carga

5. **[SEC-AUDIT]** → Agente: *Security Auditor (EdTech)*
   - Audita vulnerabilidades OWASP Top 10, secrets expostos, falhas de autenticação/autorização e conformidade LGPD

6. **[LEAD-REPORT]** → Agente: *Quality & Stability Lead (EdTech)*
   - Consolida descobertas e prioriza ações imediatas

## Regras

- Processar sequencialmente: cada agente recebe o contexto + descobertas dos anteriores
- O [LEAD-REPORT] **obrigatoriamente** encerra com relatório executivo
- **Formato do Report Final:** tabela com colunas: `Componente | Falha Detectada | Severidade (1-10) | Ação de Curto Prazo`
- **Gerar documentos automaticamente ao final:** Após o último agente (LEAD-REPORT), criar pasta `war-room/[nome-da-feature]/` no diretório de trabalho e salvar 6 arquivos Markdown:
  1. `01-doc-reverse-arquitetura.md` — Spec de arquitetura com diagramas Mermaid
  2. `02-arquiteto-infra-escalabilidade.md` — Relatório de escalabilidade e gargalos
  3. `03-dev-concurrency-race-conditions.md` — Análise de concorrência e race conditions
  4. `04-sre-chaos-cenarios-desastre.md` — Cenários de desastre e resiliência
  5. `05-sec-audit-seguranca.md` — Auditoria de segurança e vulnerabilidades
  6. `06-lead-report-relatorio-executivo.md` — Relatório executivo consolidado
