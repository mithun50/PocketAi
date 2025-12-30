#!/data/data/com.termux/files/usr/bin/bash
#
# PocketAI v2 - Unified Core Engine
# Llamafile-powered local AI for Android
#
# Single-file engine handling runtime, models, and inference
#

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

readonly VERSION="2.0.0"
readonly LLAMAFILE_VERSION="0.9.3"
readonly LLAMAFILE_URL="https://github.com/Mozilla-Ocho/llamafile/releases/download/${LLAMAFILE_VERSION}/llamafile-${LLAMAFILE_VERSION}"

# Paths (set by init or caller)
POCKETAI_ROOT="${POCKETAI_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DATA_DIR="$POCKETAI_ROOT/data"
MODELS_DIR="$POCKETAI_ROOT/models"
CONFIG_FILE="$DATA_DIR/config"

# Container settings
CONTAINER_NAME="pocketai"
CONTAINER_BIN="/opt/pocketai/bin/llamafile"
CONTAINER_MODELS="/opt/pocketai/models"

# =============================================================================
# Output Helpers
# =============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly RESET='\033[0m'

log_info()    { echo -e "${BLUE}▸${RESET} $1"; }
log_success() { echo -e "${GREEN}✓${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}!${RESET} $1"; }
log_error()   { echo -e "${RED}✗${RESET} $1" >&2; }
log_step()    { echo -e "\n${BOLD}${CYAN}$1${RESET}"; }

# =============================================================================
# Configuration
# =============================================================================

config_init() {
    mkdir -p "$DATA_DIR" "$MODELS_DIR"
    [[ -f "$CONFIG_FILE" ]] || cat > "$CONFIG_FILE" << 'EOF'
# PocketAI Configuration
active_model=
threads=4
ctx_size=2048
EOF
}

config_get() {
    local key="$1" default="${2:-}"
    if [[ -f "$CONFIG_FILE" ]]; then
        grep "^${key}=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2- || echo "$default"
    else
        echo "$default"
    fi
}

config_set() {
    local key="$1" value="$2"
    config_init
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
}

# =============================================================================
# Container Management
# =============================================================================

container_exists() {
    # Check rootfs directory directly (more reliable than parsing list output)
    [[ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/$CONTAINER_NAME" ]]
}

container_create() {
    if container_exists; then
        log_success "Container exists"
        return 0
    fi

    log_info "Creating Alpine container..."
    proot-distro install alpine --override-alias "$CONTAINER_NAME"
    log_success "Container created"
}

container_exec() {
    proot-distro login "$CONTAINER_NAME" -- sh -c "$1"
}

container_run() {
    local model_path="$1"
    shift
    # Use stdbuf for unbuffered output if available
    local unbuf=""
    command -v stdbuf &>/dev/null && unbuf="stdbuf -o0"
    proot-distro login "$CONTAINER_NAME" \
        --bind "$POCKETAI_ROOT/data:/opt/pocketai/data" \
        --bind "$POCKETAI_ROOT/models:/opt/pocketai/models" \
        -- $unbuf "$CONTAINER_BIN" -m "$model_path" "$@"
}

# =============================================================================
# Engine Installation
# =============================================================================

engine_installed() {
    [[ -f "$DATA_DIR/llamafile" ]] && container_exists
}

engine_install() {
    log_step "Installing PocketAI Engine"

    # Create container
    container_create

    # Download llamafile
    if [[ -f "$DATA_DIR/llamafile" ]]; then
        log_success "Engine binary exists"
    else
        log_info "Downloading llamafile (~5MB)..."
        curl -L --progress-bar -o "$DATA_DIR/llamafile" "$LLAMAFILE_URL"
        chmod +x "$DATA_DIR/llamafile"
        log_success "Engine downloaded"
    fi

    # Setup in container
    log_info "Setting up container..."
    container_exec "mkdir -p /opt/pocketai/bin /opt/pocketai/models /opt/pocketai/data"

    # Copy binary to container (workaround for bind mount issues)
    cp "$DATA_DIR/llamafile" "$DATA_DIR/llamafile-container"
    container_exec "cp /opt/pocketai/data/llamafile-container /opt/pocketai/bin/llamafile && chmod +x /opt/pocketai/bin/llamafile"

    log_success "Engine installed"
}

engine_version() {
    echo "PocketAI v${VERSION} (llamafile ${LLAMAFILE_VERSION})"
}

# =============================================================================
# Model Registry
# =============================================================================

# Built-in model catalog: name=description|size|min_ram_mb|url
declare -A MODEL_CATALOG=(
    # Ultra-light (< 1GB RAM) - Best small models 2025
    ["qwen3"]="Qwen3 0.6B ⭐NEW 2025|400MB|512|https://huggingface.co/unsloth/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_K_M.gguf"
    ["smollm2"]="SmolLM2 360M (Best tiny)|270MB|400|https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF/resolve/main/SmolLM2-360M-Instruct-Q8_0.gguf"
    ["qwen2"]="Qwen2.5 0.5B (Smart)|400MB|512|https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"
    ["qwen"]="Qwen 0.5B Chat|395MB|512|https://huggingface.co/Qwen/Qwen1.5-0.5B-Chat-GGUF/resolve/main/qwen1_5-0_5b-chat-q4_k_m.gguf"

    # Light (1-2GB RAM) - Best quality/size 2025
    ["llama3.2"]="Llama 3.2 1B ⭐NEW 2025|700MB|1024|https://huggingface.co/hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF/resolve/main/llama-3.2-1b-instruct-q4_k_m.gguf"
    ["llama3.2-3b"]="Llama 3.2 3B ⭐NEW 2025|2.0GB|2048|https://huggingface.co/hugging-quants/Llama-3.2-3B-Instruct-Q4_K_M-GGUF/resolve/main/llama-3.2-3b-instruct-q4_k_m.gguf"
    ["smollm2-1b"]="SmolLM2 1.7B (Best light)|1.0GB|1024|https://huggingface.co/bartowski/SmolLM2-1.7B-Instruct-GGUF/resolve/main/SmolLM2-1.7B-Instruct-Q4_K_M.gguf"
    ["qwen2-1b"]="Qwen2.5 1.5B (Smartest small)|1.0GB|1200|https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
    ["tinyllama"]="TinyLlama 1.1B|669MB|1024|https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

    # Medium (2-4GB RAM)
    ["gemma2b"]="Gemma 2 2B|1.4GB|2048|https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
    ["phi2"]="Microsoft Phi-2 2.7B|1.6GB|3072|https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
    ["qwen2-3b"]="Qwen2.5 3B (Best medium)|2.0GB|3072|https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"
    ["stablelm"]="StableLM Zephyr 3B|2.0GB|4096|https://huggingface.co/TheBloke/stablelm-zephyr-3b-GGUF/resolve/main/stablelm-zephyr-3b.Q4_K_M.gguf"
)

model_list_available() {
    log_step "Available Models"
    echo ""

    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')

    printf "  ${BOLD}%-12s %-22s %-8s %-8s${RESET}\n" "NAME" "DESCRIPTION" "SIZE" "RAM"
    echo "  ────────────────────────────────────────────────────────"

    # Sort by RAM requirement (smallest first) - includes 2025 models
    for name in smollm2 qwen3 qwen2 qwen llama3.2 smollm2-1b qwen2-1b tinyllama llama3.2-3b gemma2b phi2 qwen2-3b stablelm; do
        [[ -z "${MODEL_CATALOG[$name]:-}" ]] && continue
        IFS='|' read -r desc size min_ram url <<< "${MODEL_CATALOG[$name]}"

        local status=""
        if [[ $ram_mb -lt $min_ram ]]; then
            status="${DIM}"
        elif [[ $ram_mb -lt $((min_ram + 512)) ]]; then
            status="${YELLOW}"
        else
            status="${GREEN}"
        fi

        printf "  ${status}%-12s %-22s %-8s %sMB${RESET}\n" "$name" "$desc" "$size" "$min_ram"
    done

    echo ""
    echo -e "  ${DIM}Your RAM: ${ram_mb}MB${RESET}"
    echo ""

    # Recommendation - prefer 2025 models
    if [[ $ram_mb -lt 1024 ]]; then
        log_info "Recommended: ${BOLD}qwen3${RESET} ⭐ (best tiny 2025)"
    elif [[ $ram_mb -lt 2048 ]]; then
        log_info "Recommended: ${BOLD}llama3.2${RESET} ⭐ (best small 2025)"
    elif [[ $ram_mb -lt 4096 ]]; then
        log_info "Recommended: ${BOLD}llama3.2-3b${RESET} ⭐ (best medium 2025)"
    else
        log_info "Recommended: ${BOLD}llama3.2-3b${RESET} or ${BOLD}qwen2-3b${RESET}"
    fi
    echo ""
}

model_list_installed() {
    log_step "Installed Models"
    echo ""

    local found=0
    for f in "$MODELS_DIR"/*.gguf; do
        [[ -f "$f" ]] || continue
        found=1
        local name=$(basename "$f")
        local size=$(du -h "$f" | cut -f1)
        local active=""
        [[ "$(config_get active_model)" == "$f" ]] && active=" ${GREEN}[active]${RESET}"
        echo -e "  $name ($size)$active"
    done

    [[ $found -eq 0 ]] && echo "  No models installed"
    echo ""
}

model_install() {
    local name="$1"

    # Check catalog
    if [[ -z "${MODEL_CATALOG[$name]:-}" ]]; then
        log_error "Unknown model: $name"
        echo "Available: ${!MODEL_CATALOG[*]}"
        return 1
    fi

    IFS='|' read -r desc size min_ram url <<< "${MODEL_CATALOG[$name]}"
    local filename=$(basename "$url")
    local filepath="$MODELS_DIR/$filename"

    # RAM check with warning
    local ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $ram_mb -lt $min_ram ]]; then
        log_warn "Your RAM (${ram_mb}MB) may be low for this model (needs ${min_ram}MB)"
        log_warn "Model may run slowly or crash. Continue anyway? [y/N]"
        read -r response
        [[ ! "$response" =~ ^[Yy] ]] && return 1
    fi

    if [[ -f "$filepath" ]]; then
        log_success "Model already installed: $filename"
        return 0
    fi

    log_step "Installing $desc"
    log_info "Downloading $filename ($size)..."

    curl -L --progress-bar -o "$filepath" "$url"

    log_success "Model installed: $filename"

    # Auto-activate if first model
    if [[ -z "$(config_get active_model)" ]]; then
        config_set active_model "$filepath"
        log_info "Model activated"
    fi
}

model_activate() {
    local name="$1"
    local found=""

    # Find model file
    for f in "$MODELS_DIR"/*.gguf; do
        [[ -f "$f" ]] || continue
        if [[ "$f" == *"$name"* ]]; then
            found="$f"
            break
        fi
    done

    if [[ -z "$found" ]]; then
        log_error "Model not found: $name"
        return 1
    fi

    config_set active_model "$found"
    log_success "Activated: $(basename "$found")"
}

model_remove() {
    local name="$1"

    for f in "$MODELS_DIR"/*.gguf; do
        [[ -f "$f" ]] || continue
        if [[ "$f" == *"$name"* ]]; then
            rm -f "$f"
            log_success "Removed: $(basename "$f")"

            # Clear if active
            [[ "$(config_get active_model)" == "$f" ]] && config_set active_model ""
            return 0
        fi
    done

    log_error "Model not found: $name"
    return 1
}

# =============================================================================
# Inference
# =============================================================================

infer() {
    local prompt="$1"
    local model_path
    model_path=$(config_get active_model)

    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        log_error "No model active. Run: pai install qwen2"
        return 1
    fi

    local threads=$(config_get threads 4)
    local ctx_size=$(config_get ctx_size 2048)
    local container_model="$CONTAINER_MODELS/$(basename "$model_path")"
    local model_name=$(basename "$model_path" | tr '[:upper:]' '[:lower:]')

    # Token limits - Qwen3 needs more for thinking mode
    local max_tokens=40
    if [[ "$model_name" == *"qwen3"* ]]; then
        max_tokens=150  # Extra tokens for <think> block
        if [[ "$prompt" =~ (code|program|write|implement|function|script|algorithm|create|explain|describe|what|how|why) ]]; then
            max_tokens=300
        fi
    elif [[ "$prompt" =~ (code|program|write|implement|function|script|algorithm|create|explain|describe|what|how|why) ]]; then
        max_tokens=200
    fi

    # Qwen3-specific parameters (no default system prompt, adjusted temp)
    if [[ "$model_name" == *"qwen3"* ]]; then
        container_run "$container_model" \
            -t "$threads" \
            -c "$ctx_size" \
            -p "<|im_start|>system
You are a helpful assistant. Answer briefly and directly.<|im_end|>
<|im_start|>user
$prompt<|im_end|>
<|im_start|>assistant
" \
            -n "$max_tokens" \
            --temp 0.7 \
            --top-k 20 \
            --top-p 0.8 \
            -r "<|im_end|>" \
            -r "<|im_start|>" \
            -r "User:" \
            -r "Human:" \
            --log-disable \
            --no-display-prompt 2>/dev/null | awk 'BEGIN{RS="</think>"} NR==2{gsub(/^[[:space:]]+/,""); print}' | sed 's/<|im_end|>//g' | head -c 500
    else
        # Original parameters for other models (Qwen2, SmolLM, Llama, etc.)
        container_run "$container_model" \
            -t "$threads" \
            -c "$ctx_size" \
            -p "<|im_start|>system
RULES: Answer in 1-2 sentences MAX. No questions back. No offers to help more. Just answer directly.<|im_end|>
<|im_start|>user
$prompt<|im_end|>
<|im_start|>assistant
" \
            -n "$max_tokens" \
            --temp 0.1 \
            --repeat-penalty 2.5 \
            --top-k 10 \
            --top-p 0.7 \
            -r "<|im_end|>" \
            -r "<|im_start|>" \
            -r "?" \
            -r "User:" \
            -r "Human:" \
            -r "Let me" \
            -r "Please" \
            -r "feel free" \
            -r "Is there" \
            -r "Is it" \
            --log-disable \
            --no-display-prompt 2>/dev/null | head -c 500 | sed 's/<|im_end|>//g'
    fi
}

# Minimal cleanup - just stop at turn markers
cut_response() {
    sed -n '/^###/q; /^User:/q; /^Human:/q; /^<|/q; p'
}

# Convert LaTeX to readable Unicode
cleanup_latex() {
    sed -e 's/\\times/×/g' \
        -e 's/\\div/÷/g' \
        -e 's/\\pm/±/g' \
        -e 's/\\leq/≤/g' \
        -e 's/\\geq/≥/g' \
        -e 's/\\neq/≠/g' \
        -e 's/\\approx/≈/g' \
        -e 's/\\infty/∞/g' \
        -e 's/\\sqrt/√/g' \
        -e 's/\\alpha/α/g' \
        -e 's/\\beta/β/g' \
        -e 's/\\gamma/γ/g' \
        -e 's/\\delta/δ/g' \
        -e 's/\\pi/π/g' \
        -e 's/\\theta/θ/g' \
        -e 's/\\lambda/λ/g' \
        -e 's/\\mu/μ/g' \
        -e 's/\\sigma/σ/g' \
        -e 's/\\omega/ω/g' \
        -e 's/\\frac{\([^}]*\)}{\([^}]*\)}/\1\/\2/g' \
        -e 's/\\text{\([^}]*\)}/\1/g' \
        -e 's/\\\[ *//g' \
        -e 's/ *\\\]//g' \
        -e 's/\\( *//g' \
        -e 's/ *\\)//g' \
        -e 's/\\cdot/·/g'
}

chat_interactive() {
    local model_path
    model_path=$(config_get active_model)

    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        log_error "No model active. Run: pai install tinyllama"
        return 1
    fi

    log_info "Chat with $(basename "$model_path")"
    log_info "Commands: 'exit' to quit, '/clear' to reset context"
    log_info "Context: Remembers last 4 exchanges"
    echo ""

    local threads=$(config_get threads 4)
    local ctx_size=$(config_get ctx_size 2048)
    local container_model="$CONTAINER_MODELS/$(basename "$model_path")"

    # Use temp file for history (Termux-compatible path)
    local tmp_dir="${TMPDIR:-$HOME/.cache/pocketai}"
    mkdir -p "$tmp_dir"
    local history_file="$tmp_dir/pocketai_history_$$"
    echo -n "" > "$history_file"
    trap "rm -f '$history_file'" EXIT

    while true; do
        echo -ne "${CYAN}You>${RESET} "
        read -r user_input

        # Exit conditions
        [[ -z "$user_input" ]] && continue
        [[ "$user_input" == "exit" || "$user_input" == "quit" || "$user_input" == "/exit" ]] && break

        # Clear history command
        if [[ "$user_input" == "/clear" ]]; then
            echo -n "" > "$history_file"
            log_success "Context cleared"
            continue
        fi

        # Read history and build context
        local history=""
        if [[ -s "$history_file" ]]; then
            history=$(cat "$history_file")
        fi

        # Detect model type
        local model_name=$(basename "$model_path" | tr '[:upper:]' '[:lower:]')

        # Token limits - Qwen3 needs more for thinking mode
        local max_tokens=40
        if [[ "$model_name" == *"qwen3"* ]]; then
            max_tokens=150
            if [[ "$user_input" =~ (code|program|write|implement|function|script|algorithm|create|explain|describe|what|how|why) ]]; then
                max_tokens=300
            fi
        elif [[ "$user_input" =~ (code|program|write|implement|function|script|algorithm|create|explain|describe|what|how|why) ]]; then
            max_tokens=200
        fi

        echo -ne "${GREEN}AI>${RESET} "

        # Stream response
        local response_file="$tmp_dir/response_$$"

        # Qwen3-specific chat (adjusted parameters, simple system prompt)
        if [[ "$model_name" == *"qwen3"* ]]; then
            local context="<|im_start|>system
You are a helpful assistant. Answer briefly and directly.<|im_end|>
${history}<|im_start|>user
$user_input<|im_end|>
<|im_start|>assistant
"
            container_run "$container_model" \
                -t "$threads" \
                -c "$ctx_size" \
                -p "$context" \
                -n "$max_tokens" \
                --temp 0.7 \
                --top-k 20 \
                --top-p 0.8 \
                -r "<|im_end|>" \
                -r "<|im_start|>" \
                -r "User:" \
                -r "Human:" \
                --log-disable \
                --no-display-prompt 2>/dev/null > "$response_file"
            # Strip thinking block and display
            sed -n '/<\/think>/,$ p' "$response_file" | sed '1d; s/<|im_end|>//g' | head -c 500
            # Update response file with clean content
            local clean_response=$(sed -n '/<\/think>/,$ p' "$response_file" | sed '1d; s/<|im_end|>//g' | head -c 500)
            echo "$clean_response" > "$response_file"
            # Fake tee output - already displayed above
        else
            # Original parameters for other models
            local context="<|im_start|>system
RULES: Answer in 1-2 sentences MAX. No questions back. No offers to help more. Just answer directly.<|im_end|>
${history}<|im_start|>user
$user_input<|im_end|>
<|im_start|>assistant
"
            container_run "$container_model" \
                -t "$threads" \
                -c "$ctx_size" \
                -p "$context" \
                -n "$max_tokens" \
                --temp 0.1 \
                --repeat-penalty 2.5 \
                --top-k 10 \
                --top-p 0.7 \
                -r "<|im_end|>" \
                -r "<|im_start|>" \
                -r "?" \
                -r "User:" \
                -r "Human:" \
                -r "Let me" \
                -r "Please" \
                -r "feel free" \
                -r "Is there" \
                -r "Is it" \
                --log-disable \
                --no-display-prompt 2>/dev/null | head -c 500 | sed 's/<|im_end|>//g' | tee "$response_file"
        fi

        local response=$(cat "$response_file")
        rm -f "$response_file"
        echo ""

        # Append to history file (ChatML format)
        echo "<|im_start|>user
$user_input<|im_end|>
<|im_start|>assistant
$response<|im_end|>
" >> "$history_file"

        # Trim history to last 4 exchanges (keep file under ~2000 bytes)
        if [[ $(wc -c < "$history_file") -gt 2000 ]]; then
            tail -c 1500 "$history_file" > "${history_file}.tmp"
            mv "${history_file}.tmp" "$history_file"
        fi
    done

    rm -f "$history_file"
    echo ""
    log_info "Chat ended"
}

# =============================================================================
# System Info
# =============================================================================

system_info() {
    log_step "System Information"
    echo ""
    echo "  PocketAI: v${VERSION}"
    echo "  Engine:   llamafile ${LLAMAFILE_VERSION}"
    echo "  Arch:     $(uname -m)"
    echo "  RAM:      $(free -h | awk '/^Mem:/{print $2}')"
    echo "  Storage:  $(df -h "$HOME" | tail -1 | awk '{print $4}') free"

    if engine_installed; then
        echo -e "  Status:   ${GREEN}Ready${RESET}"
    else
        echo -e "  Status:   ${YELLOW}Not installed${RESET}"
    fi

    local model=$(config_get active_model)
    if [[ -n "$model" ]]; then
        echo "  Model:    $(basename "$model")"
    fi
    echo ""
}

# =============================================================================
# Export Functions
# =============================================================================

# Make functions available when sourced
export -f config_get config_set
export -f container_exists container_create container_exec container_run
export -f engine_installed engine_install engine_version
export -f model_list_available model_list_installed model_install model_activate model_remove
export -f infer chat_interactive system_info
export -f log_info log_success log_warn log_error log_step
