#!/usr/bin/env bash

# =============================================================================
# Claude War Room — install.sh  (DEPRECADO na v2.0)
# -----------------------------------------------------------------------------
# A partir da v2.0, o War Room é distribuído como um PLUGIN do Claude Code.
# O antigo mecanismo (copiar agentes para ~/.claude/agents/ + trigger de
# memória "ativar modo war room:") foi substituído por slash commands.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Claude War Room v2.0 — instale como PLUGIN     ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo -e "${YELLOW}Este script de instalação foi descontinuado.${NC}"
echo ""
echo "No Claude Code, rode:"
echo ""
echo -e "  ${GREEN}/plugin marketplace add RandMelville/claude-war-room${NC}"
echo -e "  ${GREEN}/plugin install claude-war-room${NC}"
echo ""
echo "Depois, dentro de qualquer repositório que você queira analisar:"
echo ""
echo -e "  ${BLUE}/warroom${NC}            # Recon: doc viva do codebase (.warroom/)"
echo -e "  ${BLUE}/warroom-audit${NC}      # War Room completo: auditoria multi-agente de riscos"
echo ""
echo "Migração do v1: o trigger 'ativar modo war room:' e os agentes copiados"
echo "manualmente em ~/.claude/agents/ não são mais necessários. Veja o README."
echo ""
exit 0
