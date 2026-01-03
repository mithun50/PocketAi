#!/data/data/com.termux/files/usr/bin/bash
#
# PocketAI Setup Script
# One command to install everything
#
# Usage: ./setup.sh
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POCKETAI_ROOT="$SCRIPT_DIR"
DATA_DIR="$POCKETAI_ROOT/data"
MODELS_DIR="$POCKETAI_ROOT/models"
ENV_FILE="$HOME/.pocketai_env"
SHELL_RC="$HOME/.bashrc"

LLAMAFILE_VERSION="0.8.13"
LLAMAFILE_URL="https://github.com/Mozilla-Ocho/llamafile/releases/download/${LLAMAFILE_VERSION}/llamafile-${LLAMAFILE_VERSION}"

CONTAINER_NAME="pocketai"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# =============================================================================
# Helpers
# =============================================================================

log_info()    { echo -e "${BLUE}▸${RESET} $1"; }
log_success() { echo -e "${GREEN}✓${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}!${RESET} $1"; }
log_error()   { echo -e "${RED}✗${RESET} $1" >&2; }
log_step()    { echo -e "\n${BOLD}${CYAN}$1${RESET}"; }

# =============================================================================
# Banner
# =============================================================================

show_banner() {
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
    ____             __        __  ___    ____
   / __ \____  _____/ /_____  / /_/   |  /  _/
  / /_/ / __ \/ ___/ //_/ _ \/ __/ /| |  / /
 / ____/ /_/ / /__/ ,< /  __/ /_/ ___ |_/ /
/_/    \____/\___/_/|_|\___/\__/_/  |_/___/
EOF
    echo -e "${RESET}${DIM}  Local AI • No Cloud • Just Works${RESET}"
    echo ""
}

# =============================================================================
# System Check
# =============================================================================

check_system() {
    log_step "System Check"

    # Check Termux
    if [[ -d "/data/data/com.termux" ]]; then
        log_success "Termux detected"
    else
        log_warn "Not in Termux - some features may not work"
    fi

    # Check architecture
    local arch=$(uname -m)
    log_success "Architecture: $arch"

    # Check RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    log_success "RAM: ${ram_gb}GB"

    # Check storage
    local storage=$(df -h "$HOME" | tail -1 | awk '{print $4}')
    log_success "Storage: ${storage} free"
}

# =============================================================================
# Dependencies
# =============================================================================

install_dependencies() {
    log_step "Dependencies"

    # Update package list
    pkg update -y 2>/dev/null || true

    # Install proot-distro
    if command -v proot-distro &>/dev/null || [[ -f "$PREFIX/bin/proot-distro" ]]; then
        log_success "proot-distro ready"
    else
        log_info "Installing proot-distro..."
        pkg install -y proot-distro
        log_success "proot-distro installed"
    fi

    # Install curl
    if command -v curl &>/dev/null; then
        log_success "curl ready"
    else
        log_info "Installing curl..."
        pkg install -y curl
        log_success "curl installed"
    fi

    # Install python3 (required for API server)
    if command -v python3 &>/dev/null; then
        log_success "python3 ready"
    else
        log_info "Installing python3..."
        pkg install -y python
        log_success "python3 installed"
    fi
}

# =============================================================================
# Directory Setup
# =============================================================================

setup_directories() {
    log_step "Directories"

    mkdir -p "$DATA_DIR"
    mkdir -p "$MODELS_DIR"
    mkdir -p "$POCKETAI_ROOT/docs"

    chmod +x "$POCKETAI_ROOT/bin/pai" 2>/dev/null || true
    chmod +x "$POCKETAI_ROOT/core/engine.sh" 2>/dev/null || true

    log_success "Directories ready"
}

# =============================================================================
# Container Setup
# =============================================================================

setup_container() {
    log_step "Container (Alpine)"

    # Check if exists
    if [[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$CONTAINER_NAME" ]]; then
        log_success "Container exists"
        return 0
    fi

    log_info "Creating Alpine container (~50MB)..."
    proot-distro install alpine --override-alias "$CONTAINER_NAME"
    log_success "Container created"
}

# =============================================================================
# Engine Setup
# =============================================================================

setup_engine() {
    log_step "Engine (llamafile)"

    local llamafile_bin="$DATA_DIR/llamafile"

    if [[ -f "$llamafile_bin" ]]; then
        log_success "Engine exists"
    else
        log_info "Downloading llamafile (~5MB)..."
        curl -L --progress-bar -o "$llamafile_bin" "$LLAMAFILE_URL"
        chmod +x "$llamafile_bin"
        log_success "Engine downloaded"
    fi

    # Setup in container
    local container_root="$PREFIX/var/lib/proot-distro/installed-rootfs/$CONTAINER_NAME"
    mkdir -p "$container_root/opt/pocketai/bin"
    mkdir -p "$container_root/opt/pocketai/models"

    cp "$llamafile_bin" "$container_root/opt/pocketai/bin/llamafile"
    chmod +x "$container_root/opt/pocketai/bin/llamafile"

    log_success "Engine ready"
}

# =============================================================================
# PATH & Environment Setup
# =============================================================================

setup_environment() {
    log_step "Environment"

    # Create environment file
    cat > "$ENV_FILE" << EOF
# PocketAI Environment
# Source this file or restart terminal after setup

export POCKETAI_ROOT="$POCKETAI_ROOT"
export PATH="\$POCKETAI_ROOT/bin:\$PATH"

# Aliases
alias pai='$POCKETAI_ROOT/bin/pai'
EOF

    log_success "Created $ENV_FILE"

    # Add to shell rc if not already there
    if ! grep -q "pocketai_env" "$SHELL_RC" 2>/dev/null; then
        echo '' >> "$SHELL_RC"
        echo '# PocketAI' >> "$SHELL_RC"
        echo '[[ -f ~/.pocketai_env ]] && source ~/.pocketai_env' >> "$SHELL_RC"
        log_success "Added to $SHELL_RC"
    else
        log_success "Already in $SHELL_RC"
    fi

    # Add API auto-start on Termux launch
    if ! grep -q "pai api web" "$SHELL_RC" 2>/dev/null; then
        echo '' >> "$SHELL_RC"
        echo '# Auto-start PocketAI API server' >> "$SHELL_RC"
        echo 'if [[ -z "$(pgrep -f api_server.py)" ]]; then' >> "$SHELL_RC"
        echo '    pai api web &>/dev/null &' >> "$SHELL_RC"
        echo '    echo "PocketAI API started in background"' >> "$SHELL_RC"
        echo 'fi' >> "$SHELL_RC"
        log_success "API auto-start enabled"
    else
        log_success "API auto-start already configured"
    fi

    # Export for current session
    export POCKETAI_ROOT="$POCKETAI_ROOT"
    export PATH="$POCKETAI_ROOT/bin:$PATH"
}

# =============================================================================
# Config Setup
# =============================================================================

setup_config() {
    local config_file="$DATA_DIR/config"

    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
# PocketAI Configuration
active_model=
threads=4
ctx_size=2048
EOF
    fi
}

# =============================================================================
# Model Download (Optional)
# =============================================================================

setup_model() {
    log_step "Model Setup"

    # Check RAM
    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')

    echo ""
    echo "Your RAM: ${ram_mb}MB"
    echo ""
    echo "Available models:"
    echo ""
    printf "  ${BOLD}%-4s %-14s %-8s %-10s %s${RESET}\n" "#" "MODEL" "SIZE" "MIN RAM" "STATUS"
    echo "  ───────────────────────────────────────────────────────────"

    # Model options based on RAM - Best SLMs first
    echo -n "  1.   smollm2       270MB    400MB     "
    [[ $ram_mb -ge 400 ]] && echo -e "${GREEN}Best tiny${RESET}" || echo -e "${DIM}needs more RAM${RESET}"

    echo -n "  2.   qwen2         400MB    512MB     "
    [[ $ram_mb -ge 512 ]] && echo -e "${GREEN}Smart tiny${RESET}" || echo -e "${DIM}needs more RAM${RESET}"

    echo -n "  3.   smollm2-1b    1.0GB    1GB       "
    [[ $ram_mb -ge 1024 ]] && echo -e "${GREEN}Best light${RESET}" || echo -e "${DIM}needs more RAM${RESET}"

    echo -n "  4.   qwen2-1b      1.0GB    1.2GB     "
    [[ $ram_mb -ge 1200 ]] && echo -e "${GREEN}Smartest small${RESET}" || echo -e "${DIM}needs more RAM${RESET}"

    echo -n "  5.   qwen2-3b      2.0GB    3GB       "
    [[ $ram_mb -ge 3072 ]] && echo -e "${GREEN}Best medium${RESET}" || echo -e "${DIM}needs more RAM${RESET}"

    echo -n "  6.   gemma2b       1.4GB    2GB       "
    [[ $ram_mb -ge 2048 ]] && echo -e "${GREEN}Google${RESET}" || echo -e "${DIM}needs more RAM${RESET}"

    echo ""
    echo "  0.   Skip - Download later with 'pai install <model>'"
    echo ""

    echo -n "Choose [0-6]: "
    read -r choice

    local model=""
    case "$choice" in
        1) model="smollm2" ;;
        2) model="qwen2" ;;
        3) model="smollm2-1b" ;;
        4) model="qwen2-1b" ;;
        5) model="qwen2-3b" ;;
        6) model="gemma2b" ;;
        0|"") log_info "Skipped. Run 'pai models' to see available models"; return ;;
        *) log_warn "Invalid choice. Skipping."; return ;;
    esac

    # Source engine and install model
    source "$POCKETAI_ROOT/core/engine.sh"
    model_install "$model"
}

# =============================================================================
# Summary
# =============================================================================

show_summary() {
    log_step "Setup Complete!"

    # Auto-source for current session
    source "$ENV_FILE" 2>/dev/null || true
    log_success "Environment activated"

    echo ""
    echo -e "${BOLD}PocketAI is ready!${RESET}"
    echo ""
    echo -e "${BOLD}Quick Start:${RESET}"
    echo "  pai help              # Show all commands"
    echo "  pai models            # List available models"
    echo "  pai install qwen2     # Download a model"
    echo "  pai chat              # Start chatting"
    echo "  pai api web           # Start API server"
    echo ""
    echo -e "${DIM}Note: Run 'source ~/.pocketai_env' in new terminals${RESET}"
    echo ""
}

# =============================================================================
# Uninstall
# =============================================================================

uninstall() {
    show_banner
    log_step "Uninstalling PocketAI"

    echo ""
    echo -e "${YELLOW}This will remove:${RESET}"
    echo "  • PocketAI container (pocketai)"
    echo "  • Downloaded models"
    echo "  • Configuration files"
    echo "  • Environment settings from ~/.bashrc"
    echo ""
    echo -n "Are you sure? [y/N]: "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        exit 0
    fi

    # Stop API server
    if pgrep -f api_server.py &>/dev/null; then
        log_info "Stopping API server..."
        pkill -f api_server.py 2>/dev/null || true
        log_success "API stopped"
    fi

    # Remove container
    if proot-distro list 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        log_info "Removing container..."
        proot-distro remove "$CONTAINER_NAME" 2>/dev/null || true
        log_success "Container removed"
    fi

    # Remove models
    if [[ -d "$MODELS_DIR" ]] && [[ -n "$(ls -A "$MODELS_DIR" 2>/dev/null)" ]]; then
        log_info "Removing models..."
        rm -rf "$MODELS_DIR"/*.gguf 2>/dev/null || true
        log_success "Models removed"
    fi

    # Remove data files
    log_info "Removing data files..."
    rm -f "$DATA_DIR/llamafile"* 2>/dev/null || true
    rm -f "$DATA_DIR/config" 2>/dev/null || true
    rm -f "$DATA_DIR/api.pid" 2>/dev/null || true
    log_success "Data files removed"

    # Remove environment file
    rm -f "$ENV_FILE" 2>/dev/null || true
    log_success "Environment file removed"

    # Clean ~/.bashrc
    if [[ -f "$SHELL_RC" ]]; then
        log_info "Cleaning ~/.bashrc..."
        sed -i '/# PocketAI/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '/pocketai_env/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '/# Auto-start PocketAI/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '/pgrep -f api_server.py/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '/pai api web/d' "$SHELL_RC" 2>/dev/null || true
        sed -i '/PocketAI API started/d' "$SHELL_RC" 2>/dev/null || true
        log_success "Cleaned ~/.bashrc"
    fi

    log_step "Uninstall Complete!"
    echo ""
    echo -e "${DIM}Note: PocketAI source files remain in $POCKETAI_ROOT${RESET}"
    echo -e "${DIM}To fully remove, run: rm -rf $POCKETAI_ROOT${RESET}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Handle uninstall flag
    if [[ "${1:-}" == "--uninstall" ]] || [[ "${1:-}" == "-u" ]] || [[ "${1:-}" == "uninstall" ]]; then
        uninstall
        exit 0
    fi

    show_banner

    check_system
    install_dependencies
    setup_directories
    setup_container
    setup_engine
    setup_environment
    setup_config
    setup_model
    show_summary
}

main "$@"
