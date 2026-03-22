#!/bin/bash

# =============================================================================
# Claude War Room - Instalador
# Instala os 6 agentes e o trigger de orquestração no Claude Code
# =============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretórios
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Flags
FORCE=false
DRY_RUN=false
UNINSTALL=false

# Arquivos de agente (sem o prefixo numérico no destino)
declare -a AGENT_FILES=(
    "01-reverse-engineering-architect.md:reverse-engineering-architect.md"
    "02-scalability-architect.md:scalability-architect.md"
    "03-concurrency-specialist.md:concurrency-specialist.md"
    "04-chaos-engineer-sre.md:chaos-engineer-sre.md"
    "05-security-auditor.md:security-auditor.md"
    "06-quality-stability-lead.md:quality-stability-lead.md"
)

# =============================================================================
# Funções
# =============================================================================

usage() {
    echo "Uso: ./install.sh [opções]"
    echo ""
    echo "Opções:"
    echo "  --force       Sobrescreve arquivos existentes sem perguntar"
    echo "  --dry-run     Mostra o que seria feito sem executar"
    echo "  --uninstall   Remove os agentes e trigger instalados"
    echo "  --help        Mostra esta ajuda"
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

copy_file() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Copiaria: $src → $dest"
        return
    fi

    if [ -f "$dest" ] && [ "$FORCE" = false ]; then
        echo -e "${YELLOW}  Arquivo já existe:${NC} $dest"
        read -p "  Sobrescrever? (s/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_warn "Pulando: $label"
            return
        fi
    fi

    cp "$src" "$dest"
    log_success "$label"
}

remove_file() {
    local file="$1"
    local label="$2"

    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Removeria: $file"
        return
    fi

    if [ -f "$file" ]; then
        rm "$file"
        log_success "Removido: $label"
    else
        log_warn "Não encontrado: $label"
    fi
}

# =============================================================================
# Parse de argumentos
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Opção desconhecida: $1"
            usage
            exit 1
            ;;
    esac
done

# =============================================================================
# Header
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║         Claude War Room - Instalador             ║"
echo "║   6 Agentes para Análise 360° de Features        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# =============================================================================
# Desinstalação
# =============================================================================

if [ "$UNINSTALL" = true ]; then
    log_info "Removendo agentes do War Room..."
    echo ""

    for entry in "${AGENT_FILES[@]}"; do
        dest_name="${entry#*:}"
        remove_file "$AGENTS_DIR/$dest_name" "$dest_name"
    done

    echo ""
    log_warn "O trigger de memória (feedback_war_room_mode.md) precisa ser removido manualmente"
    log_warn "do diretório de memória do seu projeto."
    echo ""
    log_success "Desinstalação concluída!"
    exit 0
fi

# =============================================================================
# Verificações
# =============================================================================

if [ ! -d "$CLAUDE_DIR" ]; then
    log_error "Diretório ~/.claude/ não encontrado."
    log_error "Verifique se o Claude Code está instalado e configurado."
    echo ""
    echo "  Instale em: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

log_success "Claude Code detectado em $CLAUDE_DIR"

# =============================================================================
# Instalação dos Agentes
# =============================================================================

echo ""
log_info "Instalando 6 agentes..."
echo ""

if [ ! -d "$AGENTS_DIR" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "  (dry-run) Criaria: $AGENTS_DIR"
    else
        mkdir -p "$AGENTS_DIR"
        log_success "Diretório criado: $AGENTS_DIR"
    fi
fi

for entry in "${AGENT_FILES[@]}"; do
    src_name="${entry%%:*}"
    dest_name="${entry#*:}"
    copy_file "$SCRIPT_DIR/agents/$src_name" "$AGENTS_DIR/$dest_name" "$dest_name"
done

# =============================================================================
# Instalação do Trigger de Memória
# =============================================================================

echo ""
log_info "Configurando trigger de orquestração..."
echo ""

echo "Onde deseja instalar o trigger de memória?"
echo ""
echo "  1) Em um projeto específico (recomendado)"
echo "  2) Pular (instalar manualmente depois)"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "  (dry-run) Pulando configuração de memória"
else
    read -p "Opção (1/2): " -n 1 -r
    echo ""

    case $REPLY in
        1)
            echo ""
            echo "Digite o caminho absoluto do seu projeto:"
            echo "  Ex: /Users/fulano/Documents/meu-projeto"
            echo ""
            read -p "Caminho: " PROJECT_PATH

            if [ ! -d "$PROJECT_PATH" ]; then
                log_error "Diretório não encontrado: $PROJECT_PATH"
                log_warn "Pule e configure manualmente seguindo o README."
            else
                # Converte o caminho para o formato do Claude Code
                # /Users/fulano/meu-projeto → -Users-fulano-meu-projeto
                CLAUDE_PROJECT_PATH=$(echo "$PROJECT_PATH" | sed 's|/|-|g')
                MEMORY_DIR="$CLAUDE_DIR/projects/$CLAUDE_PROJECT_PATH/memory"

                mkdir -p "$MEMORY_DIR"
                copy_file "$SCRIPT_DIR/memory/feedback_war_room_mode.md" \
                          "$MEMORY_DIR/feedback_war_room_mode.md" \
                          "Trigger de orquestração"

                # Atualiza ou cria MEMORY.md
                MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"
                MEMORY_ENTRY="- [feedback_war_room_mode.md](./feedback_war_room_mode.md) - Comando \"ativar modo war room: [FEATURE]\" orquestra 6 agentes sequenciais"

                if [ -f "$MEMORY_INDEX" ]; then
                    if ! grep -q "feedback_war_room_mode" "$MEMORY_INDEX"; then
                        echo "$MEMORY_ENTRY" >> "$MEMORY_INDEX"
                        log_success "Entrada adicionada ao MEMORY.md existente"
                    else
                        log_warn "Entrada já existe no MEMORY.md"
                    fi
                else
                    echo "$MEMORY_ENTRY" > "$MEMORY_INDEX"
                    log_success "MEMORY.md criado com entrada do War Room"
                fi
            fi
            ;;
        2)
            log_info "Pulando. Siga as instruções do README para configurar manualmente."
            ;;
        *)
            log_warn "Opção inválida. Pulando."
            ;;
    esac
fi

# =============================================================================
# Finalização
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║            Instalação Concluída!                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Para usar, abra o Claude Code no seu projeto e digite:"
echo ""
echo -e "  ${GREEN}ativar modo war room: [NOME DA FEATURE]${NC}"
echo ""
echo "Exemplo:"
echo -e "  ${BLUE}ativar modo war room: Sistema de Autenticação${NC}"
echo ""
echo "Documentação completa: docs/ARCHITECTURE.md"
echo "Personalização: docs/CUSTOMIZATION.md"
echo ""
