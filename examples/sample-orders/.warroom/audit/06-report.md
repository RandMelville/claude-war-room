<!-- Exemplo ILUSTRATIVO. Trecho do Report de Confiança (quality-stability-lead). -->

# Report de Confiança do Sistema

**Feature/Sistema analisado:** Módulo de Pedidos (`src/orders`)
**Índice de Confiança:** 🔴 Baixo

## Resumo Executivo

O checkout pode **vender estoque que não existe** quando dois clientes compram o mesmo item ao mesmo
tempo (sem trava no estoque). Além disso, uma instabilidade no gateway de pagamento pode **derrubar o
serviço inteiro** (chamada sem timeout), e um cliente consegue **ver pedidos de outro** trocando o id
na URL. Recomendamos corrigir os 3 itens críticos/altos antes da próxima campanha de vendas.

## 1. Tabela de Severidade

| # | Problema (negócio)                         | Risco Técnico                | Severidade | Afetados        | Evidência                                 |
|---|--------------------------------------------|------------------------------|------------|-----------------|-------------------------------------------|
| 1 | Vende estoque inexistente (oversell)       | Race condition sem lock      | 🔴 Crítico | Todos clientes  | `InventoryRepository.java:58`             |
| 2 | Gateway lento derruba o checkout           | Sem timeout/circuit breaker  | 🔴 Alto    | Todos clientes  | `OrderService.java:84`                     |
| 3 | Cliente vê pedido de outro                 | IDOR (Broken Access Control) | 🔴 Alto    | Toda a base     | `OrderService.java:121`                    |
| 4 | Checkout trava no pico                      | Pool de conexões pequeno     | 🟡 Médio   | Pico de vendas  | `application.yml:12`                       |

## 2. Plano de Ação Imediato

### Esta semana (P0)
| # | Ação                                         | Responsável | Esforço | Impacto |
|---|----------------------------------------------|-------------|---------|---------|
| 1 | Lock otimista (@Version) no estoque          | Backend     | P       | Alto    |
| 2 | Timeout + circuit breaker no pagamento       | Backend     | P       | Alto    |
| 3 | Checagem de ownership no GET /orders/{id}     | Backend     | P       | Alto    |

## 3. Riscos de Não Agir

- Oversell em campanha de vendas → estorno, suporte e perda de confiança.
- Incidente de indisponibilidade total se o gateway oscilar no pico.
- Vazamento de dados de pedidos entre clientes (exposição de PII).
