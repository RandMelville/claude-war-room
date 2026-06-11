---
description: "Recon — engenharia reversa do repositório/feature em doc viva. Mapeia stack, fluxos, regras de negócio e minas terrestres, e persiste em .warroom/ (architecture.md + manifest.json). Passe um caminho para focar (ex: /warroom src/billing) ou nada para o repositório inteiro."
argument-hint: "[caminho|feature opcional]"
---

# /warroom — Recon (doc viva de um codebase)

Você vai reconstruir contexto confiável de um repositório legado e **persistir** o resultado para
o time herdar. Siga este protocolo à risca.

## Passo 0 — Escopo e progresso

- O escopo é o argumento `$ARGUMENTS`. Se vazio, o escopo é o repositório inteiro (`.`).
- Crie uma task list visível (TaskCreate) com 3 itens: `Recon`, `Persistir doc`, `Gerar manifest`.

## Passo 1 — Rodar o Recon

Invoque o subagente **`recon`** via a ferramenta `Agent`, instruindo-o a analisar o escopo
(`$ARGUMENTS` ou o repo inteiro) e produzir o Documento de Arquitetura completo, **incluindo a
seção obrigatória "7. Arquivos Analisados"**. Aguarde o resultado.

## Passo 2 — Persistir a doc viva

1. Crie o diretório `.warroom/` na raiz do repositório-alvo (não no repo do plugin).
2. Grave a saída do Recon em `.warroom/architecture.md`.

## Passo 3 — Gerar o manifesto (base de drift)

Monte `.warroom/manifest.json` válido contra `schemas/manifest.schema.json`. Para isso, use Bash:

```bash
# commit atual (ou null se não for repo git)
COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "")
# timestamp ISO-8601 UTC
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
# hash de cada arquivo listado pelo Recon na seção "Arquivos Analisados":
shasum -a 256 <arquivo>   # use o primeiro campo (64 hex) como sha256
```

Preencha:
- `warroom_version`: `"2.0.0"`
- `generated_at`: `$TS`
- `mode`: `"recon"`
- `model`: o modelo usado pelo Recon (`"sonnet"`)
- `scope`: `$ARGUMENTS` ou `"."`
- `commit_sha`: `$COMMIT` (ou `null` se vazio)
- `files`: um objeto `{path, sha256}` para **cada** arquivo da seção "Arquivos Analisados".

Grave em `.warroom/manifest.json`. Marque as tasks como concluídas conforme avança.

## Passo 4 — Fechamento

Responda ao usuário com:
- Caminho dos artefatos gerados (`.warroom/architecture.md`, `.warroom/manifest.json`).
- 3-5 bullets com as **minas terrestres** mais relevantes encontradas pelo Recon.
- Sugestão: rode `/warroom-audit` para a auditoria multi-agente completa de riscos.

## Regras

- **Não invente** — o Recon já é instruído a só afirmar o que tem evidência `arquivo:linha`.
- **Commitável:** os artefatos em `.warroom/` foram desenhados para serem versionados pelo time.
- Se já existir `.warroom/manifest.json`, avise que está **sobrescrevendo** a análise anterior
  (na v2.2 isto vira um diff incremental via `/warroom-refresh`).
