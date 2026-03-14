# Personalização do War Room

Os agentes vêm configurados para o domínio **EdTech** (plataformas educacionais), mas a estratégia de orquestração funciona para qualquer sistema de software. Este guia explica como adaptar para o seu contexto.

---

## 1. Substituição de Termos de Domínio

Os agentes usam termos EdTech em suas análises. Para adaptar, faça find-and-replace nos arquivos de agente:

| Termo EdTech | Substitua por (seu domínio) | Onde aparece |
|-------------|-------------------------------|--------------|
| escolas | seus clientes/organizações | Todos os agentes |
| professores | seus usuários principais | Agentes 3 e 5 |
| alunos | seus usuários secundários | Agentes 3 e 5 |
| notas | seus dados críticos | Agentes 3 e 5 |
| frequência, matrículas | seus registros transacionais | Agente 5 |
| período de provas | seu evento de pico | Agentes 4 e 5 |
| 1.000 escolas simultâneas | seu volume-alvo | Agente 2 |
| dados educacionais | dados do seu domínio | Agentes 3 e 5 |
| calendário escolar | seu calendário operacional | Agente 4 |

### Exemplo: Adaptando para FinTech

```
escolas → instituições financeiras
professores → operadores
alunos → clientes
notas → transações
período de provas → fechamento mensal
1.000 escolas → 500 bancos simultâneos
dados educacionais → dados financeiros (PCI-DSS)
```

---

## 2. Ajuste de Escala

O Agente 2 (Scalability Architect) simula carga com **1.000 acessos simultâneos**. Para ajustar:

No arquivo `agents/02-scalability-architect.md`, altere:
- Seção "Simulação de Carga (1.000 Escolas Simultâneas)" → seu volume
- Diretriz "Sempre simule escala. Pense em 1.000 escolas acessando simultaneamente." → seu cenário

---

## 3. Mudança de Modelo

Todos os agentes usam `model: opus` no frontmatter YAML. Para reduzir custo:

```yaml
# De:
model: opus

# Para:
model: sonnet
```

**Tradeoffs:**

| Aspecto | Opus | Sonnet |
|---------|------|--------|
| Profundidade de análise | Muito alta | Alta |
| Custo por agente | Alto | Médio |
| Velocidade | Mais lento | Mais rápido |
| Recomendação | Features críticas | Análises rotineiras |

Dica: Use Opus para o primeiro e último agente (DOC-REVERSE e LEAD-REPORT) e Sonnet para os intermediários.

---

## 4. Mudança do Comando de Ativação

O trigger está em `memory/feedback_war_room_mode.md`. Para mudar o comando:

```markdown
# De (português):
Quando o usuário digitar **"ativar modo war room: [NOME DA FEATURE]"**

# Para (inglês):
Quando o usuário digitar **"activate war room: [FEATURE NAME]"**
```

---

## 5. Adicionar um Agente ao Pipeline

Para adicionar um 6º agente (ex: Security Auditor):

### Passo 1: Crie o arquivo do agente

Crie `agents/06-security-auditor.md` seguindo o padrão:

```yaml
---
name: "Security Auditor"
description: "Descrição do agente..."
model: opus
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
---
```

O corpo do arquivo deve seguir a mesma estrutura dos outros agentes:
- Role
- Foco de Análise
- Protocolo de Execução (Fase 1, 2, 3)
- Estrutura Obrigatória de Resposta
- Persona e Tom de Voz
- Diretrizes Inegociáveis

### Passo 2: Atualize o trigger

Em `memory/feedback_war_room_mode.md`, adicione o novo agente na posição desejada:

```markdown
5. **[SECURITY-AUDIT]** → Agente: *Security Auditor*
   - Analisa vulnerabilidades OWASP Top 10 e conformidade

6. **[LEAD-REPORT]** → Agente: *Quality & Stability Lead (EdTech)*
   - Consolida descobertas e prioriza ações imediatas
```

**Importante:** O LEAD-REPORT deve ser sempre o **último** agente, pois consolida todas as descobertas.

### Passo 3: Instale o novo agente

```bash
cp agents/06-security-auditor.md ~/.claude/agents/
```

---

## 6. Remover um Agente do Pipeline

Para análises mais rápidas, você pode remover agentes intermediários.

### Pipeline mínimo (3 agentes):
1. DOC-REVERSE — entender o código
2. DEV-CONCURRENCY — caçar bugs de concorrência
3. LEAD-REPORT — consolidar

### Pipeline focado em resiliência (3 agentes):
1. DOC-REVERSE — entender o código
2. SRE-CHAOS — simular falhas
3. LEAD-REPORT — consolidar

Edite `memory/feedback_war_room_mode.md` removendo os agentes desnecessários.

---

## 7. Adaptando a Estrutura de Resposta

Cada agente tem uma seção "Estrutura Obrigatória de Resposta" com templates de tabelas e seções. Você pode:

- **Adicionar seções** — ex: "Compliance Check" para FinTech
- **Remover seções** — ex: "Glossário de Regras de Negócio" se não for relevante
- **Alterar tabelas** — adicionar/remover colunas conforme seu contexto

**Recomendação:** Mantenha sempre a seção de diagramas Mermaid — é a parte mais valiosa para comunicação visual.

---

## 8. Usando em Inglês

Para uma versão completa em inglês, além de traduzir os arquivos de agente, ajuste:

1. O comando de ativação no trigger
2. As seções de "Persona e Tom de Voz" (para instruir o agente a responder em inglês)
3. Os templates de resposta (headers das tabelas, nomes das seções)

Exemplo de persona adaptada:
```markdown
## Persona and Tone
- **Technical, direct, critical and highly analytical.**
- Don't sugarcoat problems. If the code is fragile, say it clearly.
- Always reference specific files and line numbers.
```
