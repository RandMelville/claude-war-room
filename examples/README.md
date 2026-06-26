# Exemplos

Esta pasta contém saídas do War Room para você ver **o que recebe** antes de instalar.

## `solidus-checkout/` ⭐ exemplo real

Saída **real** do War Room completo (`/warroom` + `/warroom-audit`) sobre o módulo de pedidos/checkout
do [Solidus](https://github.com/solidusio/solidus) (e-commerce Rails OSS, commit `8d781ac`). 31
arquivos analisados, **36 achados** consolidados (Índice de Confiança 🔴 Baixo), toda afirmação com
evidência `arquivo:linha`. É o melhor lugar para ver o nível de profundidade que o War Room entrega
num codebase de verdade — veja [`solidus-checkout/README.md`](solidus-checkout/README.md).

## `sample-orders/`

> ⚠️ **Exemplo ilustrativo** (sintético, sistema de pedidos fictício) — serve para demonstrar o
> **formato** dos artefatos e como fixture de validação de schema na CI. Não é a auditoria de um
> repositório real. Para um caso real, veja `solidus-checkout/` acima.

```
sample-orders/.warroom/
├── architecture.md   # saída do /warroom (Recon)
├── manifest.json     # valida contra schemas/manifest.schema.json
├── findings.json     # valida contra schemas/findings.schema.json
└── audit/
    └── 06-report.md  # Report de Confiança (trecho)
```

## Gerar um exemplo real

Com o plugin instalado, dentro de qualquer repositório:

```
/warroom            # gera .warroom/architecture.md + manifest.json
/warroom-audit      # gera .warroom/findings.json + audit/*.md
```

Depois é só copiar o `.warroom/` resultante para cá (anonimizando o que for sensível) e abrir um PR.
