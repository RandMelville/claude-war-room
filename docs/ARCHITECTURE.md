# Arquitetura do War Room

## Visão Geral

O War Room é um **plugin do Claude Code** que orquestra agentes especializados via **slash commands**. Não é um framework ou biblioteca — são arquivos de configuração (`commands/` + `agents/`) que transformam o Claude Code num pipeline de análise automatizada e **persistente** (`.warroom/`).

Dois comandos:
- `/warroom` → roda o **Recon** (engenharia reversa) e grava a doc viva.
- `/warroom-audit` → roda o War Room completo: Recon + 4 especialistas **em paralelo** + consolidação.

## Padrão de Orquestração

```mermaid
graph TD
    CMD["/warroom-audit [escopo]"] --> R[RECON — mapa do território]
    R --> A2[ARQUITETO-INFRA]
    R --> A3[DEV-CONCURRENCY]
    R --> A4[SRE-CHAOS]
    R --> A5[SEC-AUDIT]
    A2 --> L[LEAD-REPORT]
    A3 --> L
    A4 --> L
    A5 --> L
    L --> OUT[".warroom/ — architecture.md · audit/ · findings.json"]
```

### Por que map → fan-out paralelo → reduce?

A dependência real é **um-para-muitos**, não uma cadeia:

1. **Recon primeiro (map)** — Cria o mapa do território. Sem entender a arquitetura, os outros agentes não sabem o que analisar. **Todos** os especialistas dependem dele.
2. **4 especialistas em paralelo (fan-out)** — Infra, concorrência, chaos e segurança são **independentes entre si**: cada um re-analisa o mesmo mapa sob um viés próprio. Rodar em paralelo corta tempo e **evita estourar a janela de contexto** que o modo sequencial do v1 causava em codebases reais.
3. **Lead por último (reduce)** — Precisa de TODAS as descobertas para priorizar por impacto de negócio e emitir o `findings.json`.

> No v1 os 6 agentes rodavam em sequência na mesma conversa, justamente o que esgotava o contexto. O v2 troca a cadeia por um fan-out paralelo.

### Passagem de Contexto

O comando `/warroom-audit` (em `commands/warroom-audit.md`) orquestra o fluxo: lê o
`.warroom/architecture.md` produzido pelo Recon e o passa como contexto às **4 chamadas paralelas**
da ferramenta `Agent` (uma por especialista). As 4 saídas, mais o mapa, são então passadas ao
`quality-stability-lead` para consolidação.

---

## Deep Dive: Cada Agente

### Agente 1: Recon (Reverse Engineering & Software Architect)

**Arquivo:** `agents/recon.md`

**Propósito:** Criar a documentação técnica que nunca foi escrita. É o "cartógrafo" do War Room.

**Fases de execução:**
1. **Varredura e Coleta** — Lê código-fonte, migrations, configs, testes. Mapeia imports, queries, eventos.
2. **Análise e Documentação** — Gera o documento seguindo template obrigatório.

**Output obrigatório:**
- Visão Geral da Feature
- Mapeamento de Stack (tabela)
- Arquitetura de Fluxo com diagrama Mermaid (`sequenceDiagram`)
- Pontos de Integração (leitura e escrita)
- Dívida Técnica e Gargalos (tabela com severidade)
- Glossário de Regras de Negócio

**Ferramentas:** Read, Glob, Grep, Bash, Agent

**Diretrizes-chave:**
- Nunca inventa informação — se não dá para determinar pelo código, declara explicitamente
- Toda afirmação com referência `arquivo:linha`
- Diagramas Mermaid obrigatórios

---

### Agente 2: ARQUITETO-INFRA (Cloud Scalability Architect)

**Arquivo:** `agents/scalability-architect.md`

**Propósito:** Encontrar onde o sistema vai quebrar sob carga. É o "engenheiro de estresse" do War Room.

**Fases de execução:**
1. **Mapeamento de Infraestrutura** — Lê configs (application.yml, docker-compose, k8s), pools de conexão, timeouts.
2. **Análise de Gargalos** — Para cada gargalo: carga estimada vs limite, ponto de ruptura, efeito cascata.
3. **Entrega** — Inventário + simulação de carga.

**Output obrigatório:**
- Resumo Executivo com classificação (Crítico/Preocupante/Adequado)
- Mapa de Fluxo com Gargalos (diagrama Mermaid com anotações de bottleneck)
- Inventário de Gargalos (tabela)
- Análise Detalhada por Gargalo
- Simulação de Carga com 1.000 acessos simultâneos (tabela)
- Plano de Ação para Escalar (P0/P1/P2)

**Métrica-chave:** Sempre simula com 1.000 acessos simultâneos (customizável).

---

### Agente 3: DEV-CONCURRENCY (Concurrency & Distributed Systems Specialist)

**Arquivo:** `agents/concurrency-specialist.md`

**Propósito:** Caçar race conditions e deadlocks antes que eles corrompam dados. É o "paranóico de dados" do War Room.

**Fases de execução:**
1. **Mapeamento de Pontos de Escrita** — Identifica INSERT/UPDATE/DELETE, endpoints que disparam escritas, múltiplos caminhos para o mesmo registro.
2. **Análise de Concorrência** — Simula mentalmente 2 requests simultâneos em cada ponto de escrita.
3. **Entrega** — Cenários de race condition + recomendações de locking.

**Output obrigatório:**
- Resumo de Risco (Alto/Médio/Baixo)
- Mapa de Pontos de Escrita (diagrama Mermaid)
- Análise de Race Conditions com sequências temporais (T1, T2)
- Análise de Transações (nível de isolamento atual vs recomendado)
- Análise de Deadlocks
- Recomendações de Locking (Optimistic vs Pessimistic com justificativa)
- Checklist de Idempotência

**Diferencial:** Simula cenários com diagramas temporais mostrando exatamente como o dado se corrompe.

---

### Agente 4: SRE-CHAOS (Chaos Engineer SRE)

**Arquivo:** `agents/chaos-engineer-sre.md`

**Propósito:** Simular o pior dia possível. É o "pessimista profissional" do War Room.

**Fases de execução:**
1. **Mapeamento de Superfície de Falha** — Chamadas externas, processos longos, configs de timeout/retry/circuit breaker.
2. **Simulação de Desastres** — Para cada ponto: o que acontece imediatamente, após 5 min, quando volta.
3. **Entrega** — Catálogo de desastres + plano de resiliência.

**Output obrigatório:**
- Veredito de Resiliência (Frágil/Parcialmente Resiliente/Resiliente)
- Mapa de Superfície de Falha (diagrama Mermaid)
- Catálogo de Cenários de Desastre (com sequência temporal T+0, T+30s, T+5min)
- Análise de Timeouts e Retries (tabela)
- Análise de Processos Longos
- Plano de Resiliência (P0/P1/P2)

**Diferencial:** Apresenta cada cenário com blast radius e sequência temporal de degradação.

---

### Agente 5: SEC-AUDIT (Security Auditor)

**Arquivo:** `agents/security-auditor.md`

**Propósito:** Encontrar vulnerabilidades exploráveis antes que um atacante as encontre. É o "hacker ético" do War Room.

**Fases de execução:**
1. **Reconhecimento de Superfície de Ataque** — Usa o mapa do Recon para identificar pontos de entrada, fluxos de auth e dados sensíveis.
2. **Análise de Vulnerabilidades** — Para cada ponto de entrada: validação de input, verificação de autorização, criptografia de dados, vazamento de informações em erros.
3. **Entrega** — Catálogo de vulnerabilidades com vetores de ataque e plano de remediação.

**Output obrigatório:**
- Veredito de Segurança (Crítico/Atenção/Seguro)
- Mapa de Superfície de Ataque (diagrama Mermaid)
- Catálogo de Vulnerabilidades (tabela OWASP + vetor de ataque passo a passo + código vulnerável + correção)
- Análise de Autenticação e Autorização (endpoint × checks)
- Auditoria de Secrets e Configuração (tabela de itens expostos)
- Análise de Dependências (CVEs conhecidas)
- Plano de Remediação (P0/P1/P2 com impacto LGPD)

**Diferencial:** Apresenta cada vulnerabilidade com vetor de ataque passo a passo e código corrigido, e destaca implicações LGPD para dados de menores.

---

### Agente 6: LEAD-REPORT (Quality & Stability Lead)

**Arquivo:** `agents/quality-stability-lead.md`

**Propósito:** Traduzir tudo para linguagem de negócio e priorizar por impacto. É o "tradutor" do War Room.

**Fases de execução:**
1. **Coleta de Evidências** — Lê as análises de todos os agentes anteriores.
2. **Priorização por Impacto** — Classifica por: perda de dados > indisponibilidade > degradação > dívida técnica.
3. **Entrega** — Report de Confiança com plano de ação.

**Output obrigatório:**
- Report de Confiança (Índice: Baixo/Moderado/Alto)
- Resumo Executivo (2-3 frases para não-técnicos)
- Tabela de Severidade (problema em linguagem de negócio + risco técnico)
- Detalhamento por Problema (o que o usuário vê, o que acontece por baixo, correção)
- Plano de Ação Imediato (Esta semana / 2 semanas / Próximo sprint)
- Métricas de Acompanhamento
- Riscos de Não Agir

**Contrato final:** Tabela obrigatória com colunas:
`Componente | Falha Detectada | Severidade (1-10) | Ação de Curto Prazo`

---

## Ferramentas Utilizadas

Todos os agentes usam o mesmo conjunto de ferramentas:

| Ferramenta | Uso no War Room |
|-----------|-----------------|
| **Read** | Ler arquivos de código, configs, migrations |
| **Glob** | Encontrar arquivos por padrão (ex: `**/*.kt`, `**/application.yml`) |
| **Grep** | Buscar padrões no código (ex: `@Transactional`, `SELECT FOR UPDATE`) |
| **Bash** | Executar comandos do sistema (ex: verificar versões, listar estrutura) |
| **Agent** | Delegar sub-tarefas para exploração mais profunda |

---

## Limitações Conhecidas

1. **Contexto** — O fan-out paralelo alivia muito o estouro de contexto do v1, mas codebases gigantes ainda se beneficiam de focar com o argumento de escopo (ex: `/warroom-audit src/billing`).
2. **Modelo** — O **Recon** usa `model: sonnet` (barato, alta frequência); os 4 especialistas e o Lead usam `model: opus` (profundidade onde importa). Ajustável no frontmatter de cada agente.
3. **Leitura estática** — Os agentes analisam código estático. Não executam testes, não acessam banco em produção, não fazem profiling real.
4. **Achados não verificados** — Na v2.0 os achados saem com `verified: false`. A verificação adversarial que mata falso-positivo chega na v2.1.
5. **Domínio** — O core é neutro ao domínio. Para reintroduzir vocabulário específico, use um domain pack (ex: [`packs/edtech`](../packs/edtech/README.md)). Veja também [CUSTOMIZATION.md](CUSTOMIZATION.md).
