#!/usr/bin/env bash
set -euo pipefail

# ┌───────────────────────────────────────────────────────────────────┐
# │                        Dev Container Setup                        │
# └───────────────────────────────────────────────────────────────────┘

#── helper for colored output ───────────────────────────────────────
info()    { printf "\033[36mℹ [INFO]\033[0m  %s\n" "$*"; }
success() { printf "\033[32m✔ [OK]\033[0m    %s\n" "$*"; }
warn()    { printf "\033[33m⚠ [WARN]\033[0m  %s\n" "$*"; }
error()   { printf "\033[31m✖ [ERROR]\033[0m %s\n" "$*"; }

info "Welcome to your Development Container!"
echo

#── show the key tools ───────────────────────────────────────────────
info "🔧 Tools available in this environment:"
printf "  • Node.js: %s\n" "$(node --version)"
printf "  • npm:     %s\n" "$(npm --version)"

#── PowerShell check ─────────────────────────────────────────────────
if command -v pwsh &>/dev/null; then
  PS_PATH=$(which pwsh)
  PS_VER=$("$PS_PATH" -c '$PSVersionTable.PSVersion.ToString()')
  success "PowerShell: found at $PS_PATH (v$PS_VER)"
else
  warn    "PowerShell: NOT found in PATH"
fi

echo
#── Claude CLI check ────────────────────────────────────────────────
info "🔧 Claude CLI status:"
if command -v claude &>/dev/null; then
  CLAUDE_PATH=$(which claude)
  CLAUDE_VER=$(claude --version 2>/dev/null || echo "n/a")
  success "Claude CLI: found at $CLAUDE_PATH (v$CLAUDE_VER)"
else
  warn    "Claude CLI: NOT found in PATH"
fi

echo
#── Azure CLI check ─────────────────────────────────────────────────
info "☁️ Azure CLI status:"
if command -v az &>/dev/null; then
  AZ_PATH=$(which az)
  AZ_VER=$(az --version 2>/dev/null | head -n1 | awk '{print $2}')
  success "Azure CLI: found at $AZ_PATH (v$AZ_VER)"
else
  warn    "Azure CLI: NOT found in PATH"
fi

echo
#── Claude (Anthropic) configuration ────────────────────────────────
info "🔑 Configuring Claude (Anthropic)…"
if [[ -n "${ANTHROPIC_API_KEY-}" ]]; then
  success "ANTHROPIC_API_KEY is set"
  CONF_DIR="$HOME/.config/anthropic"
  mkdir -p "$CONF_DIR"
  cat > "$CONF_DIR/credentials.json" <<-EOF
  {
    "api_key": "${ANTHROPIC_API_KEY}"
  }
EOF
  chmod 600 "$CONF_DIR/credentials.json"
  success "Wrote credentials to $CONF_DIR/credentials.json"
else
  error "ANTHROPIC_API_KEY is missing — Claude may not work!"
fi

echo
success "Post-create steps completed!"
