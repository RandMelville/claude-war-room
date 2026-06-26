<!-- Gerado por /warroom-audit (passo de verificação v2.1) — Adversarial Verifier (opus) sobre Solidus @ 8d781ac.
     Cada achado foi reaberto no código real e submetido ao protocolo de refutação. -->

# Verificação Adversarial (v2.1)

O `adversarial-verifier` reabriu cada `arquivo:linha` citado no código real do Solidus e tentou
**refutar** cada um dos 36 achados. Resultado:

- **27 confirmados** · **9 falsos positivos** (refutados com evidência).
- Confirmados por faixa: **0 críticos** · **2 altos** · 13 médios · 12 baixos.
- **Índice de Confiança recalibrado: 🔴 Baixo → 🟡 Moderado.** Os 5 "críticos" do relatório bruto
  não sobreviveram: 2 foram refutados e 3 rebaixados. O pior achado confirmado é alto (não crítico).

> Por que isso importa: o relatório bruto saía com tudo `verified: false` e severidades "quentes".
> A verificação mata o falso-positivo e recalibra a severidade **antes** de qualquer humano confiar
> no número. Quando a evidência é ambígua, o verificador refuta.

## Os 9 falsos positivos (refutados)

| ID | Por que caiu (evidência) |
|----|--------------------------|
| **CONC-002** | "Oversell" barrado: `count_on_hand >= 0 unless backorderable?` roda sob `with_lock` e **levanta exceção** em vez de persistir negativo (`stock_item.rb:13,38`). O resíduo real é falha de checkout = CONC-001. |
| **CHAOS-004** | ActiveMerchant encapsula `Timeout::Error`/`Net::ReadTimeout`/`ECONNRESET`/etc. em `ConnectionError`, que o `protect_from_connection_error` **já captura** (`processing.rb:212-216`). Os erros não sobem crus. |
| **CHAOS-009** | O `BatchBuilder` retoma por `created_codes = promotion_codes.count` (checkpoint) e deduplica via `rescue RecordInvalid` (`batch_builder.rb:35-53`) — o retry **não** re-roda do zero nem duplica. |
| **CONC-010** | `ensure_promotions_eligible` roda o adjuster com `persist:false` como **revalidação** — não aplica nem persiste desconto (`order.rb:808-817`). Não há "desconto em dobro". |
| **SEC-004** | Premissa "sem allowlist" é falsa: `Order` define allowlist restrita (`order.rb:69-70`) e o concern `RansackableAttributes` retorna só `%w[id] | allowed` (`ransackable_attributes.rb:19-20`). |
| **SEC-005** | `unscoped.update_all` é intencional e documentado (`order.rb:330`) e gated por `can?(:admin)` em todo caller. |
| **SEC-006** | Número de pedido não é fronteira de segurança — `show/update` exigem ownership/token (`default_customer.rb:57-58`). |
| **SCAL-003** | `update_order` só recalcula `if completed? || void?` (`payment.rb:201-205`); no loop de store credit o pedido está em `payment` → o guard bloqueia a amplificação alegada. |
| **SCAL-009** | "Sem cache" é intencional (cachear estoque/frete vivo arriscaria staleness/oversell) e é responsabilidade do app, não do engine. Sem `arquivo:linha`. |

## Vereditos completos (confirmados, com recalibração)

| ID | Agente | Sev. (era → agora) | Veredito |
|----|--------|--------------------|----------|
| CHAOS-002 | chaos | 9 → **8** | ✅ Expiração do OrderMutex a 120s permite reprocessar sem idempotency key |
| CONC-001 | concurrency | 9 → **7** | ✅ `use_transactions:false` + `finalize` multi-tabela sem transação (não-atômico pós-pagamento) |
| CONC-005 | concurrency | 7 → **6** | ✅ Double-spend de store credit entre 2 pedidos do mesmo usuário (mutex é por order_id) |
| CHAOS-003 | chaos | 9 → **6** | ✅ Pagamento órfão preso em `:processing` sem job de reconciliação |
| CHAOS-001 | scalability/chaos | 9 → **5** | ✅ Gateway síncrono sem timeout app-level (mas ActiveMerchant tem default 60s; config é do integrador) |
| CHAOS-008 | chaos | 6 → **5** | ✅ `OrderShipping#ship`: `recalculate`/publish fora da transação de inventário |
| SEC-002 | security | 5 → **5** | ✅ Credencial/token aceitos via query string → vazam em log/Referer (CWE-598) |
| SCAL-002 | scalability | 7 → **4** | ✅ N+1 real em `recalculate_payment_total` (blast radius pequeno) |
| SCAL-004 | scalability | 7 → **4** | ✅ Shipments/frete recriados sem cache a cada `delivery` (custo escala com config, não tráfego) |
| CONC-004 | concurrency | 5 → **4** | ✅ `OrderMutex.with_lock!` não-reentrante → `LockFailed` espúrio em chamada aninhada |
| CONC-006 | concurrency | 7 → **4** | ✅ Sem idempotency key (mitigado pelo mutex; depende da expiração — ver CHAOS-002) |
| CONC-007 | concurrency | 6 → **4** | ✅ Lost update em `recalculate` (mitigado pelo mutex no caminho dominante) |
| CONC-009 | concurrency | 5 → **4** | ✅ Deadlock potencial em locks de `stock_items` multi-variante |
| CONC-011 | concurrency | 4 → **4** | ✅ `restart_checkout_flow` com `update_columns` sem transação |
| SEC-001 | security | 6 → **4** | ✅ Mass-assignment de `gateway_*_profile_id` (condicional; `wallet_payment_source_id` é ownership-scoped) |
| CHAOS-006 | chaos | 7 → **3** | ✅ `allow_checkout_on_gateway_error` (opt-in, default false) |
| CHAOS-007 | chaos | 8 → **3** | ✅ Sem circuit breaker/retry (ausência-de-feature; responsabilidade do integrador) |
| CHAOS-012 | chaos | 4 → **3** | ✅ Jobs de auditoria com discard silencioso (janela estreita) |
| SCAL-005 | scalability | 6 → **3** | ✅ N+1 em `determine_target_shipment` (shipments/pedido ~1) |
| SCAL-006 | scalability | 6 → **3** | ✅ N+1 em `Quantifier#variant_stock_items` |
| SCAL-007 | scalability | 6 → **3** | ✅ Write-amplification/409 no OrderMutex (raise-not-block é by-design) |
| SCAL-008 | scalability | 5 → **3** | ✅ `order.reload` por chamada de gateway |
| SCAL-010 | scalability | 5 → **3** | ✅ Ransack admin sem índice (admin-only, auth-gated, paginado) |
| SCAL-011 | scalability | 4 → **3** | ✅ `finalize` faz N writes sem transação (atomicidade já é CONC-001) |
| CONC-012 | concurrency | 4 → **3** | ✅ `associate_user!` via `update_all` (gated por admin) |
| SEC-003 | security | 3 → **2** | ✅ Comparação de token não-constante (token de 128 bits torna timing inviável) |
| CONC-008 | concurrency | 6 → **2** | ✅ Número de pedido duplicável (colisão ~1/10^9, negligenciável) |

## Leitura

A calibração dos especialistas rodou **consistentemente quente** — especialmente em escalabilidade
(todos rebaixados) e nas manchetes financeiras: o "oversell" (CONC-002) e o "double-charge isolado"
(CHAOS-004/CONC-006) foram neutralizados por uma validação sob lock, pelo encapsulamento de erros do
ActiveMerchant e pelo OrderMutex. O que **sobrevive com força**: a cadeia de expiração do mutex
(CHAOS-002, alto), o `finalize` não-atômico (CONC-001, alto), o double-spend de store credit
(CONC-005) e a credencial em query string (SEC-002). Esses são os achados que merecem ação — e agora
o número de confiança reflete isso.
