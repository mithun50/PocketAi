# 📖 PocketAI Command Reference

Complete documentation for all `pai` commands.

## Table of Contents

- [Setup Commands](#setup-commands)
- [Model Commands](#model-commands)
- [Chat Commands](#chat-commands)
- [Configuration Commands](#configuration-commands)
- [Info Commands](#info-commands)

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

### `pai status`

Display system status and information.

```bash
pai status
```

**Output includes:**
- PocketAI version
- Engine version
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
- ✓ proot-distro installed
- ✓ Container exists
- ✓ Engine binary exists
- ✓ Model active
- ✓ RAM available
- ✓ Storage free

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
# Examples
pai install smollm2      # Tiny (270MB)
pai install qwen2        # Small (400MB)
pai install qwen2-1b     # Best balance (1GB)
pai install qwen2-3b     # Best quality (2GB)
```

**Available models:**

| Model | Size | RAM | Quality |
|-------|------|-----|---------|
| smollm2 | 270MB | 400MB | ⭐⭐ |
| qwen2 | 400MB | 512MB | ⭐⭐⭐ |
| qwen2-1b | 1.0GB | 1.2GB | ⭐⭐⭐⭐ |
| smollm2-1b | 1.0GB | 1GB | ⭐⭐⭐ |
| gemma2b | 1.4GB | 2GB | ⭐⭐⭐⭐ |
| phi2 | 1.6GB | 3GB | ⭐⭐⭐⭐ |
| qwen2-3b | 2.0GB | 3GB | ⭐⭐⭐⭐⭐ |

---

### `pai use <model>`

Switch to a different installed model.

```bash
pai use qwen2-1b
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
▸ Chat with qwen2-1b.gguf
▸ Type your message, press Enter. Type 'exit' to quit.

You> Hello, how are you?
AI> I'm doing well, thank you for asking! How can I help you today?

You> What is Python?
AI> Python is a popular programming language known for its simple syntax...

You> exit
▸ Chat ended
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
Engine: llamafile 0.8.13
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
pai install qwen2-1b
pai chat
```

### Switch between models
```bash
pai install smollm2
pai install qwen2-1b
pai use smollm2      # Use tiny model
pai ask "Hello"
pai use qwen2-1b     # Switch to better model
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
