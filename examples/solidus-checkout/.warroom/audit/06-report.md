<!-- Gerado por /warroom-audit — Quality & Stability Lead (opus) sobre Solidus @ 8d781ac. -->

# Report de Confiança — Módulo de Pedidos/Checkout (Solidus)

**Data:** 2026-06-25
**Sistema analisado:** `core/app/models/spree` — pedidos/checkout/pagamento (Solidus `4.8.0.dev`, commit `8d781ac`)
**Agentes consolidados:** Scalability Architect, Concurrency Specialist, Chaos Engineer/SRE, Security Auditor (sobre o mapa do Recon)
**Índice de Confiança:** 🔴 **Baixo (low)**

---

## Resumo Executivo

O caminho de pagamento do Solidus funciona muito bem no "caminho feliz", mas **não tem nenhuma defesa contra a falha mais comum de um e-commerce: o gateway de pagamento ficar lento ou cair.** Quando isso acontece, o site **inteiro** pode sair do ar (não só o checkout), e o mesmo cliente pode ser **cobrado duas vezes**. Em paralelo, o controle de estoque permite **vender produto que não existe** sob concorrência, e a ausência de transação na máquina de estados pode deixar pedidos **cobrados, mas nunca concluídos** — exigindo conciliação manual.

São **5 problemas críticos** concentrados num único núcleo transacional, e vários se **reforçam em cadeia**. A postura de **segurança**, por contraste, é madura (cartão tratado conforme PCI, autorização por ownership, anti-tampering de preço) — os achados de segurança são de severidade média/baixa. O risco dominante é de **estabilidade e integridade financeira**, não de invasão.

Por isso o Índice de Confiança é **Baixo**: os defeitos atingem o coração do negócio (dinheiro, estoque, disponibilidade), têm gatilhos de **alta probabilidade** (todo provedor de pagamento tem incidentes) e ainda **não passaram por verificação adversarial** (chega na v2.1 — ver nota final).

---

## 1. Tabela de Severidade Consolidada

Os achados mais graves, em linguagem de negócio. Severidade: 🔴 Crítico (9-10) · 🟠 Alto (7-8) · 🟡 Médio (4-6).

| # | Problema (negócio) | Risco técnico | Sev. | Quem sofre | Evidência (arquivo:linha) |
|---|---|---|---|---|---|
| CHAOS-001 | Gateway lento derruba o **site inteiro** | Chamada ao gateway sem timeout segura thread Puma + conexão DB → pool esgota em cascata (convergência chaos+scal) | 🔴 9 | 100% dos usuários | `payment/processing.rb:42-49`; `payment_method.rb:90-100` |
| CHAOS-002 | Cliente **cobrado em dobro** quando o gateway demora | Lock do pedido expira em 120s durante a request pendurada; 2ª request reprocessa sem idempotency key (convergência chaos+conc) | 🔴 9 | Clientes pagantes | `order_mutex.rb:9,19`; `app_configuration.rb:214` |
| CHAOS-003 | Cliente **cobrado sem receber o pedido** | Pagamento preso em `:processing` após crash; `return if processing?` bloqueia retry; sem job de reconciliação | 🔴 9 | Clientes pagantes | `payment/processing.rb:40,56,168` |
| CONC-002 | **Vende produto que não existe** (oversell) | TOCTOU: `fill_status` lê estoque sem lock; `with_lock` cobre só o incremento aritmético | 🔴 9 | Clientes + operação | `order_inventory.rb:76,86`; `stock_item.rb:37-44` |
| CONC-001 | Pedido **pago mas nunca concluído** (estado preso) | `use_transactions:false`: `finalize` escreve em 4+ tabelas sem rollback (convergência recon+conc+chaos) | 🔴 9 | Operação/financeiro | `state_machines/order/class_methods.rb:38`; `order.rb:758-774` |
| CHAOS-007 | Incidente do gateway **vira bola de neve** | Zero retry/backoff/circuit breaker; retry ingênuo martela provedor caído | 🟠 8 | Todos em pico | `base_job.rb:7` |
| CHAOS-004 | Checkout **quebra com 500** em timeout do gateway | `protect_from_connection_error` só captura `ConnectionError`; Timeout/SSL/Reset sobem | 🟠 8 | Clientes em checkout | `payment/processing.rb:212-216` |
| CONC-005 | Saldo de **crédito de loja gasto em dobro** | Lê `amount_remaining` e cria payment sem lock; mutex é por pedido, não por crédito | 🟠 7 | Financeiro | `order.rb:594-610` |
| CONC-006 | **Cobrança dupla** no gateway por reentrada | `process_payments!` sem idempotency key; `order.reload` descarta mudanças em memória | 🟠 7 | Clientes pagantes | `order/payments.rb:40-48`; `payment/processing.rb:116` |
| CHAOS-006 | Pedido **completa SEM pagamento** durante queda | `allow_checkout_on_gateway_error` converte erro em sucesso; sem monitor de `payment_state` | 🟠 7 | Receita | `order/payments.rb:49-52` |
| SCAL-002/003/004 | **Checkout lento** e caro sob carga | N+1 de refunds, recálculo O(n) por payment, frete recriado sem cache | 🟠 7 | Toda a base | `order_updater.rb:151,19`; `order.rb:510` |
| SEC-001 | Cobrança contra **cartão de outro cliente** | Mass-assignment de `gateway_*_profile_id`; valida só no gateway | 🟡 6 | Clientes/fraude | `permitted_attributes.rb:106-111` |

*(36 achados no total — os demais médios/baixos estão em `findings.json`.)*

---

## 2. Temas Transversais (achados que se reforçam)

A gravidade real **não está nos achados isolados, e sim em três cadeias** onde múltiplos agentes convergiram independentemente sobre o mesmo código:

### Tema A — A cadeia do gateway: "sem timeout → lock expira → cobrança dupla / pagamento órfão"

Citada por **chaos + concorrência + escalabilidade**. É a falha-mãe do módulo:

```
Gateway sem read/open-timeout (CHAOS-001 = SCAL-001)
   │  a request fica pendurada indefinidamente
   ▼
Lock do pedido expira aos 120s (CHAOS-002 = CONC-003)
   │  2ª request (retry do cliente/LB) adquire o lock
   ▼
Sem idempotency key (CONC-006)  ──►  COBRANÇA EM DOBRO
   │
   └─ se o processo morre no meio  ──►  pagamento órfão em :processing (CHAOS-003)
                                          sem job de reconciliação → dinheiro preso
   │
   └─ em paralelo, a thread/conexão presa  ──►  pool esgota  ──►  SITE INTEIRO CAI (CHAOS-001/SCAL-001)
```

Um único defeito de configuração (timeout ausente) destrava simultaneamente outage total, cobrança dupla e pagamento órfão. **É o item nº1 do plano de ação.**

### Tema B — `use_transactions:false`: atomicidade abandonada no checkout

Citado por **3 agentes** (Recon Mina #1, CONC-001, CHAOS-005). A máquina de estados desliga a transação envolvente, então `finalize` escreve em adjustments, shipments, inventário e order **sem rollback**. Qualquer falha parcial (deadlock em pico, `save!` que levanta, validação de `stock < 0`) deixa o pedido **pago mas inconsistente**. Esse tema **amplifica o Tema A**: o pagamento órfão e a cobrança dupla pioram porque o sistema não consegue desfazer o estado intermediário. Também é a raiz de SCAL-011 e do agravante de CONC-002 (o oversell levanta exceção dentro do `finalize` não-transacional).

### Tema C — Estoque e dinheiro lidos sem lock (família "read-then-act")

Um padrão repetido: **decidir com base numa leitura sem lock, depois escrever**. Aparece em CONC-002 (oversell de estoque), CONC-005 (double-spend de store credit) e CONC-007 (lost update de totais). Todos sob isolamento READ COMMITTED, sem `SELECT FOR UPDATE` nem `lock_version`. O denominador comum: **a única exclusão mútua do sistema é a tabela-mutex de aplicação, que protege por `order_id` — e portanto não protege estoque compartilhado nem o saldo de um usuário com dois carrinhos.**

### Tema D — Amplificação de carga por callbacks (custo escondido)

`Payment after_save → order.recalculate` (SCAL-003/CHAOS-011) + N+1 de refunds (SCAL-002) + frete sem cache (SCAL-004) + `order.reload` por payment (SCAL-008/CHAOS-010). Isoladamente são "lentidão"; somados, **prolongam a janela em que a conexão fica retida durante o gateway** — alimentando o Tema A. Performance aqui é uma questão de resiliência, não só de UX.

---

## 3. Plano de Ação Priorizado

### 🔴 P0 — Esta semana (parar o sangramento)

| Ação | Achados | Esforço | Impacto |
|---|---|---|---|
| Impor **read_timeout/open_timeout** no client ActiveMerchant (ex.: 8s/3s), **estritamente < 120s** do mutex | CHAOS-001, CHAOS-002, SCAL-001 | Baixo (config) | Evita outage total e fecha a janela de re-lock |
| Enviar **idempotency key** ao gateway por tentativa de cobrança | CHAOS-002, CONC-006 | Médio | Elimina cobrança em dobro |
| Ampliar `protect_from_connection_error` para Timeout/SSL/Reset/Socket | CHAOS-004 | Baixo | Evita 500 e abortos sujos no checkout |
| **Job de reconciliação** para pagamentos presos em `:processing` (gateway `inquire`/`verify`) | CHAOS-003 | Médio | Recupera dinheiro órfão; impede perda silenciosa |
| Corrigir N+1 de refunds (`payment.refunds.sum(&:amount)`) | SCAL-002 | Trivial | Encurta a transação no passo `complete` |

### 🟠 P1 — Próximas 2 semanas (integridade)

| Ação | Achados | Esforço | Impacto |
|---|---|---|---|
| **Decremento condicional atômico** de estoque (`UPDATE ... WHERE count_on_hand >= q`) | CONC-002 | Médio | Elimina oversell |
| Reativar `use_transactions:true` **ou** envolver `next!`/`finalize` em `order.with_lock` transacional | CONC-001, SCAL-011 | Médio | Atomicidade do checkout; backstop do Tema A/B |
| **Lock pessimista no store credit** ao validar/debitar saldo | CONC-005 | Baixo | Impede double-spend |
| Circuit breaker por payment method + monitor de `payment_state != paid` em pedidos completos | CHAOS-007, CHAOS-006 | Médio | Degradação graciosa; flag de "completo sem pagar" | 
| Batch do recálculo (uma vez ao fim do loop de payments) | SCAL-003, CHAOS-011 | Médio | Reduz carga e janela de conexão |
| Remover token/api_key da query string; aceitar só via header + `filter_parameters` | SEC-002 | Baixo | Para vazamento de credencial em logs |
| Remover `gateway_*_profile_id` da allowlist de não-admin; validar ownership de `wallet_payment_source_id` | SEC-001 | Médio | Fecha IDOR de meio de pagamento |

### 🟡 P2 — Próximo sprint (planejado)

| Ação | Achados | Esforço | Impacto |
|---|---|---|---|
| `lock_version` (optimistic lock) em `spree_orders` para totais | CONC-007 | Médio | Evita lost update de faturamento |
| Índice **único** em `spree_orders.number` + retry no `RecordNotUnique` | CONC-008 | Baixo | Elimina número de pedido duplicado |
| Estender transação do `OrderShipping#ship` + outbox para `carton_shipped` | CHAOS-008 | Médio | Consistência de expedição/e-mail |
| `includes(:stock_location)` + pré-carregar shipments; cache de frete/estoque com TTL curto | SCAL-005, SCAL-006, SCAL-004, SCAL-009 | Baixo/Médio | Latência e custo de infra |
| Whitelist de `ransackable_attributes` + índices no admin | SCAL-010, SEC-004 | Médio | Admin estável; reduz enumeração |
| Tornar `OrderMutex` reentrante (ou migrar para `order.with_lock`); retry com backoff no client (evitar 409) | CONC-004, SCAL-007 | Médio | Operações compostas deixam de falhar |
| Idempotência/checkpoint no `PromotionCodeBatchJob`; alertar jobs de auditoria descartados; `secure_compare` no token | CHAOS-009, CHAOS-012, SEC-003 | Baixo | Hardening geral |

---

## 4. Riscos de Não Agir

- **Próximo incidente do gateway = site fora do ar.** Provedores de pagamento têm degradações regulares; hoje qualquer uma derruba o catálogo, o login e o admin junto — não só o checkout.
- **Cobrança dupla em escala durante a Black Friday:** exatamente quando o gateway fica lento (Tema A) e o DB satura (Tema B), os dois gatilhos de cobrança em dobro e pagamento órfão ficam mais prováveis. Chargebacks e exposição PCI sobem em conjunto.
- **Oversell vira cancelamento e perda de confiança:** vender estoque inexistente gera reembolso, frustração e churn — e, pior, pode travar o `finalize` não-transacional, deixando pedidos presos.
- **Conciliação manual permanente:** sem transação nem reconciliação, o time de operações vira o "rollback humano" do sistema — custo recorrente e propenso a erro.

---

## 5. Distribuição dos Achados

| Faixa | Qtd | IDs (resumo) |
|---|---|---|
| 🔴 Crítico (9-10) | 5 | CHAOS-001, CHAOS-002, CHAOS-003, CONC-001, CONC-002 |
| 🟠 Alto (7-8) | 8 | CHAOS-004, CHAOS-006, CHAOS-007, SCAL-002, SCAL-003, SCAL-004, CONC-005, CONC-006 |
| 🟡 Médio (4-6) | 20 | SCAL-005..011, CONC-004, CONC-007..012, CHAOS-008/009/012, SEC-001/002/004 |
| 🟢 Baixo (1-3) | 3 | SEC-003, SEC-005, SEC-006 |
| **Total** | **36** | (41 achados brutos; 5 duplicatas cross-agent fundidas) |

---

> ⚠️ **Nota de verificação (v2.1).** Os achados acima foram consolidados a partir dos relatórios dos especialistas, com evidência `arquivo:linha` no código real do Solidus, mas **ainda não passaram pela verificação adversarial** (agente *verifier*, previsto para a v2.1). Todos estão marcados como `verified: false` e `status: open` em `findings.json`. Trate as severidades como **calibração inicial** e confirme, em especial, os itens cujo impacto depende de configuração do app que monta o Solidus (pool/timeout do gateway, flag `allow_checkout_on_gateway_error`) e da validação do gateway ActiveMerchant em uso (SEC-001).
