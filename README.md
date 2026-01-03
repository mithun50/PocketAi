# PocketAI

<div align="center">

**Run AI models locally on your Android phone**

*No cloud. No subscription. No compilation. Just works.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20(Termux)-green.svg)](https://termux.dev/)
[![Engine](https://img.shields.io/badge/Engine-llamafile%200.9.3-blue.svg)](https://github.com/Mozilla-Ocho/llamafile)
[![Version](https://img.shields.io/badge/Version-2.0.0-purple.svg)](https://github.com/mithun50/PocketAi/releases)

</div>

---

## Features

- **100% Offline** - Works without internet after initial setup
- **Free Forever** - No subscriptions, no API keys, no hidden costs
- **No Compilation** - Powered by Mozilla llamafile (just download and run)
- **Private & Secure** - Your data never leaves your device
- **Android Native** - Optimized for mobile with proot isolation
- **Multiple Models** - Choose from tiny (270MB) to powerful (2GB+)
- **Smart Prompting** - Model-specific templates for optimal responses
- **Web Dashboard** - Browser-based UI for easy management
- **REST API** - Full control via HTTP endpoints
- **OpenAI Compatible** - Drop-in replacement for OpenAI API

## Quick Start

### One-Command Install

```bash
git clone https://github.com/mithun50/PocketAi.git
cd PocketAi
./setup.sh
```

### Start Using

```bash
# Activate environment (or restart terminal)
source ~/.pocketai_env

# Install a model (Qwen3 recommended for 2025)
pai install qwen3

# Start chatting!
pai chat
```

## Available Models

### 2025 Models (Recommended)

| Model | Size | RAM | Quality | Best For |
|-------|------|-----|---------|----------|
| `qwen3` | 400MB | 512MB | ⭐⭐⭐ | **Best for low RAM** |
| `llama3.2` | 700MB | 1GB | ⭐⭐⭐⭐ | **Best balance** |
| `llama3.2-3b` | 2.0GB | 2GB | ⭐⭐⭐⭐⭐ | Best quality |

### Classic Models

| Model | Size | RAM | Quality | Best For |
|-------|------|-----|---------|----------|
| `smollm2` | 270MB | 400MB | ⭐⭐ | Ultra-low RAM |
| `qwen2` | 400MB | 512MB | ⭐⭐⭐ | Low RAM |
| `qwen2-1b` | 1.0GB | 1.2GB | ⭐⭐⭐⭐ | Daily use |
| `gemma2b` | 1.4GB | 2GB | ⭐⭐⭐⭐ | Google quality |
| `qwen2-3b` | 2.0GB | 3GB | ⭐⭐⭐⭐⭐ | Best quality |
| `phi2` | 1.6GB | 3GB | ⭐⭐⭐⭐ | Coding tasks |

## Commands

### Chat & Inference

```bash
pai chat                 # Interactive chat
pai ask "What is AI?"    # Quick question
pai complete "Once..."   # Text completion
```

### Model Management

```bash
pai models               # List available models
pai models installed     # List installed models
pai install <model>      # Download a model
pai use <model>          # Switch active model
pai remove <model>       # Delete a model
```

### OpenAI-Compatible Server

```bash
pai server start         # Start API server (port 8080)
pai server stop          # Stop the server
pai server status        # Show server info
```

Use with any OpenAI-compatible client:
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello"}]}'
```

### REST API & Web Dashboard

```bash
pai api start            # Start REST API (port 8081)
pai api web              # Start API + Web Dashboard
pai api stop             # Stop API server
pai api status           # Show API endpoints
```

Open http://localhost:8081/ in your browser for the web dashboard.

**API Endpoints:**
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check (instant, no shell calls) |
| GET | `/api/status` | System status (cached, 30s TTL) |
| GET | `/api/models` | Available models |
| GET | `/api/models/installed` | Installed models |
| POST | `/api/models/install` | Install model |
| POST | `/api/models/use` | Switch model |
| POST | `/api/chat` | Send message (blocking, returns full response) |
| POST | `/api/chat/stream` | Send message (SSE streaming, real-time tokens) |
| GET | `/api/config` | Get config |
| POST | `/api/config` | Set config |

**Streaming vs Blocking:**
- `/api/chat` - Waits for complete response, returns JSON `{"response": "..."}`
- `/api/chat/stream` - Returns tokens in real-time via Server-Sent Events (SSE)

**Both endpoints accept:**
```json
{"message": "Your question", "max_tokens": 500}
```
> **Note:** Default is only 150 tokens. For longer responses, set `max_tokens` higher.

**Performance Optimizations:**
- `/api/health` - Instant response, no shell commands (use for polling)
- `/api/status` - Cached for 30 seconds to reduce shell command overhead
- Streaming uses PTY for unbuffered real-time token delivery

### Configuration

```bash
pai config               # Show current config
pai config set key val   # Change settings
pai config reset         # Reset to defaults
```

| Option | Default | Description |
|--------|---------|-------------|
| `threads` | 4 | CPU threads to use |
| `ctx_size` | 2048 | Context window size |

### System

```bash
pai status               # System information
pai doctor               # Diagnose issues
pai update               # Update PocketAI from GitHub
pai help                 # Show all commands
pai version              # Version info
```

## Project Structure

```
pocketai/
├── bin/
│   └── pai                  # CLI entry point
├── core/
│   └── engine.sh            # Core engine (inference, models, API)
├── data/
│   ├── config               # User configuration
│   ├── llamafile            # LLM runtime engine
│   └── api_server.py        # REST API server
├── models/                  # Downloaded GGUF models
├── web/
│   └── index.html           # Web dashboard
├── docs/
│   ├── COMMANDS.md          # Command reference
│   ├── MODELS.md            # Model guide
│   └── TROUBLESHOOTING.md   # Problem solving
├── setup.sh                 # Installer
└── README.md
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        PocketAI                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────┐    ┌──────────┐    ┌─────────────────────┐    │
│   │   CLI   │───►│  Engine  │───►│  proot container    │    │
│   │  (pai)  │    │          │    │  (Alpine Linux)     │    │
│   └─────────┘    └──────────┘    └──────────┬──────────┘    │
│                                              │               │
│   ┌─────────┐    ┌──────────┐               ▼               │
│   │   Web   │───►│ REST API │         ┌──────────┐          │
│   │Dashboard│    │ (Python) │         │llamafile │          │
│   └─────────┘    └──────────┘         └────┬─────┘          │
│                                             │                │
│   ┌─────────┐                              ▼                │
│   │ OpenAI  │◄────────────────────  GGUF Model             │
│   │ Clients │                                               │
│   └─────────┘                                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
1. **pai CLI** - User-friendly bash interface
2. **engine.sh** - Core logic (model management, inference, API)
3. **api_server.py** - REST API + Web dashboard server
4. **llamafile** - Mozilla's portable LLM runtime
5. **proot** - Lightweight Linux container for isolation
6. **GGUF models** - Quantized models optimized for mobile

## Requirements

- **Device**: Android phone/tablet
- **App**: [Termux](https://termux.dev/) from F-Droid
- **Storage**: 1GB+ free (varies by model)
- **RAM**: 512MB+ (more = better models)

## Troubleshooting

### Quick Fix
```bash
pai doctor    # Diagnose all issues
```

### Common Issues

| Issue | Solution |
|-------|----------|
| `pai: command not found` | Run `source ~/.pocketai_env` |
| `No model active` | Run `pai install qwen3` |
| Slow responses | Use smaller model: `pai use smollm2` |
| Out of memory | Close apps, use smaller model |
| API offline | Run `pai api web` not `pai api start` |

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Mozilla llamafile](https://github.com/Mozilla-Ocho/llamafile) - Portable LLM runtime
- [Termux](https://termux.dev/) - Android terminal emulator
- [proot-distro](https://github.com/termux/proot-distro) - Linux containers for Termux
- Model providers: Qwen, Meta (Llama), HuggingFace, Google, Microsoft

## Contact

- **Author**: Mithun
- **GitHub**: [@mithun50](https://github.com/mithun50)
- **Issues**: [GitHub Issues](https://github.com/mithun50/PocketAi/issues)

---

<div align="center">

**Star this repo if you find it useful!**

Made with love for the Android AI community

</div>
