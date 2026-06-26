# Exemplo real — Solidus (checkout/pedidos)

Saída **real** do War Room rodando sobre um codebase OSS de verdade: o módulo de pedidos/checkout do
[Solidus](https://github.com/solidusio/solidus) (e-commerce em Ruby on Rails).

| | |
|---|---|
| **Repositório** | github.com/solidusio/solidus |
| **Commit** | `8d781ac` (2026-06-09) |
| **Versão** | Solidus `4.8.0.dev` · Rails `>= 7.2` |
| **Escopo** | `core/app/models/spree/order*` + state machines + payment/inventory |
| **Comandos** | `/warroom` (Recon, `sonnet`) + `/warroom-audit` (4 especialistas em paralelo + Lead + verificação adversarial, `opus`) |
| **Arquivos analisados** | 31 (todos verificados — nenhum caminho inventado) |
| **Índice de Confiança** | 🟡 **Moderado** — recalibrado pela verificação adversarial (v2.1), era 🔴 Baixo |
| **Achados** | 36 brutos → **27 confirmados** · 9 falsos positivos (0 críticos sobrevivem; 2 altos) |

```
solidus-checkout/.warroom/
├── architecture.md       # doc viva do Recon (fluxo, stack, regras de negócio, minas terrestres)
├── manifest.json         # 31 arquivos + sha256 no commit acima (base de drift)
├── findings.json         # 36 achados c/ verified/severity/verification_note (data model do dashboard/SaaS)
└── audit/
    ├── 02-scalability.md  # Scalability Architect
    ├── 03-concurrency.md  # Concurrency Specialist
    ├── 04-chaos.md        # Chaos Engineer / SRE
    ├── 05-security.md     # Security Auditor
    ├── 06-report.md       # Report de Confiança (Quality & Stability Lead)
    └── 07-verification.md # Verificação adversarial (v2.1): 27 confirmados, 9 falsos positivos
```

> **Map → fan-out paralelo → reduce:** o Recon mapeou; 4 especialistas auditaram o mesmo mapa em
> paralelo (cada um com um viés); o Lead consolidou em linguagem de negócio + `findings.json`. O tema
> dominante atravessa 3 agentes: gateway de pagamento **sem timeout** + lock que **expira em 120s** +
> state machine `use_transactions:false` formam a cadeia "**cobra o cliente e não conclui o pedido /
> cobra duas vezes**" — o pior cenário do checkout.

## Por que este exemplo

O checkout do Solidus é um caso-escola de **sistema legado transacional**: state machine sem
transações (`use_transactions: false`), lock de concorrência caseiro (`order_mutex`), cascata de
callbacks que recalculam o pedido a cada `save`, e dados de pagamento. O Recon mapeou tudo isso a
partir do código, com evidência `arquivo:linha` para cada afirmação.

As **minas terrestres que sobreviveram à verificação adversarial** (os achados confirmados mais
graves — ver [`audit/07-verification.md`](.warroom/audit/07-verification.md)):

- **ALTA (8)** — expiração do `OrderMutex` a 120s permite reprocessar o mesmo pedido sem idempotency
  key → cobrança dupla quando o gateway pendura >120s (`order_mutex.rb:19`; `app_configuration.rb:214`).
- **ALTA (7)** — `use_transactions: false` + `finalize` multi-tabela sem transação: falha pós-pagamento
  deixa o pedido não-atômico, sem rollback (`state_machines/order/class_methods.rb:38`; `order.rb:758`).
- **MÉDIA (6)** — pagamento órfão preso em `:processing` sem job de reconciliação (`processing.rb:40,168`).
- **MÉDIA (6)** — double-spend de store credit entre dois pedidos do mesmo usuário (mutex é por
  `order_id`, não trava a linha do crédito) (`store_credit.rb:59-118`; `order.rb:594-610`).

> 🔬 **O que a verificação derrubou:** o "oversell por TOCTOU" foi **refutado** (a validação
> `count_on_hand >= 0` roda sob `with_lock` e levanta exceção em vez de vender negativo), e a "cascata
> de recálculo" caiu (o guard `if completed?` em `payment.rb:202` bloqueia o recálculo no carrinho).
> Esse é o ponto do verificador: separar a manchete assustadora do risco real.

> Reproduza você mesmo: `git clone --depth 1 https://github.com/solidusio/solidus`, instale o plugin
> e rode `/warroom-audit core/app/models/spree`. (Os hashes do `manifest.json` batem com o commit `8d781ac`.)
