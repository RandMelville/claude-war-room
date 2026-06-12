# Personalização do War Room

O core dos agentes é **neutro ao domínio**. A orquestração (`commands/`) funciona para qualquer
sistema. Este guia mostra como adaptar ao seu contexto.

---

## 1. Domain Packs (em vez de find-and-replace)

No v1 você editava os agentes manualmente para reintroduzir termos de domínio. No v2, isso virou um
**domain pack**: um overlay opcional de termos, métricas de escala e regulação.

- Veja [`packs/edtech`](../packs/edtech/README.md) como exemplo e template.
- Para ativar, cole o bloco do pack no `CLAUDE.md` do repositório-alvo (ou passe como contexto ao
  rodar `/warroom` / `/warroom-audit`). Os agentes têm a diretriz de incorporar o pack ativo.

Para criar um pack novo (ex: FinTech), copie `packs/edtech/` para `packs/fintech/` e troque:

| Genérico (core)       | FinTech                         |
|-----------------------|---------------------------------|
| usuário / cliente     | operador / correntista          |
| pedido / transação    | transação financeira / boleto   |
| registro crítico      | lançamento, saldo               |
| pico de carga         | fechamento mensal               |
| PII / dados sensíveis  | dados financeiros (PCI-DSS)     |

---

## 2. Tiers de modelo

Cada agente define `model` no frontmatter. Os defaults do v2:

| Agente                    | Modelo  | Por quê                          |
|---------------------------|---------|----------------------------------|
| `recon`                   | sonnet  | Alta frequência, barato          |
| 4 especialistas + lead    | opus    | Profundidade onde importa        |

Ajuste livremente. Para reduzir custo de uma auditoria, troque `opus` → `sonnet` nos especialistas
(menor profundidade). Para máxima profundidade no Recon, troque `sonnet` → `opus`.

---

## 3. Focar o escopo

Ambos os comandos aceitam um argumento de escopo — a forma mais barata de controlar custo e contexto:

```
/warroom src/billing
/warroom-audit Autenticação
```

---

## 4. Adicionar um agente ao pipeline

1. Crie `agents/meu-agente.md` (frontmatter com `name` em kebab-case).
2. Registre o caminho em `.claude-plugin/plugin.json` → `agents[]`.
3. Adicione o `name` ao enum `agent` em `schemas/findings.schema.json`.
4. Conecte ao fan-out paralelo em `commands/warroom-audit.md` (mais uma chamada `Agent`).
5. Atualize `docs/ARCHITECTURE.md` e o README.

> O `quality-stability-lead` deve permanecer como **reduce** (último), pois consolida tudo e emite o
> `findings.json`.

---

## 5. Remover/encurtar o pipeline

Para auditorias mais rápidas, edite `commands/warroom-audit.md` e dispare menos especialistas no
fan-out. Exemplos de pipeline mínimo:

- **Foco em concorrência:** Recon → `concurrency-specialist` → `quality-stability-lead`
- **Foco em resiliência:** Recon → `chaos-engineer-sre` → `quality-stability-lead`

O `/warroom` sozinho (só Recon) já é um pipeline mínimo de 1 agente para entender um codebase.

---

## 6. Adaptar a estrutura de resposta

Cada agente tem uma seção "Estrutura Obrigatória de Resposta" com templates de tabelas. Você pode
adicionar seções (ex: "Compliance Check"), remover as irrelevantes ou alterar colunas. **Mantenha os
diagramas Mermaid** e a emissão do `findings.json` pelo lead — são as partes mais valiosas.
