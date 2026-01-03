# PocketAI

<div align="center">

<img src="docs/assets/banner.png" alt="PocketAI Banner" width="600">

### **Run AI models locally on your Android phone**

*No cloud. No subscription. No compilation. Just works.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20(Termux)-3DDC84.svg?logo=android)](https://termux.dev/)
[![Engine](https://img.shields.io/badge/Engine-llamafile%200.9.3-FF6600.svg)](https://github.com/Mozilla-Ocho/llamafile)
[![Version](https://img.shields.io/badge/Version-2.0.0-blue.svg)](https://github.com/mithun50/PocketAi/releases)

[![GitHub stars](https://img.shields.io/github/stars/mithun50/PocketAi?style=social)](https://github.com/mithun50/PocketAi/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/mithun50/PocketAi?style=social)](https://github.com/mithun50/PocketAi/network/members)
[![GitHub issues](https://img.shields.io/github/issues/mithun50/PocketAi)](https://github.com/mithun50/PocketAi/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/mithun50/PocketAi)](https://github.com/mithun50/PocketAi/commits/main)

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/mithun50/PocketAi/pulls)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/mithun50/PocketAi/graphs/commit-activity)
[![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Made with Python](https://img.shields.io/badge/Made%20with-Python-3776AB.svg?logo=python&logoColor=white)](https://www.python.org/)

---

[**Features**](#-features) | [**Quick Start**](#-quick-start) | [**Models**](#-available-models) | [**Commands**](#-commands) | [**API**](#-rest-api--web-dashboard) | [**Docs**](#-documentation)

</div>

---

## **Features**

| Feature | Description |
|---------|-------------|
| **100% Offline** | Works without internet after initial setup |
| **Free Forever** | No subscriptions, no API keys, no hidden costs |
| **No Compilation** | Powered by Mozilla llamafile (just download and run) |
| **Private & Secure** | Your data never leaves your device |
| **Android Native** | Optimized for mobile with proot isolation |
| **Multiple Models** | Choose from tiny (270MB) to powerful (2GB+) |
| **Smart Prompting** | Model-specific templates for optimal responses |
| **Web Dashboard** | Browser-based UI for easy management |
| **REST API** | Full control via HTTP endpoints |
| **OpenAI Compatible** | Drop-in replacement for OpenAI API |
| **Auto-Start** | API server starts automatically with Termux |
| **Easy Uninstall** | Clean removal with single command |

---

## **Quick Start**

### Prerequisites

- Android phone/tablet
- [Termux](https://f-droid.org/en/packages/com.termux/) from F-Droid (NOT Play Store)
- 1GB+ free storage
- 512MB+ RAM

### One-Command Install

```bash
# Clone and install
git clone https://github.com/mithun50/PocketAi.git
cd PocketAi
./setup.sh
```

### Start Using

```bash
# Install a model (Qwen3 recommended)
pai install qwen3

# Start chatting!
pai chat

# Or start the web dashboard
pai api web
```

---

## **Available Models**

### 2025 Models (Recommended)

| Model | Size | RAM | Quality | Best For |
|:------|:----:|:---:|:-------:|:---------|
| `qwen3` | 400MB | 512MB | ★★★☆☆ | **Best for low RAM** |
| `llama3.2` | 700MB | 1GB | ★★★★☆ | **Best balance** |
| `llama3.2-3b` | 2.0GB | 2GB | ★★★★★ | Best quality |

### Classic Models

| Model | Size | RAM | Quality | Best For |
|:------|:----:|:---:|:-------:|:---------|
| `smollm2` | 270MB | 400MB | ★★☆☆☆ | Ultra-low RAM |
| `qwen2` | 400MB | 512MB | ★★★☆☆ | Low RAM |
| `qwen2-1b` | 1.0GB | 1.2GB | ★★★★☆ | Daily use |
| `gemma2b` | 1.4GB | 2GB | ★★★★☆ | Google quality |
| `qwen2-3b` | 2.0GB | 3GB | ★★★★★ | Best quality |
| `phi2` | 1.6GB | 3GB | ★★★★☆ | Coding tasks |

---

## **Commands**

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

### Server & API

```bash
# OpenAI-Compatible Server (port 8080)
pai server start         # Start API server
pai server stop          # Stop the server
pai server status        # Show server info

# REST API + Web Dashboard (port 8081)
pai api web              # Start API + Web Dashboard
pai api start            # Start REST API only
pai api stop             # Stop API server
pai api status           # Show API endpoints
```

### System

```bash
pai status               # System information
pai doctor               # Diagnose issues
pai update               # Update PocketAI from GitHub
pai uninstall            # Remove PocketAI completely
pai help                 # Show all commands
pai version              # Version info
```

### Configuration

```bash
pai config               # Show current config
pai config set key val   # Change settings
pai config reset         # Reset to defaults
```

| Option | Default | Description |
|--------|:-------:|-------------|
| `threads` | 4 | CPU threads to use |
| `ctx_size` | 2048 | Context window size |

---

## **REST API & Web Dashboard**

Start the web dashboard and API server:

```bash
pai api web
```

Then open http://localhost:8081/ in your browser.

### API Endpoints

| Method | Endpoint | Description |
|:------:|----------|-------------|
| `GET` | `/api/health` | Health check (instant) |
| `GET` | `/api/status` | System status (cached 30s) |
| `GET` | `/api/models` | Available models |
| `GET` | `/api/models/installed` | Installed models |
| `POST` | `/api/models/install` | Install model |
| `POST` | `/api/models/use` | Switch model |
| `POST` | `/api/chat` | Send message (blocking) |
| `POST` | `/api/chat/stream` | Send message (SSE streaming) |
| `GET` | `/api/config` | Get config |
| `POST` | `/api/config` | Set config |

### Chat Request

```json
{
  "message": "Your question here",
  "max_tokens": 500
}
```

> **Note:** Default is 150 tokens. Set `max_tokens` higher for longer responses.

### OpenAI-Compatible API

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello"}]}'
```

---

## **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                        PocketAI                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐    ┌──────────┐    ┌─────────────────────┐   │
│   │   CLI   │───>│  Engine  │───>│  proot container    │   │
│   │  (pai)  │    │          │    │  (Alpine Linux)     │   │
│   └─────────┘    └──────────┘    └──────────┬──────────┘   │
│                                              │              │
│   ┌─────────┐    ┌──────────┐               ▼              │
│   │   Web   │───>│ REST API │         ┌──────────┐         │
│   │Dashboard│    │ (Python) │         │llamafile │         │
│   └─────────┘    └──────────┘         └────┬─────┘         │
│                                             │               │
│   ┌─────────┐                              ▼               │
│   │ OpenAI  │<────────────────────  GGUF Model            │
│   │ Clients │                                              │
│   └─────────┘                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| **pai CLI** | User-friendly bash interface |
| **engine.sh** | Core logic (model management, inference, API) |
| **api_server.py** | REST API + Web dashboard server |
| **llamafile** | Mozilla's portable LLM runtime |
| **proot** | Lightweight Linux container for isolation |
| **GGUF models** | Quantized models optimized for mobile |

---

## **Project Structure**

```
PocketAi/
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

---

## **Documentation**

| Document | Description |
|----------|-------------|
| [COMMANDS.md](docs/COMMANDS.md) | Complete command reference |
| [MODELS.md](docs/MODELS.md) | Model selection guide |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Problem solving |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |

---

## **Troubleshooting**

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
| API offline | Run `pai api web` |

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.

---

## **Contributing**

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## **Acknowledgments**

- [Mozilla llamafile](https://github.com/Mozilla-Ocho/llamafile) - Portable LLM runtime
- [Termux](https://termux.dev/) - Android terminal emulator
- [proot-distro](https://github.com/termux/proot-distro) - Linux containers for Termux
- Model providers: Qwen, Meta (Llama), HuggingFace, Google, Microsoft

---

## **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## **Contact**

- **Author**: Mithun
- **GitHub**: [@mithun50](https://github.com/mithun50)
- **Issues**: [GitHub Issues](https://github.com/mithun50/PocketAi/issues)

---

<div align="center">

### **Star this repo if you find it useful!**

[![GitHub stars](https://img.shields.io/github/stars/mithun50/PocketAi?style=for-the-badge&logo=github)](https://github.com/mithun50/PocketAi/stargazers)

**Made with love for the Android AI community**

</div>
