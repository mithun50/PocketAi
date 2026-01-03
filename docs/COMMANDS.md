# PocketAI Command Reference

Complete documentation for all `pai` commands.

## Table of Contents

- [Setup Commands](#setup-commands)
- [Model Commands](#model-commands)
- [Chat Commands](#chat-commands)
- [Server Commands](#server-commands)
- [API Commands](#api-commands)
  - [Streaming Chat Endpoint](#streaming-chat-endpoint)
- [Configuration Commands](#configuration-commands)
- [Info Commands](#info-commands)
- [Examples](#examples)
  - [Streaming in Your App](#streaming-in-your-app)

---

## Setup Commands

### `pai init`

Initialize PocketAI for first-time use.

```bash
pai init
```

**What it does:**
- Creates Alpine Linux container via proot
- Downloads llamafile engine (~5MB)
- Sets up directory structure
- Configures environment

**When to use:**
- First time setup
- After a fresh install
- To repair broken installation

---

### `pai update`

Update PocketAI to the latest version from GitHub.

```bash
pai update
```

**What it does:**
- Fetches latest changes from GitHub
- Shows new commits before updating
- Auto-stashes local changes if any
- Pulls updates with fast-forward merge
- Restores stashed changes after update

**Features:**
- Safe update with automatic backup of local changes
- Preview of what's new before applying
- Automatic conflict detection
- Version display after update

**Example output:**
```
Updating PocketAI
▸ Fetching latest changes...
▸ Changes available:
abc1234 Fix prompt templates
def5678 Add update command

▸ Pulling updates...
✓ Update successful!

Update Complete!
PocketAI v2.0.0
```

**Alias:** `pai upgrade`

---

### `pai status`

Display system status and information.

```bash
pai status
```

**Output includes:**
- PocketAI version
- Engine version (llamafile 0.9.3)
- Architecture (aarch64/x86_64)
- RAM available
- Storage free
- Active model

---

### `pai doctor`

Diagnose and troubleshoot issues.

```bash
pai doctor
```

**Checks:**
- proot-distro installed
- Container exists
- Engine binary exists
- Model active
- RAM available
- Storage free

**Use when:**
- Something isn't working
- Before reporting a bug
- After system updates

---

## Model Commands

### `pai models`

List all available models with compatibility info.

```bash
pai models
```

**Output shows:**
- Model name
- Description
- Download size
- RAM requirement
- Compatibility with your device

---

### `pai models installed`

List models you have downloaded.

```bash
pai models installed
```

**Shows:**
- Installed model files
- File sizes
- Which is currently active

---

### `pai install <model>`

Download and install a model.

```bash
# 2025 Models (Recommended)
pai install qwen3        # Best for low RAM (400MB)
pai install llama3.2     # Best balance (700MB)
pai install llama3.2-3b  # Best quality (2GB)

# Classic Models
pai install smollm2      # Tiny (270MB)
pai install qwen2        # Small (400MB)
pai install qwen2-1b     # Good balance (1GB)
pai install qwen2-3b     # Best quality (2GB)
```

**Available models:**

| Model | Size | RAM | Quality |
|-------|------|-----|---------|
| qwen3 | 400MB | 512MB | ⭐⭐⭐ |
| llama3.2 | 700MB | 1GB | ⭐⭐⭐⭐ |
| llama3.2-3b | 2.0GB | 2GB | ⭐⭐⭐⭐⭐ |
| smollm2 | 270MB | 400MB | ⭐⭐ |
| qwen2 | 400MB | 512MB | ⭐⭐⭐ |
| qwen2-1b | 1.0GB | 1.2GB | ⭐⭐⭐⭐ |
| gemma2b | 1.4GB | 2GB | ⭐⭐⭐⭐ |
| phi2 | 1.6GB | 3GB | ⭐⭐⭐⭐ |
| qwen2-3b | 2.0GB | 3GB | ⭐⭐⭐⭐⭐ |

---

### `pai use <model>`

Switch to a different installed model.

```bash
pai use qwen3
pai use llama3.2
pai use smollm2
```

**Note:** Model must be installed first.

---

### `pai remove <model>`

Delete an installed model to free space.

```bash
pai remove tinyllama
pai remove qwen2
```

---

## Chat Commands

### `pai chat`

Start an interactive chat session.

```bash
pai chat
```

**In chat mode:**
- Type your message and press Enter
- Type `exit` or `quit` to leave
- Press `Ctrl+C` to force quit

**Example session:**
```
Chat with qwen3.gguf
Type your message, press Enter. Type 'exit' to quit.

You> Hello, how are you?
AI> I'm doing well, thank you for asking! How can I help you today?

You> What is Python?
AI> Python is a popular programming language known for its simple syntax...

You> exit
Chat ended
```

---

### `pai ask "<question>"`

Ask a single question and get an answer.

```bash
pai ask "What is the capital of France?"
pai ask "Explain quantum computing simply"
pai ask "Write a haiku about coding"
```

**Tips for better answers:**
- Be specific in your questions
- Use quotes around the question
- For complex topics, ask step by step

---

### `pai complete "<text>"`

Complete the given text.

```bash
pai complete "The quick brown fox"
pai complete "def fibonacci(n):"
```

---

## Server Commands

OpenAI-compatible API server for use with external clients.

### `pai server start`

Start the OpenAI-compatible API server.

```bash
pai server start
```

**Details:**
- Port: 8080
- Endpoint: `http://localhost:8080/v1/chat/completions`
- Compatible with OpenAI API clients

**Usage example:**
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

---

### `pai server stop`

Stop the running API server.

```bash
pai server stop
```

---

### `pai server status`

Show server status and information.

```bash
pai server status
```

**Output:**
- Running/Stopped status
- PID (if running)
- Port number
- Available endpoints

---

### `pai server restart`

Restart the API server.

```bash
pai server restart
```

---

## API Commands

REST API for model management and web dashboard.

### `pai api start`

Start the REST API server (API only, no web UI).

```bash
pai api start
```

**Details:**
- Port: 8081
- Background process
- API endpoints only

---

### `pai api web`

Start REST API with web dashboard (recommended).

```bash
pai api web
```

**Details:**
- Port: 8081
- Foreground process (Ctrl+C to stop)
- Web dashboard at `http://localhost:8081/`
- API endpoints at `http://localhost:8081/api/`

**Web Dashboard Features:**
- View system status
- Manage models (install, remove, switch)
- Interactive chat
- Configuration management
- API endpoint tester

---

### `pai api stop`

Stop the REST API server.

```bash
pai api stop
```

---

### `pai api status`

Show API server status and available endpoints.

```bash
pai api status
```

**API Endpoints:**

| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| GET | `/api/health` | - | Health check |
| GET | `/api/status` | - | System status |
| GET | `/api/models` | - | Available models |
| GET | `/api/models/installed` | - | Installed models |
| POST | `/api/models/install` | `{"model": "name"}` | Install model |
| POST | `/api/models/remove` | `{"model": "name"}` | Remove model |
| POST | `/api/models/use` | `{"model": "name"}` | Switch model |
| POST | `/api/chat` | `{"message": "text"}` | Send message (blocking) |
| POST | `/api/chat/stream` | `{"message": "text"}` | Send message (streaming) |
| GET | `/api/config` | - | Get config |
| POST | `/api/config` | `{"key": "k", "value": "v"}` | Set config |

**Example API calls:**

```bash
# Check health
curl http://localhost:8081/api/health

# Get status
curl http://localhost:8081/api/status

# List installed models
curl http://localhost:8081/api/models/installed

# Send chat message
curl -X POST http://localhost:8081/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'

# Install a model
curl -X POST http://localhost:8081/api/models/install \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen3"}'

# Switch model
curl -X POST http://localhost:8081/api/models/use \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2"}'
```

---

### Streaming Chat Endpoint

The `/api/chat/stream` endpoint provides real-time token streaming via Server-Sent Events (SSE).

**Endpoint:** `POST /api/chat/stream`

**Request:**
```json
{
  "message": "Your question here",
  "max_tokens": 500
}
```

**Parameters:**
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `message` | Yes | - | The user's message/question |
| `max_tokens` | No | 500 | Maximum tokens to generate |

**Token Limits (when `max_tokens` not specified):**
| Condition | Limit |
|-----------|-------|
| Default | 500 tokens (~375 words) |
| Code/algorithm in prompt | 800 tokens |
| Explain/describe in prompt | 600 tokens |
| Qwen3 model | No limit (uses stop sequences) |

> **Tip:** Override with `max_tokens` if you need more/less.

**Response Format (SSE):**
```
data: {"token": "H"}
data: {"token": "e"}
data: {"token": "l"}
data: {"token": "l"}
data: {"token": "o"}
...
data: {"done": true, "full_response": "Hello..."}
```

**Streaming Example:**
```bash
# Stream response in real-time
curl -N -X POST http://localhost:8081/api/chat/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!"}'
```

**Comparison: Blocking vs Streaming**

| Feature | `/api/chat` | `/api/chat/stream` |
|---------|-------------|-------------------|
| Response type | JSON | SSE stream |
| First output | After full generation | Immediate tokens |
| User experience | Wait → See all | See tokens flow |
| Use case | Programmatic calls | Live UI updates |

**Streaming Behavior:**
- Each `data:` line contains JSON with a single token
- Tokens arrive character-by-character as AI generates
- Final message has `"done": true` with complete response
- Content-Type: `text/event-stream`

**Implementing with Fallback:**

For production apps, implement fallback to blocking endpoint:

```
1. Try /api/chat/stream first
2. If stream fails (error, timeout, SSE parse failure):
   → Fallback to /api/chat
   → Show full response at once
```

**Fallback Triggers:**
- Network/connection error
- Timeout (no response in 30 seconds)
- SSE parsing failure
- HTTP error status codes (4xx, 5xx)

---

### API Performance

The API server includes several performance optimizations:

**Endpoint Caching:**
| Endpoint | Caching | Description |
|----------|---------|-------------|
| `/api/health` | None (instant) | Returns immediately, no shell commands |
| `/api/status` | 30 seconds | Caches model/version info to reduce overhead |
| `/api/chat/stream` | None | Real-time streaming via PTY |

**Why Caching Matters:**
- Each shell command sources `engine.sh` which takes ~100-200ms
- `/api/status` previously ran 2 shell commands per call
- With caching, repeated status checks are instant
- Cache automatically refreshes every 30 seconds

**Best Practices for Polling:**
```bash
# Good: Use health for frequent checks (instant)
curl http://localhost:8081/api/health

# Good: Use status less frequently (cached)
curl http://localhost:8081/api/status

# Bad: Polling status every second (wastes resources)
```

**Streaming Performance:**
- Uses PTY (pseudo-terminal) for unbuffered output
- Tokens are sent character-by-character via SSE
- No artificial delays or buffering
- Real-time display in compatible clients

---

## Configuration Commands

### `pai config`

Show current configuration.

```bash
pai config
```

**Output:**
```
# PocketAI Configuration
active_model=/path/to/model.gguf
threads=4
ctx_size=2048
```

---

### `pai config set <key> <value>`

Change a configuration setting.

```bash
pai config set threads 2        # Use 2 CPU threads
pai config set ctx_size 1024    # Smaller context window
```

**Available settings:**

| Key | Default | Description |
|-----|---------|-------------|
| threads | 4 | CPU threads (1-8) |
| ctx_size | 2048 | Context window size |
| active_model | - | Path to active model |

**Performance tips:**
- Lower threads = less CPU usage, slower
- Lower ctx_size = less RAM, shorter memory

---

### `pai config get <key>`

Get a specific configuration value.

```bash
pai config get threads
pai config get active_model
```

---

### `pai config reset`

Reset configuration to defaults.

```bash
pai config reset
```

---

## Info Commands

### `pai help`

Show help message with all commands.

```bash
pai help
```

---

### `pai version`

Show version information.

```bash
pai version
```

**Output:**
```
PocketAI v2.0.0
Engine: llamafile 0.9.3
Platform: aarch64 / Android
```

---

### `pai about`

Show about information.

```bash
pai about
```

---

## Command Aliases

Some commands have shorter aliases:

| Full Command | Alias |
|--------------|-------|
| `pai install` | `pai add` |
| `pai remove` | `pai rm`, `pai del` |
| `pai status` | `pai info` |
| `pai ask` | `pai q` |
| `pai config` | `pai cfg` |

---

## Examples

### First-time setup
```bash
./setup.sh
source ~/.pocketai_env
pai install qwen3
pai chat
```

### Use Web Dashboard
```bash
pai api web
# Open http://localhost:8081 in browser
```

### Start OpenAI-compatible server
```bash
pai server start
# Use with any OpenAI client at localhost:8080
```

### Switch between models
```bash
pai install smollm2
pai install qwen3
pai use smollm2      # Use tiny model
pai ask "Hello"
pai use qwen3        # Switch to better model
pai ask "Hello"      # Better answer
```

### Check system health
```bash
pai doctor
pai status
```

### Optimize for low RAM
```bash
pai install smollm2           # Smallest model
pai use smollm2
pai config set threads 2      # Less CPU
pai config set ctx_size 1024  # Less RAM
```

### API Integration
```bash
# Start API
pai api start

# Blocking request (wait for full response)
curl -X POST http://localhost:8081/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is 2+2?"}'

# Streaming request (real-time tokens)
curl -N -X POST http://localhost:8081/api/chat/stream \
  -H "Content-Type: application/json" \
  -d '{"message": "What is 2+2?"}'
```

### Streaming in Your App

**JavaScript/Browser:**
```javascript
const eventSource = new EventSource('/api/chat/stream', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ message: 'Hello' })
});

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.done) {
    console.log('Complete:', data.full_response);
  } else {
    process.stdout.write(data.token); // Print token
  }
};
```

**Python:**
```python
import requests

response = requests.post(
    'http://localhost:8081/api/chat/stream',
    json={'message': 'Hello'},
    stream=True
)

for line in response.iter_lines():
    if line.startswith(b'data: '):
        data = json.loads(line[6:])
        if data.get('done'):
            print('\nComplete!')
        else:
            print(data['token'], end='', flush=True)
```

**With Fallback (Recommended):**
```python
import requests

def chat(message):
    # Try streaming first
    try:
        response = requests.post(
            'http://localhost:8081/api/chat/stream',
            json={'message': message},
            stream=True,
            timeout=30
        )
        result = ''
        for line in response.iter_lines():
            if line.startswith(b'data: '):
                data = json.loads(line[6:])
                if data.get('done'):
                    return data['full_response']
                print(data['token'], end='', flush=True)
    except:
        # Fallback to blocking
        response = requests.post(
            'http://localhost:8081/api/chat',
            json={'message': message}
        )
        return response.json()['response']
```
