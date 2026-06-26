# Exemplo real — Solidus (checkout/pedidos)

Saída **real** do War Room rodando sobre um codebase OSS de verdade: o módulo de pedidos/checkout do
[Solidus](https://github.com/solidusio/solidus) (e-commerce em Ruby on Rails).

| | |
|---|---|
| **Repositório** | github.com/solidusio/solidus |
| **Commit** | `8d781ac` (2026-06-09) |
| **Versão** | Solidus `4.8.0.dev` · Rails `>= 7.2` |
| **Escopo** | `core/app/models/spree/order*` + state machines + payment/inventory |
| **Comandos** | `/warroom` (Recon, `sonnet`) + `/warroom-audit` (4 especialistas em paralelo + Lead, `opus`) |
| **Arquivos analisados** | 31 (todos verificados — nenhum caminho inventado) |
| **Índice de Confiança** | 🔴 **Baixo** — 36 achados (5 críticos, 8 altos, 20 médios, 3 baixos) |

```
solidus-checkout/.warroom/
├── architecture.md       # doc viva do Recon (fluxo, stack, regras de negócio, minas terrestres)
├── manifest.json         # 31 arquivos + sha256 no commit acima (base de drift)
├── findings.json         # 36 achados estruturados (data model do dashboard/SaaS)
└── audit/
    ├── 02-scalability.md  # Scalability Architect
    ├── 03-concurrency.md  # Concurrency Specialist
    ├── 04-chaos.md        # Chaos Engineer / SRE
    ├── 05-security.md     # Security Auditor
    └── 06-report.md       # Report de Confiança (Quality & Stability Lead)
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

Algumas das **minas terrestres** encontradas (ver `architecture.md` §5):

- **CRÍTICA** — `use_transactions: false` na state machine: callback de transição que falha no meio
  deixa o pedido inconsistente, sem rollback (`state_machines/order/class_methods.rb:38`).
- **ALTA** — janela de race no `OrderMutex`: locks expirados são deletados antes do `create!`, então
  dois processos podem readquirir o mesmo lock (`order_mutex.rb:19,22`).
- **ALTA** — TOCTOU de estoque: `OrderInventory#verify` lê a quantidade e escreve sem lock entre
  check e use (`order_inventory.rb:22-37`).
- **ALTA** — cascata de recálculo: todo `Payment#save` dispara `order.recalculate` → `order.save!`,
  O(n) por pedido (`payment.rb:31`).

> Reproduza você mesmo: `git clone --depth 1 https://github.com/solidusio/solidus`, instale o plugin
> e rode `/warroom core/app/models/spree`. (Os hashes do `manifest.json` batem com o commit `8d781ac`.)
