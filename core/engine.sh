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
    local requested_tokens="${2:-}"  # Optional: override max_tokens
    local model_path
    model_path=$(config_get active_model)

    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        log_error "No model active. Run: pai install qwen3"
        return 1
    fi

    local threads=$(config_get threads 4)
    local ctx_size=$(config_get ctx_size 2048)
    local container_model="$CONTAINER_MODELS/$(basename "$model_path")"
    local model_name=$(basename "$model_path")
    local family=$(get_model_family "$model_name")

    # Build model-specific prompt
    local formatted_prompt=$(build_prompt "$model_name" "$prompt")

    # Token limits - Qwen3 has no limit (uses stop sequences)
    # Default: 500 tokens (~375 words) - enough for most responses
    local max_tokens=500
    if [[ -n "$requested_tokens" ]]; then
        max_tokens="$requested_tokens"  # Use requested tokens if provided
    elif [[ "$family" == "qwen3" ]]; then
        max_tokens=""  # No limit for Qwen3 (uses stop sequences)
    elif [[ "$prompt" =~ (code|program|write|implement|function|script|algorithm|example|binary|search|sort) ]]; then
        max_tokens=800  # More tokens for code/algorithm requests
    elif [[ "$prompt" =~ (create|explain|describe|what|how|why|list|steps|detailed) ]]; then
        max_tokens=600  # Extended for explanations
    fi

    # Get model-specific parameters
    local model_args=$(get_model_args "$model_name")

    # Build stop sequence arguments
    local stop_args=""
    while IFS= read -r stop_seq; do
        [[ -n "$stop_seq" ]] && stop_args="$stop_args -r \"$stop_seq\""
    done <<< "$(get_stop_sequences "$model_name")"

    # Run inference with model-specific settings
    if [[ "$family" == "qwen3" ]]; then
        # Qwen3: No token limit, handle thinking blocks
        eval container_run '"$container_model"' \
            -t '"$threads"' \
            -c '"$ctx_size"' \
            -p '"$formatted_prompt"' \
            $model_args \
            $stop_args \
            --log-disable \
            --no-display-prompt 2>/dev/null | \
            awk 'BEGIN{RS="</think>"} NR==2{gsub(/^[[:space:]]+/,""); print}' | \
            clean_response
    else
        # Other models: Use token limit
        local token_arg=""
        [[ -n "$max_tokens" ]] && token_arg="-n $max_tokens"

        eval container_run '"$container_model"' \
            -t '"$threads"' \
            -c '"$ctx_size"' \
            -p '"$formatted_prompt"' \
            $token_arg \
            $model_args \
            $stop_args \
            --log-disable \
            --no-display-prompt 2>/dev/null | \
            clean_response
    fi
}

# Streaming inference - unbuffered output for real-time token streaming
infer_stream() {
    local prompt="$1"
    local requested_tokens="${2:-}"
    local model_path
    model_path=$(config_get active_model)

    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        echo "Error: No model active"
        return 1
    fi

    local threads=$(config_get threads 4)
    local ctx_size=$(config_get ctx_size 2048)
    local container_model="$CONTAINER_MODELS/$(basename "$model_path")"
    local model_name=$(basename "$model_path")
    local family=$(get_model_family "$model_name")

    # Build prompt
    local formatted_prompt=$(build_prompt "$model_name" "$prompt")

    # Token limits
    local max_tokens=500
    if [[ -n "$requested_tokens" ]]; then
        max_tokens="$requested_tokens"
    elif [[ "$family" == "qwen3" ]]; then
        max_tokens=""
    elif [[ "$prompt" =~ (code|program|write|implement|function|script) ]]; then
        max_tokens=800
    fi

    local model_args=$(get_model_args "$model_name")

    # Stop sequences
    local stop_args=""
    while IFS= read -r stop_seq; do
        [[ -n "$stop_seq" ]] && stop_args="$stop_args -r \"$stop_seq\""
    done <<< "$(get_stop_sequences "$model_name")"

    # Token limit arg
    local token_arg=""
    [[ -n "$max_tokens" ]] && token_arg="-n $max_tokens"

    # Run inference - llamafile outputs tokens as they're generated
    # The Python PTY wrapper handles unbuffering
    proot-distro login "$CONTAINER_NAME" \
        --bind "$POCKETAI_ROOT/data:/opt/pocketai/data" \
        --bind "$POCKETAI_ROOT/models:/opt/pocketai/models" \
        -- "$CONTAINER_BIN" -m "$container_model" \
        -t "$threads" \
        -c "$ctx_size" \
        -p "$formatted_prompt" \
        $token_arg \
        $model_args \
        $stop_args \
        --log-disable \
        --no-display-prompt 2>/dev/null
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

# =============================================================================
# Model-Specific Prompt Templates
# =============================================================================

# Detect model family from filename
get_model_family() {
    local model_name="$1"
    model_name=$(echo "$model_name" | tr '[:upper:]' '[:lower:]')

    if [[ "$model_name" == *"qwen3"* ]]; then
        echo "qwen3"
    elif [[ "$model_name" == *"qwen"* ]]; then
        echo "qwen"  # Qwen, Qwen2, Qwen2.5
    elif [[ "$model_name" == *"smollm"* ]]; then
        echo "smollm"
    elif [[ "$model_name" == *"llama-3"* || "$model_name" == *"llama3"* ]]; then
        echo "llama3"
    elif [[ "$model_name" == *"tinyllama"* ]]; then
        echo "tinyllama"
    elif [[ "$model_name" == *"gemma"* ]]; then
        echo "gemma"
    elif [[ "$model_name" == *"phi-2"* || "$model_name" == *"phi2"* ]]; then
        echo "phi2"
    elif [[ "$model_name" == *"stablelm"* || "$model_name" == *"zephyr"* ]]; then
        echo "zephyr"
    else
        echo "chatml"  # Default fallback
    fi
}

# Build prompt with correct template for model
build_prompt() {
    local model_name="$1"
    local user_message="$2"
    local history="${3:-}"
    local family=$(get_model_family "$model_name")

    case "$family" in
        qwen3|qwen|smollm)
            # ChatML format (Qwen, Qwen2, Qwen3, SmolLM2)
            echo "${history}<|im_start|>user
${user_message}<|im_end|>
<|im_start|>assistant
"
            ;;
        llama3)
            # Llama 3.x format
            if [[ -z "$history" ]]; then
                echo "<|begin_of_text|><|start_header_id|>user<|end_header_id|>

${user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"
            else
                echo "${history}<|start_header_id|>user<|end_header_id|>

${user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"
            fi
            ;;
        tinyllama)
            # TinyLlama format
            echo "${history}<|user|>
${user_message}</s>
<|assistant|>
"
            ;;
        gemma)
            # Gemma format (no system prompt support)
            echo "${history}<start_of_turn>user
${user_message}<end_of_turn>
<start_of_turn>model
"
            ;;
        phi2)
            # Phi-2 Instruct format (not instruction-tuned, simple format)
            echo "Instruct: ${user_message}
Output: "
            ;;
        zephyr)
            # Zephyr/StableLM format
            echo "${history}<|user|>
${user_message}<|endoftext|>
<|assistant|>
"
            ;;
        *)
            # Default to ChatML
            echo "${history}<|im_start|>user
${user_message}<|im_end|>
<|im_start|>assistant
"
            ;;
    esac
}

# Build history entry for multi-turn chat
build_history_entry() {
    local model_name="$1"
    local user_message="$2"
    local assistant_response="$3"
    local family=$(get_model_family "$model_name")

    case "$family" in
        qwen3|qwen|smollm)
            echo "<|im_start|>user
${user_message}<|im_end|>
<|im_start|>assistant
${assistant_response}<|im_end|>
"
            ;;
        llama3)
            echo "<|start_header_id|>user<|end_header_id|>

${user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

${assistant_response}<|eot_id|>
"
            ;;
        tinyllama)
            echo "<|user|>
${user_message}</s>
<|assistant|>
${assistant_response}</s>
"
            ;;
        gemma)
            echo "<start_of_turn>user
${user_message}<end_of_turn>
<start_of_turn>model
${assistant_response}<end_of_turn>
"
            ;;
        phi2)
            # Phi-2 doesn't support multi-turn well
            echo ""
            ;;
        zephyr)
            echo "<|user|>
${user_message}<|endoftext|>
<|assistant|>
${assistant_response}<|endoftext|>
"
            ;;
        *)
            echo "<|im_start|>user
${user_message}<|im_end|>
<|im_start|>assistant
${assistant_response}<|im_end|>
"
            ;;
    esac
}

# Get llamafile arguments for model-specific stop sequences
get_model_args() {
    local model_name="$1"
    local family=$(get_model_family "$model_name")

    case "$family" in
        qwen3)
            # Qwen3: No token limit, uses stop sequences, higher temp
            echo "--temp 0.7 --top-k 20 --top-p 0.8"
            ;;
        qwen|smollm)
            # ChatML models: moderate settings
            echo "--temp 0.3 --top-k 40 --top-p 0.9 --repeat-penalty 1.1"
            ;;
        llama3)
            # Llama 3: works well with moderate temp
            echo "--temp 0.6 --top-k 40 --top-p 0.9 --repeat-penalty 1.1"
            ;;
        tinyllama)
            # TinyLlama: lower temp for consistency
            echo "--temp 0.4 --top-k 40 --top-p 0.9 --repeat-penalty 1.1"
            ;;
        gemma)
            # Gemma: moderate settings
            echo "--temp 0.5 --top-k 40 --top-p 0.9 --repeat-penalty 1.1"
            ;;
        phi2)
            # Phi-2: lower temp, not instruction-tuned
            echo "--temp 0.2 --top-k 50 --top-p 0.95 --repeat-penalty 1.2"
            ;;
        zephyr)
            # Zephyr/StableLM
            echo "--temp 0.5 --top-k 40 --top-p 0.9 --repeat-penalty 1.1"
            ;;
        *)
            echo "--temp 0.3 --top-k 40 --top-p 0.9 --repeat-penalty 1.1"
            ;;
    esac
}

# Get stop sequences for model
get_stop_sequences() {
    local model_name="$1"
    local family=$(get_model_family "$model_name")

    case "$family" in
        qwen3|qwen|smollm)
            echo '<|im_end|>
<|im_start|>
User:
Human:'
            ;;
        llama3)
            echo '<|eot_id|>
<|start_header_id|>
User:
Human:'
            ;;
        tinyllama)
            echo '</s>
<|user|>
User:
Human:'
            ;;
        gemma)
            echo '<end_of_turn>
<start_of_turn>
User:
Human:'
            ;;
        phi2)
            echo 'Instruct:
Output:
User:
Human:'
            ;;
        zephyr)
            echo '<|endoftext|>
<|user|>
User:
Human:'
            ;;
        *)
            echo '<|im_end|>
<|im_start|>
User:
Human:'
            ;;
    esac
}

# Clean response - remove all known special tokens
clean_response() {
    sed -e 's/<|im_end|>//g' \
        -e 's/<|im_start|>//g' \
        -e 's/<|eot_id|>//g' \
        -e 's/<|start_header_id|>//g' \
        -e 's/<|end_header_id|>//g' \
        -e 's/<|begin_of_text|>//g' \
        -e 's/<end_of_turn>//g' \
        -e 's/<start_of_turn>//g' \
        -e 's/<|endoftext|>//g' \
        -e 's/<|user|>//g' \
        -e 's/<|assistant|>//g' \
        -e 's/<\/s>//g' \
        -e 's/^[[:space:]]*//' \
        -e 's/[[:space:]]*$//'
}

chat_interactive() {
    local model_path
    model_path=$(config_get active_model)

    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        log_error "No model active. Run: pai install qwen3"
        return 1
    fi

    local model_name=$(basename "$model_path")
    local family=$(get_model_family "$model_name")

    log_info "Chat with $model_name"
    log_info "Model family: $family"
    log_info "Commands: 'exit' to quit, '/clear' to reset context"
    log_info "Context: Remembers last 4 exchanges"
    echo ""

    local threads=$(config_get threads 4)
    local ctx_size=$(config_get ctx_size 2048)
    local container_model="$CONTAINER_MODELS/$model_name"

    # Use temp file for history (Termux-compatible path)
    local tmp_dir="${TMPDIR:-$HOME/.cache/pocketai}"
    mkdir -p "$tmp_dir"
    local history_file="$tmp_dir/pocketai_history_$$"
    echo -n "" > "$history_file"
    trap "rm -f '$history_file'" EXIT

    # Get model-specific parameters
    local model_args=$(get_model_args "$model_name")

    # Build stop sequence arguments
    local stop_args=""
    while IFS= read -r stop_seq; do
        [[ -n "$stop_seq" ]] && stop_args="$stop_args -r \"$stop_seq\""
    done <<< "$(get_stop_sequences "$model_name")"

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

        # Read history
        local history=""
        if [[ -s "$history_file" ]]; then
            history=$(cat "$history_file")
        fi

        # Token limits - Qwen3 has no limit (uses stop sequences)
        # Default: 500 tokens (~375 words) - enough for most responses
        local max_tokens=500
        if [[ "$family" == "qwen3" ]]; then
            max_tokens=""  # No limit for Qwen3 (uses stop sequences)
        elif [[ "$user_input" =~ (code|program|write|implement|function|script|algorithm|example|binary|search|sort) ]]; then
            max_tokens=800  # More tokens for code/algorithm requests
        elif [[ "$user_input" =~ (create|explain|describe|what|how|why|list|steps|detailed) ]]; then
            max_tokens=600  # Extended for explanations
        fi

        echo -ne "${GREEN}AI>${RESET} "

        # Build model-specific prompt with history
        local formatted_prompt=$(build_prompt "$model_name" "$user_input" "$history")

        # Stream response
        local response_file="$tmp_dir/response_$$"

        if [[ "$family" == "qwen3" ]]; then
            # Qwen3: No token limit, handle thinking blocks
            eval container_run '"$container_model"' \
                -t '"$threads"' \
                -c '"$ctx_size"' \
                -p '"$formatted_prompt"' \
                $model_args \
                $stop_args \
                --log-disable \
                --no-display-prompt 2>/dev/null > "$response_file"

            # Strip thinking block and display
            if grep -q '</think>' "$response_file"; then
                sed -n '/<\/think>/,$ p' "$response_file" | sed '1d' | clean_response | tee "${response_file}.clean"
                mv "${response_file}.clean" "$response_file"
            else
                cat "$response_file" | clean_response | tee "${response_file}.clean"
                mv "${response_file}.clean" "$response_file"
            fi
        else
            # Other models: Use token limit
            local token_arg=""
            [[ -n "$max_tokens" ]] && token_arg="-n $max_tokens"

            eval container_run '"$container_model"' \
                -t '"$threads"' \
                -c '"$ctx_size"' \
                -p '"$formatted_prompt"' \
                $token_arg \
                $model_args \
                $stop_args \
                --log-disable \
                --no-display-prompt 2>/dev/null | \
                clean_response | \
                tee "$response_file"
        fi

        local response=$(cat "$response_file")
        rm -f "$response_file"
        echo ""

        # Append to history file using model-specific format
        local history_entry=$(build_history_entry "$model_name" "$user_input" "$response")
        echo "$history_entry" >> "$history_file"

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
# API Server Mode
# =============================================================================

SERVER_PID_FILE="$DATA_DIR/server.pid"
SERVER_PORT="${SERVER_PORT:-8080}"
API_PORT="${API_PORT:-8081}"

# =============================================================================
# PocketAI REST API (Full Control)
# =============================================================================

api_start() {
    log_step "Starting PocketAI REST API"
    log_info "Port: $API_PORT"

    local api_script="$DATA_DIR/api_server.py"

    # Use existing api_server.py if present, otherwise generate default
    if [ -f "$api_script" ]; then
        log_info "Using existing api_server.py"
    else
        log_info "Generating api_server.py"
        # Create Python API server
        cat > "$api_script" << PYEOF
#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import os
import sys
import time
import signal
import traceback
import threading
from urllib.parse import urlparse, parse_qs
from datetime import datetime

PORT = int(os.environ.get('API_PORT', $API_PORT))
POCKETAI_ROOT = os.environ.get('POCKETAI_ROOT', '$POCKETAI_ROOT')

# =============================================================================
# Logging
# =============================================================================
def log(level, msg):
    """Thread-safe logging with timestamp"""
    ts = datetime.now().strftime('%H:%M:%S')
    print(f"[{ts}] [{level}] {msg}", flush=True)

def log_info(msg): log("INFO", msg)
def log_warn(msg): log("WARN", msg)
def log_error(msg): log("ERROR", msg)
def log_debug(msg): log("DEBUG", msg)

# =============================================================================
# Request tracking
# =============================================================================
_request_count = 0
_active_streams = 0
_lock = threading.Lock()

def get_request_id():
    global _request_count
    with _lock:
        _request_count += 1
        return _request_count

# =============================================================================
# Cache for expensive operations
# =============================================================================
_status_cache = {
    'model': None,
    'version': None,
    'last_update': 0,
    'cache_ttl': 30
}

def get_cached_status():
    """Get cached status or refresh if stale"""
    try:
        now = time.time()
        if now - _status_cache['last_update'] > _status_cache['cache_ttl']:
            model, _ = run_cmd('config_get active_model', timeout=10)
            version, _ = run_cmd('echo \$VERSION', timeout=5)
            _status_cache['model'] = os.path.basename(model) if model else ''
            _status_cache['version'] = version
            _status_cache['last_update'] = now
        return _status_cache['model'], _status_cache['version']
    except Exception as e:
        log_error(f"get_cached_status failed: {e}")
        return _status_cache.get('model', ''), _status_cache.get('version', '')

# =============================================================================
# Command execution
# =============================================================================
def run_cmd(cmd, timeout=60):
    """Run shell command with timeout and error handling"""
    try:
        result = subprocess.run(
            f'source {POCKETAI_ROOT}/core/engine.sh && {cmd}',
            shell=True, capture_output=True, text=True,
            executable='/data/data/com.termux/files/usr/bin/bash',
            timeout=timeout
        )
        return result.stdout.strip(), result.returncode == 0
    except subprocess.TimeoutExpired:
        log_error(f"Command timed out after {timeout}s: {cmd[:50]}...")
        return f"Command timed out after {timeout}s", False
    except Exception as e:
        log_error(f"run_cmd failed: {e}")
        return str(e), False

def run_cmd_stream(cmd, timeout=300):
    """Run shell command and yield output in real-time using PTY"""
    import pty
    import select

    global _active_streams
    master_fd = None
    process = None
    start_time = time.time()

    try:
        with _lock:
            _active_streams += 1
        log_info(f"Stream started (active: {_active_streams})")

        master_fd, slave_fd = pty.openpty()
        process = subprocess.Popen(
            f'source {POCKETAI_ROOT}/core/engine.sh && {cmd}',
            shell=True,
            stdout=slave_fd,
            stderr=subprocess.PIPE,
            executable='/data/data/com.termux/files/usr/bin/bash'
        )
        os.close(slave_fd)

        token_count = 0
        while True:
            # Check timeout
            if time.time() - start_time > timeout:
                log_warn(f"Stream timeout after {timeout}s")
                break

            ready, _, _ = select.select([master_fd], [], [], 0.1)
            if ready:
                try:
                    data = os.read(master_fd, 1)
                    if data:
                        token_count += 1
                        yield data.decode('utf-8', errors='replace')
                    else:
                        break
                except OSError as e:
                    log_debug(f"OSError in stream read: {e}")
                    break
            elif process.poll() is not None:
                # Process finished, read remaining data
                try:
                    while True:
                        ready, _, _ = select.select([master_fd], [], [], 0)
                        if ready:
                            data = os.read(master_fd, 1024)
                            if data:
                                yield data.decode('utf-8', errors='replace')
                            else:
                                break
                        else:
                            break
                except OSError:
                    pass
                break

        duration = time.time() - start_time
        log_info(f"Stream complete: {token_count} tokens in {duration:.1f}s")

    except Exception as e:
        log_error(f"Stream error: {e}\n{traceback.format_exc()}")
        yield f"[Error: {str(e)}]"
    finally:
        # Cleanup
        with _lock:
            _active_streams -= 1
        if master_fd is not None:
            try:
                os.close(master_fd)
            except:
                pass
        if process is not None:
            try:
                process.terminate()
                process.wait(timeout=2)
            except:
                try:
                    process.kill()
                except:
                    pass

class APIHandler(http.server.BaseHTTPRequestHandler):
    # Suppress default logging
    def log_message(self, format, *args):
        pass

    def send_json(self, data, status=200):
        try:
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', 'Content-Type')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        except (BrokenPipeError, ConnectionResetError) as e:
            log_debug(f"Client disconnected during JSON response: {e}")
        except Exception as e:
            log_error(f"send_json error: {e}")

    def send_error_json(self, message, status=500):
        """Send error response as JSON"""
        log_error(f"HTTP {status}: {message}")
        self.send_json({'error': message, 'status': status}, status)

    def send_sse_stream(self, generator):
        """Send Server-Sent Events stream with robust error handling"""
        req_id = get_request_id()
        log_info(f"[REQ-{req_id}] SSE stream started")
        buffer = ""
        token_count = 0

        try:
            self.send_response(200)
            self.send_header('Content-Type', 'text/event-stream')
            self.send_header('Cache-Control', 'no-cache')
            self.send_header('Connection', 'keep-alive')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('X-Request-ID', str(req_id))
            self.end_headers()

            for char in generator:
                buffer += char
                token_count += 1
                try:
                    self.wfile.write(f"data: {json.dumps({'token': char})}\n\n".encode())
                    self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    log_warn(f"[REQ-{req_id}] Client disconnected during stream")
                    return

            # Send completion event
            self.wfile.write(f"data: {json.dumps({'done': True, 'full_response': buffer})}\n\n".encode())
            self.wfile.flush()
            log_info(f"[REQ-{req_id}] SSE complete: {token_count} tokens")

        except (BrokenPipeError, ConnectionResetError) as e:
            log_warn(f"[REQ-{req_id}] Client disconnected: {e}")
        except Exception as e:
            log_error(f"[REQ-{req_id}] SSE error: {e}\n{traceback.format_exc()}")
            try:
                self.wfile.write(f"data: {json.dumps({'error': str(e)})}\n\n".encode())
                self.wfile.flush()
            except:
                pass

    def do_OPTIONS(self):
        self.send_json({})

    def do_GET(self):
        req_id = get_request_id()
        path = urlparse(self.path).path

        try:
            if path == '/api/health':
                self.send_json({'healthy': True, 'active_streams': _active_streams})

            elif path == '/api/status':
                model_name, version = get_cached_status()
                self.send_json({'status': 'ok', 'version': version, 'model': model_name})

            elif path == '/api/models':
                out, _ = run_cmd('for n in "\${!MODEL_CATALOG[@]}"; do echo "\$n|\${MODEL_CATALOG[\$n]}"; done')
                models = []
                for line in out.split('\n'):
                    if '|' in line:
                        parts = line.split('|')
                        name = parts[0]
                        info = parts[1].split('|') if len(parts) > 1 else ['', '', '', '']
                        models.append({
                            'name': name,
                            'description': info[0] if len(info) > 0 else '',
                            'size': info[1] if len(info) > 1 else '',
                            'ram': info[2] if len(info) > 2 else ''
                        })
                self.send_json({'models': models})

            elif path == '/api/models/installed':
                out, _ = run_cmd('for f in "\$MODELS_DIR"/*.gguf; do [ -f "\$f" ] && echo "\$f"; done')
                active, _ = run_cmd('config_get active_model')
                models = []
                for f in out.split('\n'):
                    if f and f.endswith('.gguf'):
                        size_out, _ = run_cmd(f'du -h "{f}" | cut -f1')
                        models.append({
                            'name': os.path.basename(f),
                            'size': size_out,
                            'active': f == active
                        })
                self.send_json({'models': models})

            elif path == '/api/config':
                out, _ = run_cmd('cat "\$CONFIG_FILE" 2>/dev/null || echo ""')
                config = {}
                for line in out.split('\n'):
                    if '=' in line and not line.startswith('#'):
                        k, v = line.split('=', 1)
                        config[k] = v
                self.send_json(config)

            else:
                self.send_json({'error': 'Not found'}, 404)

        except Exception as e:
            log_error(f"[REQ-{req_id}] GET {path} error: {e}\n{traceback.format_exc()}")
            self.send_error_json(str(e), 500)

    def do_POST(self):
        req_id = get_request_id()
        path = urlparse(self.path).path

        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode() if content_length > 0 else '{}'

            try:
                data = json.loads(body)
            except json.JSONDecodeError as e:
                log_warn(f"[REQ-{req_id}] Invalid JSON: {e}")
                data = {}

            if path == '/api/models/install':
                model = data.get('model', '')
                log_info(f"[REQ-{req_id}] Installing model: {model}")
                out, ok = run_cmd(f'model_install "{model}"', timeout=600)
                self.send_json({'success': ok, 'message': out or f'Model {model} installed'})

            elif path == '/api/models/remove':
                model = data.get('model', '')
                log_info(f"[REQ-{req_id}] Removing model: {model}")
                out, ok = run_cmd(f'model_remove "{model}"')
                self.send_json({'success': ok, 'message': out or f'Model {model} removed'})

            elif path == '/api/models/use':
                model = data.get('model', '')
                log_info(f"[REQ-{req_id}] Activating model: {model}")
                out, ok = run_cmd(f'model_activate "{model}"')
                # Invalidate cache when model changes
                _status_cache['last_update'] = 0
                self.send_json({'success': ok, 'message': out or f'Model {model} activated'})

            elif path == '/api/chat':
                message = data.get('message', '')
                max_tokens = data.get('max_tokens', '')
                log_info(f"[REQ-{req_id}] Chat request (blocking): {len(message)} chars")
                # Escape message for shell
                message = message.replace('"', '\\"').replace('\$', '\\\$')
                if max_tokens:
                    out, ok = run_cmd(f'infer "{message}" "{max_tokens}"', timeout=300)
                else:
                    out, ok = run_cmd(f'infer "{message}"', timeout=300)
                log_info(f"[REQ-{req_id}] Chat complete: {len(out)} chars")
                self.send_json({'response': out})

            elif path == '/api/chat/stream':
                message = data.get('message', '')
                log_info(f"[REQ-{req_id}] Chat request (streaming): {len(message)} chars")
                # Escape message for shell
                message = message.replace('"', '\\"').replace('\$', '\\\$').replace('\`', '\\\`')
                self.send_sse_stream(run_cmd_stream(f'infer_stream "{message}"'))

            elif path == '/api/config':
                key = data.get('key', '')
                value = data.get('value', '')
                log_info(f"[REQ-{req_id}] Config set: {key}={value}")
                run_cmd(f'config_set "{key}" "{value}"')
                self.send_json({'success': True})

            else:
                self.send_json({'error': 'Not found'}, 404)

        except Exception as e:
            log_error(f"[REQ-{req_id}] POST {path} error: {e}\n{traceback.format_exc()}")
            self.send_error_json(str(e), 500)

class CombinedHandler(APIHandler):
    """Serve both API and static web files"""
    def do_GET(self):
        path = urlparse(self.path).path

        # API routes
        if path.startswith('/api/'):
            return super().do_GET()

        # Static files
        web_dir = os.path.join(POCKETAI_ROOT, 'web')
        if path == '/' or path == '':
            path = '/index.html'

        file_path = os.path.join(web_dir, path.lstrip('/'))

        if os.path.isfile(file_path):
            try:
                self.send_response(200)
                if file_path.endswith('.html'):
                    self.send_header('Content-Type', 'text/html')
                elif file_path.endswith('.js'):
                    self.send_header('Content-Type', 'application/javascript')
                elif file_path.endswith('.css'):
                    self.send_header('Content-Type', 'text/css')
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            except (BrokenPipeError, ConnectionResetError):
                pass
        else:
            self.send_json({'error': 'Not found'}, 404)

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    """Handle each request in a new thread for better concurrency"""
    daemon_threads = True
    allow_reuse_address = True

def shutdown_handler(signum, frame):
    """Graceful shutdown on SIGINT/SIGTERM"""
    log_info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

if __name__ == '__main__':
    # Register signal handlers
    signal.signal(signal.SIGINT, shutdown_handler)
    signal.signal(signal.SIGTERM, shutdown_handler)

    Handler = CombinedHandler if os.environ.get('SERVE_WEB') else APIHandler
    mode = 'API + Web' if os.environ.get('SERVE_WEB') else 'API only'

    log_info("=" * 50)
    log_info(f"PocketAI API Server v2.0")
    log_info(f"Port: {PORT} | Mode: {mode}")
    log_info("=" * 50)

    try:
        with ThreadedTCPServer(('', PORT), Handler) as httpd:
            log_info(f"Server ready - listening on port {PORT}")
            httpd.serve_forever()
    except OSError as e:
        log_error(f"Failed to start server: {e}")
        sys.exit(1)
    except Exception as e:
        log_error(f"Server error: {e}\n{traceback.format_exc()}")
        sys.exit(1)
PYEOF
        chmod +x "$api_script"
    fi

    # Start Python API server
    log_info "Starting API server..."
    python3 "$api_script" &
    local py_pid=$!

    sleep 1
    if kill -0 $py_pid 2>/dev/null; then
        echo "$py_pid" > "$DATA_DIR/api.pid"
        log_success "API server started on port $API_PORT (PID: $py_pid)"
        echo ""
        log_info "Endpoints:"
        echo "  GET  /api/status          - System status"
        echo "  GET  /api/models          - List available models"
        echo "  GET  /api/models/installed - List installed models"
        echo "  POST /api/models/install  - Install model {\"model\":\"name\"}"
        echo "  POST /api/models/remove   - Remove model {\"model\":\"name\"}"
        echo "  POST /api/models/use      - Activate model {\"model\":\"name\"}"
        echo "  POST /api/chat            - Send message {\"message\":\"text\"}"
        echo "  POST /api/chat/stream     - Stream response (SSE)"
        echo "  GET  /api/config          - Get config"
        echo "  POST /api/config          - Set config {\"key\":\"k\",\"value\":\"v\"}"
        echo ""
    else
        log_error "Failed to start API server"
        return 1
    fi
}

api_stop() {
    if [[ -f "$DATA_DIR/api.pid" ]]; then
        kill $(cat "$DATA_DIR/api.pid") 2>/dev/null
        rm -f "$DATA_DIR/api.pid"
        log_success "API server stopped"
    else
        log_info "API server not running"
    fi
}

server_start() {
    local model_path
    model_path=$(config_get active_model)

    if [[ -z "$model_path" || ! -f "$model_path" ]]; then
        log_error "No model active. Run: pai install qwen3"
        return 1
    fi

    # Check if already running
    if server_status >/dev/null 2>&1; then
        log_warn "Server already running on port $SERVER_PORT"
        return 0
    fi

    local threads=$(config_get threads 4)
    local ctx_size=$(config_get ctx_size 2048)
    local container_model="$CONTAINER_MODELS/$(basename "$model_path")"

    log_step "Starting PocketAI API Server"
    log_info "Model: $(basename "$model_path")"
    log_info "Port: $SERVER_PORT"
    log_info "Endpoint: http://localhost:$SERVER_PORT/v1/chat/completions"

    # Start server in background inside proot container
    proot-distro login "$CONTAINER_NAME" \
        --bind "$POCKETAI_ROOT/data:/opt/pocketai/data" \
        --bind "$POCKETAI_ROOT/models:/opt/pocketai/models" \
        -- "$CONTAINER_BIN" \
        -m "$container_model" \
        -t "$threads" \
        -c "$ctx_size" \
        --server \
        --host 0.0.0.0 \
        --port "$SERVER_PORT" \
        2>/dev/null &

    local pid=$!
    echo "$pid" > "$SERVER_PID_FILE"

    # Wait for server to start
    sleep 2

    if server_status >/dev/null 2>&1; then
        log_success "Server started (PID: $pid)"
        echo ""
        log_info "API Usage:"
        echo ""
        echo "  curl http://localhost:$SERVER_PORT/v1/chat/completions \\"
        echo "    -H 'Content-Type: application/json' \\"
        echo "    -d '{\"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}]}'"
        echo ""
        log_info "Stop with: pai server stop"
    else
        log_error "Failed to start server"
        rm -f "$SERVER_PID_FILE"
        return 1
    fi
}

server_stop() {
    if [[ ! -f "$SERVER_PID_FILE" ]]; then
        log_warn "Server not running"
        return 0
    fi

    local pid=$(cat "$SERVER_PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        sleep 1
        # Force kill if still running
        kill -9 "$pid" 2>/dev/null
        log_success "Server stopped"
    else
        log_info "Server was not running"
    fi

    rm -f "$SERVER_PID_FILE"
}

server_status() {
    if [[ ! -f "$SERVER_PID_FILE" ]]; then
        return 1
    fi

    local pid=$(cat "$SERVER_PID_FILE")

    if kill -0 "$pid" 2>/dev/null; then
        # Also check if port is listening
        if command -v curl &>/dev/null; then
            curl -s "http://localhost:$SERVER_PORT/health" >/dev/null 2>&1
            return $?
        fi
        return 0
    fi

    return 1
}

server_info() {
    log_step "API Server Status"
    echo ""

    if server_status; then
        local pid=$(cat "$SERVER_PID_FILE")
        echo -e "  Status: ${GREEN}Running${RESET}"
        echo "  PID:    $pid"
        echo "  Port:   $SERVER_PORT"
        echo "  URL:    http://localhost:$SERVER_PORT"
        echo ""
        echo "  Endpoints:"
        echo "    POST /v1/chat/completions  - Chat API (OpenAI compatible)"
        echo "    POST /v1/completions       - Completion API"
        echo "    GET  /health               - Health check"
    else
        echo -e "  Status: ${YELLOW}Stopped${RESET}"
        echo ""
        echo "  Start with: pai server start"
    fi
    echo ""
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
export -f get_model_family build_prompt build_history_entry get_model_args get_stop_sequences clean_response
export -f infer infer_stream chat_interactive system_info
export -f server_start server_stop server_status server_info
export -f api_start api_stop
export -f log_info log_success log_warn log_error log_step
