# 🤖 PocketAI

<div align="center">

**Run AI models locally on your Android phone**

*No cloud. No subscription. No compilation. Just works.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20(Termux)-green.svg)](https://termux.dev/)
[![Engine](https://img.shields.io/badge/Engine-llamafile-blue.svg)](https://github.com/Mozilla-Ocho/llamafile)

</div>

---

## ✨ Features

- **🔒 100% Offline** - Works without internet after initial setup
- **🆓 Free Forever** - No subscriptions, no API keys, no hidden costs
- **⚡ No Compilation** - Powered by Mozilla llamafile (just download and run)
- **🛡️ Private & Secure** - Your data never leaves your device
- **📱 Android Native** - Optimized for mobile with proot isolation
- **🎯 Multiple Models** - Choose from tiny (270MB) to powerful (2GB+)

## 🚀 Quick Start

### One-Command Install

```bash
# Clone the repository
git clone https://github.com/mithun50/PocketAi.git
cd PocketAi

# Run setup
./setup.sh
```

### Manual Install

```bash
# Install in Termux
pkg install git
git clone https://github.com/mithun50/PocketAi.git ~/pocketai
cd ~/pocketai
./setup.sh
```

### Start Using

```bash
# Activate environment (or restart terminal)
source ~/.pocketai_env

# Install a model
pai install qwen2-1b

# Start chatting!
pai chat
```

## 📦 Available Models

| Model | Size | RAM | Quality | Best For |
|-------|------|-----|---------|----------|
| `smollm2` | 270MB | 400MB | ⭐⭐ | Ultra-low RAM devices |
| `qwen2` | 400MB | 512MB | ⭐⭐⭐ | Low RAM, good quality |
| `qwen2-1b` | 1.0GB | 1.2GB | ⭐⭐⭐⭐ | **Best balance** ✨ |
| `smollm2-1b` | 1.0GB | 1GB | ⭐⭐⭐ | Fast responses |
| `gemma2b` | 1.4GB | 2GB | ⭐⭐⭐⭐ | Google quality |
| `qwen2-3b` | 2.0GB | 3GB | ⭐⭐⭐⭐⭐ | Best quality |
| `phi2` | 1.6GB | 3GB | ⭐⭐⭐⭐ | Coding tasks |

## 🎮 Commands

### Basic Usage

```bash
pai help                 # Show all commands
pai chat                 # Interactive chat
pai ask "What is AI?"    # Quick question
```

### Model Management

```bash
pai models               # List available models
pai models installed     # List installed models
pai install <model>      # Download a model
pai use <model>          # Switch active model
pai remove <model>       # Delete a model
```

### System

```bash
pai status               # System information
pai doctor               # Diagnose issues
pai config               # View configuration
pai config set key val   # Change settings
```

## 📁 Project Structure

```
pocketai/
├── bin/
│   └── pai              # CLI tool
├── core/
│   └── engine.sh        # Core engine
├── data/
│   ├── config           # Configuration
│   └── llamafile        # Runtime engine
├── models/              # Downloaded models
├── docs/                # Documentation
│   ├── COMMANDS.md      # Command reference
│   ├── MODELS.md        # Model guide
│   └── TROUBLESHOOTING.md
├── setup.sh             # Installer
└── README.md
```

## ⚙️ Configuration

Configuration file: `~/ALLM/pocketai/data/config`

| Option | Default | Description |
|--------|---------|-------------|
| `threads` | 4 | CPU threads to use |
| `ctx_size` | 2048 | Context window size |
| `active_model` | - | Currently active model |

```bash
# Change settings
pai config set threads 2      # Use 2 threads
pai config set ctx_size 1024  # Smaller context
```

## 🔧 Requirements

- **Device**: Android phone/tablet
- **App**: [Termux](https://termux.dev/) from F-Droid
- **Storage**: 1GB+ free (varies by model)
- **RAM**: 512MB+ (more = better models)

## 🐛 Troubleshooting

### Quick Fix
```bash
pai doctor    # Diagnose all issues
```

### Common Issues

| Issue | Solution |
|-------|----------|
| `pai: command not found` | Run `source ~/.pocketai_env` |
| `No model active` | Run `pai install qwen2` |
| Slow responses | Use smaller model: `pai use smollm2` |
| Out of memory | Close apps, use smaller model |

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.

## 🏗️ How It Works

```
┌─────────────────────────────────────────────────────┐
│                    PocketAI                         │
├─────────────────────────────────────────────────────┤
│  User ──► pai CLI ──► engine.sh ──► llamafile      │
│                           │                         │
│                           ▼                         │
│                    proot container                  │
│                    (Alpine Linux)                   │
│                           │                         │
│                           ▼                         │
│                    GGUF Model File                  │
│                           │                         │
│                           ▼                         │
│                    AI Response                      │
└─────────────────────────────────────────────────────┘
```

1. **pai CLI** - User-friendly command interface
2. **engine.sh** - Core logic for model management
3. **llamafile** - Mozilla's portable LLM runtime
4. **proot** - Lightweight Linux container for isolation
5. **GGUF models** - Quantized models optimized for mobile

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Mozilla llamafile](https://github.com/Mozilla-Ocho/llamafile) - Portable LLM runtime
- [Termux](https://termux.dev/) - Android terminal emulator
- [proot-distro](https://github.com/termux/proot-distro) - Linux containers for Termux
- Model providers: Qwen, HuggingFace, Google, Microsoft

## 📬 Contact

- **Author**: Mithun
- **GitHub**: [@mithun50](https://github.com/mithun50)
- **Issues**: [GitHub Issues](https://github.com/mithun50/PocketAi/issues)

---

<div align="center">

**⭐ Star this repo if you find it useful!**

Made with ❤️ for the Android AI community

</div>
