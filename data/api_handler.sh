#!/bin/bash
source "$POCKETAI_ROOT/core/engine.sh"

# Simple HTTP response helpers
respond() {
    local status="$1" body="$2"
    echo -e "HTTP/1.1 $status\r"
    echo -e "Content-Type: application/json\r"
    echo -e "Access-Control-Allow-Origin: *\r"
    echo -e "Connection: close\r"
    echo -e "\r"
    echo "$body"
}

handle_request() {
    local method path body
    read -r method path _
    path="${path%$'\r'}"

    # Read headers and body
    local content_length=0
    while IFS= read -r line; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        [[ "$line" =~ ^Content-Length:\ ([0-9]+) ]] && content_length="${BASH_REMATCH[1]}"
    done
    [[ $content_length -gt 0 ]] && read -r -n "$content_length" body

    case "$method $path" in
        "GET /api/status")
            local model=$(config_get active_model)
            local model_name=""
            [[ -n "$model" ]] && model_name=$(basename "$model")
            respond "200 OK" "{\"status\":\"ok\",\"version\":\"$VERSION\",\"model\":\"$model_name\"}"
            ;;
        "GET /api/models")
            local models=""
            for name in "${!MODEL_CATALOG[@]}"; do
                IFS='|' read -r desc size ram url <<< "${MODEL_CATALOG[$name]}"
                models="$models{\"name\":\"$name\",\"description\":\"$desc\",\"size\":\"$size\",\"ram\":\"$ram\"},"
            done
            models="[${models%,}]"
            respond "200 OK" "{\"models\":$models}"
            ;;
        "GET /api/models/installed")
            local installed=""
            for f in "$MODELS_DIR"/*.gguf; do
                [[ -f "$f" ]] || continue
                local name=$(basename "$f")
                local size=$(du -h "$f" | cut -f1)
                local active="false"
                [[ "$(config_get active_model)" == "$f" ]] && active="true"
                installed="$installed{\"name\":\"$name\",\"size\":\"$size\",\"active\":$active},"
            done
            installed="[${installed%,}]"
            respond "200 OK" "{\"models\":$installed}"
            ;;
        "POST /api/models/install")
            local model=$(echo "$body" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
            if model_install "$model" 2>&1; then
                respond "200 OK" "{\"success\":true,\"message\":\"Model $model installed\"}"
            else
                respond "400 Bad Request" "{\"success\":false,\"message\":\"Failed to install $model\"}"
            fi
            ;;
        "POST /api/models/remove")
            local model=$(echo "$body" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
            if model_remove "$model" 2>&1; then
                respond "200 OK" "{\"success\":true,\"message\":\"Model $model removed\"}"
            else
                respond "400 Bad Request" "{\"success\":false,\"message\":\"Failed to remove $model\"}"
            fi
            ;;
        "POST /api/models/use")
            local model=$(echo "$body" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
            if model_activate "$model" 2>&1; then
                respond "200 OK" "{\"success\":true,\"message\":\"Model $model activated\"}"
            else
                respond "400 Bad Request" "{\"success\":false,\"message\":\"Failed to activate $model\"}"
            fi
            ;;
        "POST /api/chat")
            local prompt=$(echo "$body" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
            local response=$(infer "$prompt" 2>/dev/null)
            response="${response//\"/\\\"}"
            response="${response//$'\n'/\\n}"
            respond "200 OK" "{\"response\":\"$response\"}"
            ;;
        "GET /api/config")
            local cfg=""
            while IFS='=' read -r key value; do
                [[ "$key" =~ ^# ]] || [[ -z "$key" ]] && continue
                cfg="$cfg\"$key\":\"$value\","
            done < "$CONFIG_FILE"
            respond "200 OK" "{${cfg%,}}"
            ;;
        "POST /api/config")
            local key=$(echo "$body" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
            local value=$(echo "$body" | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
            config_set "$key" "$value"
            respond "200 OK" "{\"success\":true}"
            ;;
        "GET /api/health")
            respond "200 OK" "{\"healthy\":true}"
            ;;
        *)
            respond "404 Not Found" "{\"error\":\"Not found\"}"
            ;;
    esac
}

handle_request
