---
name: Modo War Room
description: Comando interno ativado por 'ativar modo war room: [FEATURE]' — orquestra 5 agentes sequenciais para análise completa de uma feature
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

5. **[LEAD-REPORT]** → Agente: *Quality & Stability Lead (EdTech)*
   - Consolida descobertas e prioriza ações imediatas

## Regras

- Processar sequencialmente: cada agente recebe o contexto + descobertas dos anteriores
- O [LEAD-REPORT] **obrigatoriamente** encerra com relatório executivo
- **Formato do Report Final:** tabela com colunas: `Componente | Falha Detectada | Severidade (1-10) | Ação de Curto Prazo`
