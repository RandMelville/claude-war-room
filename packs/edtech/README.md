# Domain Pack: EdTech

Os agentes do core são **neutros ao domínio**. Este pack reintroduz o sabor original do War Room —
sistemas educacionais — como uma camada opcional de termos, métricas e regras de priorização.

> A v2.0 mantém o pack como **documentação de overlay**: você cola o bloco abaixo no `CLAUDE.md` do
> repositório-alvo (ou passa como contexto ao rodar `/warroom` / `/warroom-audit`). Carregamento
> automático de packs entra numa versão futura.

## Como ativar

Adicione ao `CLAUDE.md` do repositório que você vai analisar:

```markdown
## War Room — Domain Pack: EdTech

- Domínio: sistemas educacionais (escolas, professores, alunos, secretarias).
- Usuário final = a escola. Priorize impacto em professor/aluno acima de elegância técnica.
- Dados críticos e irrecuperáveis: notas, frequência, matrículas, histórico escolar.
- Escala de referência: simule 1.000 escolas acessando simultaneamente (pico = início de
  semestre, período de provas, fechamento de boletim).
- Privacidade: LGPD com atenção a dados de menores (Art. 14 — tratamento de dados de crianças e
  adolescentes exige consentimento específico e o melhor interesse do titular).
- Glossário típico: lançamento de notas, diário de classe, plano de aula, conselho de classe.
```

## Mapeamento de termos genérico → EdTech

| Genérico (core)        | EdTech                          |
|------------------------|---------------------------------|
| usuário / cliente      | professor / aluno / responsável |
| pedido / transação     | lançamento de nota / matrícula  |
| registro crítico       | nota, frequência, histórico     |
| pico de carga          | início de semestre, provas      |
| PII / dados sensíveis  | dados de menores (LGPD Art. 14) |

## Outros domínios

Use este pack como template para criar `packs/fintech`, `packs/healthtech`, etc. — troque termos,
métricas de escala, dados sensíveis e regulação aplicável (PCI-DSS, HIPAA, etc.).
