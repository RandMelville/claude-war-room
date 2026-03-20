#!/usr/bin/env bash

# =============================================================================
# Claude War Room - Gerador de Report HTML Interativo
# Converte os Markdown do War Room em uma página HTML navegável
# =============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# Argumentos
# =============================================================================

if [ $# -lt 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo ""
    echo "Uso: ./generate-report.sh <war-room-directory> [output-file]"
    echo ""
    echo "Exemplos:"
    echo "  ./generate-report.sh war-room/sistema-de-notas/"
    echo "  ./generate-report.sh war-room/auth/ ~/Desktop/report.html"
    echo ""
    echo "O report HTML é gerado com:"
    echo "  - Sidebar de navegação entre agentes"
    echo "  - Diagramas Mermaid renderizados"
    echo "  - Tabelas com cores de severidade"
    echo "  - Toggle dark/light theme"
    echo ""
    exit 0
fi

WAR_ROOM_DIR="$1"
OUTPUT_FILE="${2:-${WAR_ROOM_DIR}/report.html}"

# Validações
if [ ! -d "$WAR_ROOM_DIR" ]; then
    echo -e "${RED}[ERRO]${NC} Diretório não encontrado: $WAR_ROOM_DIR"
    exit 1
fi

# Encontra arquivos .md ordenados
MD_FILES=()
while IFS= read -r file; do
    MD_FILES+=("$file")
done < <(find "$WAR_ROOM_DIR" -maxdepth 1 -name "*.md" -type f | sort)

if [ ${#MD_FILES[@]} -eq 0 ]; then
    echo -e "${RED}[ERRO]${NC} Nenhum arquivo .md encontrado em: $WAR_ROOM_DIR"
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} Gerando report HTML de ${#MD_FILES[@]} arquivo(s)..."

# Extrai nome da feature do diretório
FEATURE_NAME=$(basename "$WAR_ROOM_DIR" | sed 's/-/ /g; s/\b\(.\)/\u\1/g')

# =============================================================================
# Funções de conversão Markdown → HTML
# =============================================================================

html_escape() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    text="${text//\"/&quot;}"
    echo "$text"
}

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

apply_inline_formatting() {
    local line="$1"
    # Bold: **text** → <strong>text</strong>
    line=$(echo "$line" | sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g')
    # Inline code: `text` → <code>text</code>
    line=$(echo "$line" | sed 's/`\([^`]*\)`/<code class="inline">\1<\/code>/g')
    # File:line references
    line=$(echo "$line" | sed 's/\([A-Za-z0-9_.-]*\.[a-z]*:[0-9]*\)/<span class="code-ref">\1<\/span>/g')
    echo "$line"
}

detect_severity_class() {
    local cell="$1"
    if echo "$cell" | grep -qiE '🔴|Crít|Critic|P0|Frágil'; then
        echo "severity-critical"
    elif echo "$cell" | grep -qiE '🟡|Alt[oa]|High|Preocupante|P1|Atenção'; then
        echo "severity-warning"
    elif echo "$cell" | grep -qiE '🟢|Baix[oa]|Low|Adequad|Seguro|Resiliente|P2'; then
        echo "severity-ok"
    else
        echo ""
    fi
}

convert_md_to_html() {
    local file="$1"
    local section_id="$2"

    local state="NORMAL"
    local in_list=""
    local code_lang=""
    local table_row_num=0

    while IFS= read -r raw_line || [ -n "$raw_line" ]; do

        # --- Mermaid blocks ---
        if [ "$state" = "IN_MERMAID" ]; then
            if echo "$raw_line" | grep -q '^\s*```\s*$'; then
                echo '</pre>'
                state="NORMAL"
            else
                html_escape "$raw_line"
            fi
            continue
        fi

        # --- Code blocks ---
        if [ "$state" = "IN_CODE" ]; then
            if echo "$raw_line" | grep -q '^\s*```\s*$'; then
                echo '</code></pre>'
                state="NORMAL"
            else
                html_escape "$raw_line"
            fi
            continue
        fi

        # --- Start mermaid block ---
        if echo "$raw_line" | grep -q '^\s*```mermaid'; then
            # Close any open list
            if [ -n "$in_list" ]; then
                echo "</$in_list>"
                in_list=""
            fi
            echo '<pre class="mermaid">'
            state="IN_MERMAID"
            continue
        fi

        # --- Start code block ---
        if echo "$raw_line" | grep -q '^\s*```'; then
            if [ -n "$in_list" ]; then
                echo "</$in_list>"
                in_list=""
            fi
            code_lang=$(echo "$raw_line" | sed 's/.*```//')
            echo "<pre class=\"code-block\"><code class=\"language-${code_lang}\">"
            state="IN_CODE"
            continue
        fi

        # --- Table rows ---
        if echo "$raw_line" | grep -q '^\s*|'; then
            # Close any open list
            if [ -n "$in_list" ]; then
                echo "</$in_list>"
                in_list=""
            fi

            # Skip separator row
            if echo "$raw_line" | grep -q '^\s*|[-:|]*|$'; then
                continue
            fi

            table_row_num=$((table_row_num + 1))

            if [ $table_row_num -eq 1 ]; then
                echo '<div class="table-wrapper"><table>'
                echo '<thead><tr>'
                # Parse header cells
                echo "$raw_line" | sed 's/^\s*|//; s/|\s*$//' | tr '|' '\n' | while IFS= read -r cell; do
                    cell=$(echo "$cell" | sed 's/^\s*//; s/\s*$//')
                    echo "<th>$(apply_inline_formatting "$cell")</th>"
                done
                echo '</tr></thead><tbody>'
            else
                # Detect severity for row
                local row_class
                row_class=$(detect_severity_class "$raw_line")
                if [ -n "$row_class" ]; then
                    echo "<tr class=\"$row_class\">"
                else
                    echo '<tr>'
                fi
                echo "$raw_line" | sed 's/^\s*|//; s/|\s*$//' | tr '|' '\n' | while IFS= read -r cell; do
                    cell=$(echo "$cell" | sed 's/^\s*//; s/\s*$//')
                    echo "<td>$(apply_inline_formatting "$cell")</td>"
                done
                echo '</tr>'
            fi
            continue
        fi

        # End of table
        if [ $table_row_num -gt 0 ]; then
            echo '</tbody></table></div>'
            table_row_num=0
        fi

        # --- Headers ---
        if echo "$raw_line" | grep -q '^#### '; then
            if [ -n "$in_list" ]; then echo "</$in_list>"; in_list=""; fi
            local text="${raw_line#\#\#\#\# }"
            echo "<h4>$(apply_inline_formatting "$text")</h4>"
            continue
        fi
        if echo "$raw_line" | grep -q '^### '; then
            if [ -n "$in_list" ]; then echo "</$in_list>"; in_list=""; fi
            local text="${raw_line#\#\#\# }"
            local slug
            slug=$(slugify "$text")
            echo "<h3 id=\"${section_id}-${slug}\">$(apply_inline_formatting "$text")</h3>"
            continue
        fi
        if echo "$raw_line" | grep -q '^## '; then
            if [ -n "$in_list" ]; then echo "</$in_list>"; in_list=""; fi
            local text="${raw_line#\#\# }"
            local slug
            slug=$(slugify "$text")
            echo "<h2 id=\"${section_id}-${slug}\">$(apply_inline_formatting "$text")</h2>"
            continue
        fi
        if echo "$raw_line" | grep -q '^# '; then
            if [ -n "$in_list" ]; then echo "</$in_list>"; in_list=""; fi
            local text="${raw_line#\# }"
            echo "<h1>$(apply_inline_formatting "$text")</h1>"
            continue
        fi

        # --- Horizontal rule ---
        if echo "$raw_line" | grep -q '^\s*---\s*$'; then
            if [ -n "$in_list" ]; then echo "</$in_list>"; in_list=""; fi
            echo '<hr>'
            continue
        fi

        # --- Checkbox list ---
        if echo "$raw_line" | grep -q '^\s*- \[.\]'; then
            if [ "$in_list" != "ul" ]; then
                if [ -n "$in_list" ]; then echo "</$in_list>"; fi
                echo '<ul class="checklist">'
                in_list="ul"
            fi
            if echo "$raw_line" | grep -q '^\s*- \[x\]'; then
                local text="${raw_line#*\[x\] }"
                echo "<li><input type=\"checkbox\" checked disabled> $(apply_inline_formatting "$text")</li>"
            else
                local text="${raw_line#*\[ \] }"
                echo "<li><input type=\"checkbox\" disabled> $(apply_inline_formatting "$text")</li>"
            fi
            continue
        fi

        # --- Unordered list ---
        if echo "$raw_line" | grep -q '^\s*- '; then
            if [ "$in_list" != "ul" ]; then
                if [ -n "$in_list" ]; then echo "</$in_list>"; fi
                echo '<ul>'
                in_list="ul"
            fi
            local text="${raw_line#*- }"
            echo "<li>$(apply_inline_formatting "$text")</li>"
            continue
        fi

        # --- Ordered list ---
        if echo "$raw_line" | grep -qE '^\s*[0-9]+\. '; then
            if [ "$in_list" != "ol" ]; then
                if [ -n "$in_list" ]; then echo "</$in_list>"; fi
                echo '<ol>'
                in_list="ol"
            fi
            local text
            text=$(echo "$raw_line" | sed 's/^\s*[0-9]*\.\s*//')
            echo "<li>$(apply_inline_formatting "$text")</li>"
            continue
        fi

        # Close list if we're no longer in one
        if [ -n "$in_list" ]; then
            echo "</$in_list>"
            in_list=""
        fi

        # --- Blockquote ---
        if echo "$raw_line" | grep -q '^> '; then
            local text="${raw_line#> }"
            echo "<blockquote>$(apply_inline_formatting "$text")</blockquote>"
            continue
        fi

        # --- Empty line ---
        if [ -z "$raw_line" ]; then
            continue
        fi

        # --- Regular paragraph ---
        echo "<p>$(apply_inline_formatting "$raw_line")</p>"

    done < "$file"

    # Close any remaining open elements
    if [ $table_row_num -gt 0 ]; then
        echo '</tbody></table></div>'
    fi
    if [ -n "$in_list" ]; then
        echo "</$in_list>"
    fi
}

# =============================================================================
# Gera o HTML
# =============================================================================

{
# --- HTML Header ---
cat << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
HTMLHEAD

echo "<title>War Room Report — ${FEATURE_NAME}</title>"

cat << 'STYLE'
<style>
:root {
    --bg-primary: #0d1117;
    --bg-secondary: #161b22;
    --bg-tertiary: #1c2128;
    --text-primary: #c9d1d9;
    --text-secondary: #8b949e;
    --accent: #58a6ff;
    --accent-hover: #79c0ff;
    --border: #30363d;
    --severity-critical-bg: rgba(248,81,73,0.15);
    --severity-critical-text: #f85149;
    --severity-warning-bg: rgba(210,153,34,0.15);
    --severity-warning-text: #d29922;
    --severity-ok-bg: rgba(63,185,80,0.15);
    --severity-ok-text: #3fb950;
    --sidebar-width: 280px;
}

.light-theme {
    --bg-primary: #ffffff;
    --bg-secondary: #f6f8fa;
    --bg-tertiary: #eaeef2;
    --text-primary: #24292f;
    --text-secondary: #57606a;
    --accent: #0969da;
    --accent-hover: #0550ae;
    --border: #d0d7de;
    --severity-critical-bg: rgba(248,81,73,0.1);
    --severity-critical-text: #cf222e;
    --severity-warning-bg: rgba(210,153,34,0.1);
    --severity-warning-text: #9a6700;
    --severity-ok-bg: rgba(63,185,80,0.1);
    --severity-ok-text: #1a7f37;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
    background: var(--bg-primary);
    color: var(--text-primary);
    line-height: 1.6;
    display: grid;
    grid-template-columns: var(--sidebar-width) 1fr;
    min-height: 100vh;
}

/* Sidebar */
#sidebar {
    background: var(--bg-secondary);
    border-right: 1px solid var(--border);
    padding: 1.5rem 0;
    position: fixed;
    width: var(--sidebar-width);
    height: 100vh;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
}

.sidebar-header {
    padding: 0 1.25rem 1.25rem;
    border-bottom: 1px solid var(--border);
}

.sidebar-header h2 {
    font-size: 1.1rem;
    color: var(--text-primary);
    margin-bottom: 0.25rem;
}

.sidebar-header .feature-name {
    font-size: 0.85rem;
    color: var(--accent);
    font-weight: 500;
}

.sidebar-nav { flex: 1; padding: 0.75rem 0; }

.sidebar-nav a {
    display: block;
    padding: 0.5rem 1.25rem;
    color: var(--text-secondary);
    text-decoration: none;
    font-size: 0.85rem;
    border-left: 3px solid transparent;
    transition: all 0.15s;
}

.sidebar-nav a:hover {
    color: var(--text-primary);
    background: var(--bg-tertiary);
}

.sidebar-nav a.active {
    color: var(--accent);
    border-left-color: var(--accent);
    background: var(--bg-tertiary);
}

.sidebar-nav .agent-label {
    font-weight: 600;
    color: var(--text-primary);
    font-size: 0.8rem;
    padding: 1rem 1.25rem 0.25rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.sidebar-footer {
    padding: 1rem 1.25rem;
    border-top: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

#theme-toggle {
    background: var(--bg-tertiary);
    border: 1px solid var(--border);
    color: var(--text-secondary);
    padding: 0.35rem 0.75rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.8rem;
}

#theme-toggle:hover { color: var(--text-primary); }

.timestamp {
    font-size: 0.7rem;
    color: var(--text-secondary);
}

/* Main Content */
main {
    grid-column: 2;
    padding: 2rem 3rem;
    max-width: 960px;
}

/* Typography */
h1 { font-size: 1.8rem; margin: 2rem 0 1rem; color: var(--text-primary); }
h2 { font-size: 1.4rem; margin: 1.75rem 0 0.75rem; color: var(--text-primary); border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; }
h3 { font-size: 1.15rem; margin: 1.5rem 0 0.5rem; color: var(--text-primary); }
h4 { font-size: 1rem; margin: 1rem 0 0.5rem; color: var(--text-secondary); }
p { margin: 0.5rem 0; }
hr { border: none; border-top: 1px solid var(--border); margin: 2rem 0; }
blockquote { border-left: 3px solid var(--accent); padding: 0.5rem 1rem; margin: 0.75rem 0; background: var(--bg-secondary); border-radius: 0 6px 6px 0; }

/* Lists */
ul, ol { padding-left: 1.5rem; margin: 0.5rem 0; }
li { margin: 0.25rem 0; }
.checklist { list-style: none; padding-left: 0.5rem; }
.checklist li { display: flex; align-items: center; gap: 0.5rem; }
.checklist input[type="checkbox"] { margin: 0; }

/* Tables */
.table-wrapper { overflow-x: auto; margin: 1rem 0; border-radius: 6px; border: 1px solid var(--border); }
table { width: 100%; border-collapse: collapse; font-size: 0.875rem; }
thead { background: var(--bg-secondary); }
th { padding: 0.6rem 0.75rem; text-align: left; font-weight: 600; color: var(--text-primary); border-bottom: 2px solid var(--border); white-space: nowrap; }
td { padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--border); }
tbody tr:hover { background: var(--bg-secondary); }
tr.severity-critical { background: var(--severity-critical-bg); }
tr.severity-critical td:first-child { border-left: 3px solid var(--severity-critical-text); }
tr.severity-warning { background: var(--severity-warning-bg); }
tr.severity-warning td:first-child { border-left: 3px solid var(--severity-warning-text); }
tr.severity-ok { background: var(--severity-ok-bg); }
tr.severity-ok td:first-child { border-left: 3px solid var(--severity-ok-text); }

/* Code */
.code-block { background: var(--bg-secondary); border: 1px solid var(--border); border-radius: 6px; padding: 1rem; overflow-x: auto; font-size: 0.85rem; font-family: 'SF Mono', 'Fira Code', Consolas, monospace; margin: 0.75rem 0; }
code.inline { background: var(--bg-tertiary); padding: 0.15rem 0.4rem; border-radius: 4px; font-size: 0.85em; font-family: 'SF Mono', 'Fira Code', Consolas, monospace; }
.code-ref { color: var(--accent); font-family: 'SF Mono', 'Fira Code', Consolas, monospace; font-size: 0.85em; }

/* Mermaid */
.mermaid { background: var(--bg-secondary); border: 1px solid var(--border); border-radius: 6px; padding: 1.5rem; margin: 1rem 0; text-align: center; }

/* Agent section */
.agent-section { margin-bottom: 3rem; padding-top: 1rem; }
.agent-section-header { display: flex; align-items: center; gap: 0.75rem; margin-bottom: 1.5rem; padding-bottom: 0.75rem; border-bottom: 2px solid var(--accent); }
.agent-number { background: var(--accent); color: #fff; width: 2rem; height: 2rem; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem; flex-shrink: 0; }
.agent-section-header h2 { border: none; margin: 0; padding: 0; }

/* Mobile hamburger */
#sidebar-toggle {
    display: none;
    position: fixed;
    top: 1rem;
    left: 1rem;
    z-index: 100;
    background: var(--bg-secondary);
    border: 1px solid var(--border);
    color: var(--text-primary);
    padding: 0.5rem 0.75rem;
    border-radius: 6px;
    cursor: pointer;
    font-size: 1.2rem;
}

/* Responsive */
@media (max-width: 768px) {
    body { grid-template-columns: 1fr; }
    #sidebar { transform: translateX(-100%); transition: transform 0.3s; z-index: 50; }
    #sidebar.open { transform: translateX(0); }
    #sidebar-toggle { display: block; }
    main { grid-column: 1; padding: 1rem 1.25rem; padding-top: 3.5rem; }
}

/* Print */
@media print {
    body { display: block; color: #000; background: #fff; }
    #sidebar, #sidebar-toggle, #theme-toggle { display: none !important; }
    main { max-width: 100%; padding: 0; }
    .mermaid { border: 1px solid #ccc; }
    table { font-size: 0.75rem; }
    tr.severity-critical { background: #ffe0e0 !important; }
    tr.severity-warning { background: #fff3cd !important; }
    tr.severity-ok { background: #d4edda !important; }
    h2 { page-break-before: auto; }
    .agent-section { page-break-inside: avoid; }
}

strong { color: var(--text-primary); }
</style>
</head>
<body>
STYLE

# --- Sidebar ---
echo '<button id="sidebar-toggle">&#9776;</button>'
echo '<nav id="sidebar">'
echo '  <div class="sidebar-header">'
echo "    <h2>War Room</h2>"
echo "    <div class=\"feature-name\">${FEATURE_NAME}</div>"
echo '  </div>'
echo '  <div class="sidebar-nav">'

# Build sidebar links from files
agent_num=0
for md_file in "${MD_FILES[@]}"; do
    agent_num=$((agent_num + 1))
    fname=$(basename "$md_file" .md)
    # Extract agent alias from filename: 01-doc-reverse-arquitetura → DOC-REVERSE-ARQUITETURA
    alias=$(echo "$fname" | sed 's/^[0-9]*-//' | tr '[:lower:]' '[:upper:]' | tr '-' ' ' | cut -d' ' -f1-2 | tr ' ' '-')
    echo "    <div class=\"agent-label\">${agent_num}. ${alias}</div>"
    # Read headers from file for sub-navigation
    grep -n '^## ' "$md_file" | head -8 | while IFS=: read -r _lineno header; do
        text="${header#\#\# }"
        slug=$(slugify "$text")
        echo "    <a href=\"#agent-${agent_num}-${slug}\">${text}</a>"
    done
done

echo '  </div>'
echo '  <div class="sidebar-footer">'
echo '    <button id="theme-toggle">Tema</button>'
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
echo "    <span class=\"timestamp\">Gerado: ${TIMESTAMP}</span>"
echo '  </div>'
echo '</nav>'

# --- Main Content ---
echo '<main>'

# Title
echo "<h1>War Room: ${FEATURE_NAME}</h1>"
echo "<p style=\"color: var(--text-secondary)\">Relatório gerado em ${TIMESTAMP} com ${#MD_FILES[@]} agentes</p>"
echo '<hr>'

# Process each markdown file
agent_num=0
for md_file in "${MD_FILES[@]}"; do
    agent_num=$((agent_num + 1))
    fname=$(basename "$md_file" .md)
    alias=$(echo "$fname" | sed 's/^[0-9]*-//' | tr '[:lower:]' '[:upper:]' | tr '-' ' ' | cut -d' ' -f1-2 | tr ' ' '-')
    section_id="agent-${agent_num}"

    echo "<section class=\"agent-section\" id=\"${section_id}\">"
    echo "<div class=\"agent-section-header\">"
    echo "  <span class=\"agent-number\">${agent_num}</span>"
    echo "  <h2>${alias}</h2>"
    echo "</div>"

    convert_md_to_html "$md_file" "$section_id"

    echo "</section>"
done

echo '</main>'

# --- JavaScript ---
cat << 'SCRIPT'
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>
// Mermaid init
const isDark = !document.body.classList.contains('light-theme');
mermaid.initialize({
    startOnLoad: true,
    theme: isDark ? 'dark' : 'default',
    securityLevel: 'sandbox'
});

// Theme toggle
const toggle = document.getElementById('theme-toggle');
if (localStorage.getItem('warroom-theme') === 'light') {
    document.body.classList.add('light-theme');
}
toggle.addEventListener('click', function() {
    document.body.classList.toggle('light-theme');
    const isLight = document.body.classList.contains('light-theme');
    localStorage.setItem('warroom-theme', isLight ? 'light' : 'dark');
    // Re-render mermaid
    document.querySelectorAll('.mermaid').forEach(function(el) {
        el.removeAttribute('data-processed');
    });
    mermaid.initialize({ theme: isLight ? 'default' : 'dark', securityLevel: 'sandbox' });
    mermaid.run();
});

// Sidebar toggle (mobile)
document.getElementById('sidebar-toggle').addEventListener('click', function() {
    document.getElementById('sidebar').classList.toggle('open');
});

// Close sidebar on link click (mobile)
document.querySelectorAll('.sidebar-nav a').forEach(function(a) {
    a.addEventListener('click', function() {
        document.getElementById('sidebar').classList.remove('open');
    });
});

// Scroll spy
const sections = document.querySelectorAll('.agent-section');
const navLinks = document.querySelectorAll('.sidebar-nav a');
const observer = new IntersectionObserver(function(entries) {
    entries.forEach(function(entry) {
        if (entry.isIntersecting) {
            const id = entry.target.id;
            navLinks.forEach(function(link) {
                link.classList.remove('active');
                if (link.getAttribute('href').startsWith('#' + id)) {
                    link.classList.add('active');
                }
            });
        }
    });
}, { rootMargin: '-20% 0px -60% 0px' });
sections.forEach(function(s) { observer.observe(s); });

// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(function(a) {
    a.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
});
</script>
SCRIPT

echo '</body></html>'

} > "$OUTPUT_FILE"

echo -e "${GREEN}[OK]${NC} Report gerado: $OUTPUT_FILE"
echo -e "${BLUE}[INFO]${NC} Abra no browser: ${OUTPUT_FILE}"
