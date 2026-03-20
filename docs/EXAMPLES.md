# Exemplos de Saída do War Room

Este documento mostra exemplos abreviados do que cada agente produz durante uma execução do Modo War Room. Os exemplos são baseados em uma feature fictícia de **"Lançamento de Notas"** em uma plataforma educacional.

---

## Comando de Ativação

```
ativar modo war room: Sistema de Lançamento de Notas
```

---

## Agente 1: DOC-REVERSE (Engenharia Reversa)

### Saída resumida:

> ## 1. Visão Geral da Feature
>
> O Sistema de Lançamento de Notas permite que professores registrem notas de alunos por turma e disciplina. Suporta lançamento manual (formulário) e importação em massa via CSV. As notas são persistidas no PostgreSQL e propagadas via Kafka para o serviço de boletins.
>
> ## 2. Mapeamento de Stack
>
> | Camada | Tecnologia | Versão | Observação |
> |--------|-----------|--------|------------|
> | Linguagem | Kotlin | 1.9 | JVM 17 |
> | Framework | Spring Boot | 3.2 | WebFlux (reativo) |
> | Banco | PostgreSQL | 15 | RDS na AWS |
> | Mensageria | Kafka | 3.5 | Tópico: `notas.lancadas` |
>
> ## 3. Arquitetura de Fluxo
>
> ```mermaid
> sequenceDiagram
>     participant P as Professor
>     participant FE as Frontend
>     participant BFF as BFF (Node)
>     participant API as Notas API (Kotlin)
>     participant DB as PostgreSQL
>     participant K as Kafka
>
>     P->>FE: Preenche notas da turma
>     FE->>BFF: POST /bff/notas
>     BFF->>API: POST /api/v1/notas/batch
>     API->>DB: INSERT INTO nota_aluno (batch)
>     API->>K: Publish notas.lancadas
> ```
>
> ## 5. Dívida Técnica
>
> | # | Tipo | Localização | Severidade | Descrição |
> |---|------|-------------|------------|-----------|
> | 1 | Sem paginação | NotaController.kt:45 | Alta | GET /notas retorna todas as notas sem limite |
> | 2 | Import sem streaming | CsvImportService.kt:23 | Crítica | CSV inteiro carregado em memória |

---

## Agente 2: ARQUITETO-INFRA (Escalabilidade)

### Saída resumida:

> ## 1. Resumo Executivo
>
> Escalabilidade classificada como 🟡 **Preocupante**. O pool de conexões está subdimensionado para o volume esperado em período de provas.
>
> ## 3. Inventário de Gargalos
>
> | # | Gargalo | Localização | Limite Atual | Ponto de Ruptura | Severidade |
> |---|---------|-------------|-------------|------------------|------------|
> | 1 | Pool de conexões | application.yml:12 | 10 conexões | ~50 req/s | Crítico |
> | 2 | Import CSV in-memory | CsvImportService.kt:23 | ~256MB heap | Arquivo >20k linhas | Crítico |
> | 3 | Kafka producer síncrono | NotaEventPublisher.kt:15 | Bloqueante | Kafka indisponível | Alto |
>
> ## 5. Simulação de Carga (1.000 Escolas)
>
> | Recurso | Demanda Estimada | Capacidade Atual | Status |
> |---------|-----------------|------------------|--------|
> | Conexões DB | ~200 simultâneas | 10 (pool) | 🔴 |
> | Memória | ~2GB (CSVs) | 512MB (heap) | 🔴 |
> | Throughput API | ~500 req/s | ~100 req/s | 🟡 |

---

## Agente 3: DEV-CONCURRENCY (Concorrência)

### Saída resumida:

> ## 1. Resumo de Risco de Concorrência
>
> Risco global: 🔴 **Alto**. Identificados 2 cenários de race condition com potencial de perda de dados.
>
> ## 3. Análise de Race Conditions
>
> | # | Cenário | Endpoints | Registro | Risco |
> |---|---------|-----------|----------|-------|
> | 1 | Dois professores editam nota do mesmo aluno | PUT /notas/:id | nota_aluno | 🔴 Crítico |
> | 2 | Import CSV + edição manual simultânea | POST /import + PUT /notas | nota_aluno | 🔴 Crítico |
>
> ### Detalhamento do Cenário #1
>
> ```
> T1: READ nota (valor=8.0)     → processa → WRITE nota (valor=9.0)
> T2:     READ nota (valor=8.0) → processa →     WRITE nota (valor=7.5)
> Resultado: nota=7.5 (update de T1 perdido — Lost Update)
> ```
>
> **Causa raiz:** UPDATE sem versioning. Não há @Version na entidade NotaAluno.
>
> ## 6. Recomendações de Locking
>
> | Problema | Estratégia | Justificativa |
> |----------|-----------|---------------|
> | Lost Update em nota | Optimistic Locking (@Version) | Conflito raro (~2 profs/turma), retry automático |

---

## Agente 4: SRE-CHAOS (Chaos Engineering)

### Saída resumida:

> ## 1. Veredito de Resiliência
>
> Classificação: 🔴 **Frágil**
>
> **Pior cenário identificado:** Kafka indisponível durante período de lançamento de notas causa perda silenciosa de eventos, resultando em boletins desatualizados.
>
> ## 3. Catálogo de Cenários de Desastre
>
> ### Cenário #1: Kafka Indisponível
>
> | Atributo | Detalhe |
> |----------|---------|
> | **Gatilho** | Broker Kafka fica indisponível |
> | **Probabilidade** | Média |
> | **Impacto** | Boletins não são atualizados |
> | **Blast Radius** | 100% das escolas |
>
> **Sequência de falha:**
> 1. **T+0s** — Professor lança nota, nota é salva no DB com sucesso
> 2. **T+0.1s** — Publish no Kafka falha, exceção logada mas não propagada
> 3. **T+5min** — Múltiplas notas lançadas, nenhuma refletida nos boletins
> 4. **T+1h** — Coordenadores reportam boletins desatualizados
>
> ## 4. Análise de Timeouts e Retries
>
> | Chamada | Timeout Atual | Timeout Ideal | Retry? | Circuit Breaker? |
> |---------|--------------|---------------|--------|------------------|
> | Kafka publish | Nenhum | 5s | Não | Não |
> | PostgreSQL query | 30s (default) | 5s | Não | Não |
> | BFF → API | 60s | 10s | Não | Não |

---

## Agente 5: SEC-AUDIT (Segurança)

### Saída resumida:

> ## 1. Veredito de Segurança
>
> Classificação: 🔴 **Crítico**
>
> **Vulnerabilidade mais crítica:** IDOR no endpoint GET /notas/:id permite acesso a notas de qualquer aluno sem verificação de ownership.
> **Dados sensíveis em risco:** PII de menores (nomes, notas acadêmicas), credenciais de professores.
>
> ## 3. Catálogo de Vulnerabilidades
>
> ### Vulnerabilidade #1: IDOR em Notas de Alunos
>
> | Atributo               | Detalhe                                          |
> |------------------------|--------------------------------------------------|
> | **Categoria OWASP**    | A01:2021 - Broken Access Control                 |
> | **Severidade**         | Crítica                                          |
> | **Explorabilidade**    | Fácil                                            |
> | **Impacto**            | Acesso a notas de qualquer aluno                 |
> | **Dados em Risco**     | PII de menores, notas acadêmicas                 |
> | **LGPD Relevante?**    | Sim — dados de menores (Art. 14)                 |
> | **Evidência no código**| NotaController.kt:32                             |
>
> **Vetor de ataque:**
> 1. Professor autenticado acessa GET /api/v1/notas/123
> 2. Altera o ID para GET /api/v1/notas/456 (aluno de outra turma)
> 3. Recebe notas de aluno que não é seu — sem verificação de ownership
>
> ### Vulnerabilidade #2: Kafka Credentials Hardcoded
>
> | Atributo               | Detalhe                                          |
> |------------------------|--------------------------------------------------|
> | **Categoria OWASP**    | A07:2021 - Identification and Authentication     |
> | **Severidade**         | Alta                                             |
> | **Evidência no código**| application.yml:28                               |
>
> ## 4. Análise de Autenticação e Autorização
>
> | Endpoint              | Autenticação | Autorização (Role) | Ownership Check | Rate Limit |
> |-----------------------|--------------|--------------------|-----------------|-----------:|
> | GET /notas/:id        | JWT          | Não tem!           | Não tem!        | Não        |
> | POST /notas/batch     | JWT          | PROFESSOR          | Por turma       | Não        |
> | POST /import/csv      | JWT          | COORDENADOR        | Por escola      | Não        |
>
> ## 7. Plano de Remediação
>
> | Prioridade | Vulnerabilidade         | Correção                           | Esforço | Impacto LGPD |
> |------------|------------------------|------------------------------------|---------|--------------|
> | P0         | IDOR em notas          | Adicionar ownership check por turma| Baixo   | Sim          |
> | P0         | Credentials hardcoded  | Mover para env vars/secrets manager| Baixo   | Não          |
> | P1         | Sem rate limiting      | Adicionar rate limiter por IP/user | Médio   | Não          |

---

## Agente 6: LEAD-REPORT (Relatório Final)

### Saída completa (formato do report final):

> ## Report de Confiança do Sistema
>
> **Data:** 2026-03-13
> **Feature analisada:** Sistema de Lançamento de Notas
> **Índice de Confiança:** 🔴 Baixo
>
> ### Resumo Executivo
>
> O sistema de lançamento de notas pode **perder dados quando dois professores editam ao mesmo tempo**. Importações de CSV acima de 20.000 linhas podem **travar o servidor**. Quando o Kafka fica indisponível, os **boletins ficam desatualizados sem alerta**. Recomendamos correção imediata de 3 itens antes do próximo período de provas.
>
> ---
>
> ## Tabela de Severidade
>
> | Componente | Falha Detectada | Severidade (1-10) | Ação de Curto Prazo |
> |------------|-----------------|-------------------|---------------------|
> | Serviço de Notas | Race condition — notas podem ser perdidas quando 2 professores editam | 9 | Adicionar @Version (optimistic locking) na entidade NotaAluno |
> | Import CSV | Estouro de memória com arquivos >20k linhas | 8 | Implementar leitura com streaming (BufferedReader) |
> | Kafka Publisher | Falha silenciosa — boletins ficam desatualizados | 8 | Adicionar retry com DLQ (Dead Letter Queue) |
> | Pool de Conexões | 10 conexões para 1.000 escolas | 7 | Aumentar pool para 50 em application.yml |
> | API de Notas | GET /notas sem paginação | 6 | Adicionar paginação com limit/offset |
>
> ## Plano de Ação Imediato
>
> ### Esta semana (P0)
> | # | Ação | Responsável | Esforço | Impacto |
> |---|------|-------------|---------|---------|
> | 1 | Adicionar @Version em NotaAluno | Backend | P | Alto |
> | 2 | Aumentar pool de conexões para 50 | DevOps | P | Alto |
>
> ### Próximas 2 semanas (P1)
> | # | Ação | Responsável | Esforço | Impacto |
> |---|------|-------------|---------|---------|
> | 3 | Implementar streaming no import CSV | Backend | M | Alto |
> | 4 | Adicionar retry + DLQ no Kafka publisher | Backend | M | Alto |
>
> ## Riscos de Não Agir
>
> - Período de provas em 2 semanas — risco de perda de notas em escala
> - Coordenadores perdem confiança no sistema ao ver boletins desatualizados
> - Custo de correção pós-incidente é 10x maior que prevenção

---

## Notas sobre Qualidade da Saída

- **Especificidade do comando importa:** "Lançamento de Notas" produz resultados melhores que "o sistema todo"
- **Tamanho do codebase:** Features com 5-50 arquivos geram as melhores análises
- **Modelo:** Opus produz análises mais profundas e com mais referências a arquivo:linha
- **Tempo de execução:** Uma análise completa com 6 agentes leva de 8 a 20 minutos dependendo da complexidade
- **Report HTML:** Após a execução, use `./generate-report.sh war-room/[feature]/` para gerar um report interativo
