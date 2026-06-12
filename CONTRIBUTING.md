# Guia de Contribuição

Obrigado pelo interesse em contribuir com o Claude War Room! Este guia explica como participar do projeto.

---

## Primeiros Passos

1. **Fork** o repositório
2. **Clone** seu fork:
   ```bash
   git clone https://github.com/SEU_USUARIO/claude-war-room.git
   cd claude-war-room
   ```
3. **Crie uma branch** para sua mudança:
   ```bash
   git checkout -b feat/meu-novo-agente
   ```

---

## Estrutura de um Agente

Todo agente deve seguir esta estrutura no arquivo `.md`:

### Frontmatter YAML (obrigatório)

```yaml
---
name: meu-agente
description: "Descrição curta do que o agente faz. Usado pelo Claude Code para decidir quando invocar."
model: opus
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
---
```

**Campos obrigatórios:**
- `name` — slug **kebab-case** (deve casar com o nome usado em `commands/` e no enum de `agent` em `schemas/findings.schema.json`)
- `description` — O que faz e quando usar (o Claude Code usa isso para routing)
- `model` — `opus`, `sonnet` ou `haiku` (Recon usa `sonnet`; especialistas usam `opus`)
- `tools` — Lista de ferramentas que o agente pode usar

### Corpo do Agente (obrigatório)

Seções que todo agente deve ter:

```markdown
# Título do Agente

## Role
{Quem é o agente e qual sua especialidade}

## Foco de Análise
{Lista numerada dos pontos de atenção}

## Protocolo de Execução
### Fase 1: {Nome}
### Fase 2: {Nome}
### Fase 3: Entrega

## Estrutura Obrigatória de Resposta
{Template entre ``` com as seções exatas que o agente deve produzir}

## Persona e Tom de Voz
{Como o agente se comunica}

## Diretrizes Inegociáveis
{Regras que o agente nunca deve quebrar}
```

### Convenções

- **Diagramas Mermaid obrigatórios** na estrutura de resposta
- **Tabelas** para dados estruturados (gargalos, riscos, ações)
- **Referências a arquivo:linha** sempre que afirmar algo sobre código
- **Última diretriz** deve ser: "Respeite o CLAUDE.md do repositório sendo analisado, se existir."

---

## Como Testar um Agente

1. Instale o plugin a partir do seu checkout local (use o caminho do seu fork como marketplace):
   ```
   /plugin marketplace add /caminho/para/seu/claude-war-room
   /plugin install claude-war-room
   ```

2. Abra o Claude Code em um projeto real:
   ```bash
   cd /caminho/do/projeto
   claude
   ```

3. Invoque o agente diretamente (sem o War Room completo):
   - O Claude Code vai usar o agente automaticamente quando a descrição casar com a tarefa
   - Ou mencione explicitamente: "Use o agente [Nome] para analisar..."

4. Verifique:
   - O agente segue o protocolo de fases?
   - O output segue a estrutura obrigatória?
   - Os diagramas Mermaid renderizam corretamente?
   - As referências a arquivo:linha estão corretas?

---

## Se For Adicionar ao Pipeline

Se o agente deve fazer parte do fluxo War Room:

1. **Crie** `agents/meu-agente.md` com `name` em kebab-case.
2. **Registre** o caminho em `.claude-plugin/plugin.json` no array `agents[]`.
3. **Adicione** o `name` ao enum `agent` em `schemas/findings.schema.json`.
4. **Conecte** ao fan-out em `commands/warroom-audit.md` (mais uma chamada `Agent` paralela).
5. **Atualize** docs: `docs/ARCHITECTURE.md` e o README.

---

## Convenções de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: adiciona agente Security Auditor ao pipeline
fix: corrige validação de frontmatter no CI
docs: atualiza exemplos de saída do SRE-CHAOS
chore: atualiza markdownlint config
```

**Tipos:**
- `feat` — Novo agente, nova funcionalidade
- `fix` — Correção de bug
- `docs` — Apenas documentação
- `chore` — CI, configs, manutenção
- `refactor` — Reestruturação sem mudar comportamento

---

## Processo de Pull Request

1. Faça suas mudanças na branch
2. Rode o lint localmente (se possível):
   ```bash
   # Markdown lint
   npx markdownlint-cli2 "**/*.md"

   # ShellCheck
   shellcheck install.sh
   ```
3. Abra um PR para `main`
4. Preencha o template do PR
5. Aguarde review e CI passar

---

## O que NÃO fazer

- Não remova agentes do pipeline sem discussão (abra uma issue antes)
- Não renomeie os slash commands (`/warroom`, `/warroom-audit`) sem consenso
- Não adicione dependências externas ao runtime (o plugin é zero-dependency)
- Não inclua dados reais de projetos nos exemplos
- Não faça push direto para `main` (use PR)

---

## Ideias de Contribuição

- Criar **domain packs** novos (`packs/fintech`, `packs/healthtech`, …)
- Criar agentes novos (Performance Profiler, Accessibility Auditor)
- Adicionar exemplos reais (anonimizados) em `examples/`
- Melhorar templates de output dos agentes
- Trabalhar nos itens do roadmap (v2.1: verificador adversarial, rubrica de severidade, eval harness)
