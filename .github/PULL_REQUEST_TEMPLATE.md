## Descrição

<!-- Descreva o que essa PR faz e por quê -->

## Tipo de Mudança

- [ ] Novo agente
- [ ] Melhoria em agente existente
- [ ] Correção de bug
- [ ] Documentação
- [ ] Infraestrutura (CI, scripts)

## Checklist

- [ ] Testei localmente com Claude Code (plugin instalado a partir do checkout)
- [ ] Agentes têm frontmatter YAML válido (`name`, `description`, `model`, `tools`)
- [ ] Agentes seguem a estrutura obrigatória (Role, Protocolo, Estrutura de Resposta, Persona, Diretrizes)
- [ ] `.claude-plugin/plugin.json` atualizado (se adicionei/removi agente ou command)
- [ ] `schemas/findings.schema.json` atualizado (se adicionei agente novo)
- [ ] Documentação atualizada (se aplicável)

## Como Testar

<!-- Descreva como reproduzir/testar a mudança -->

1. Instale o plugin: `/plugin marketplace add <caminho-do-checkout>` + `/plugin install claude-war-room`
2. Abra Claude Code em um projeto
3. Execute: `/warroom` ou `/warroom-audit [feature]`
4. Verifique que...
