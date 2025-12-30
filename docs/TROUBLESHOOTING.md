# Troubleshooting Guide

Complete troubleshooting guide for PocketAI.

## Quick Diagnosis

```bash
pai doctor
```

This command checks everything and provides specific guidance.

---

## Installation Issues

### "proot-distro: command not found"

**Cause**: proot-distro not installed in Termux.

**Fix**:
```bash
pkg update && pkg install proot-distro
```

### Setup fails at container creation

**Cause**: Network issues or storage full.

**Fix**:
```bash
# Check storage
df -h ~

# Manual container install
proot-distro install alpine --override-alias pocketai
```

### "Permission denied" during setup

**Cause**: Script not executable.

**Fix**:
```bash
chmod +x setup.sh
chmod +x bin/pai
chmod +x core/engine.sh
./setup.sh
```

---

## Command Issues

### "pai: command not found"

**Cause**: Environment not loaded after setup.

**Fix**:
```bash
# Option 1: Source environment
source ~/.pocketai_env

# Option 2: Restart terminal
exit
# Then open Termux again
```

**Verify fix**:
```bash
which pai
# Should show: /path/to/pocketai/bin/pai
```

### "No model active"

**Cause**: No model installed or selected.

**Fix**:
```bash
# Install a model
pai install qwen2      # Small (512MB RAM)
pai install qwen2-1b   # Recommended (1.2GB RAM)

# Or select existing model
pai models installed   # See what's available
pai use smollm2        # Switch to it
```

---

## Model Issues

### Model download fails

**Cause**: Network issues or insufficient storage.

**Fix**:
```bash
# Check storage (need at least model size + 500MB)
df -h ~

# Check internet
ping -c 3 huggingface.co

# Retry download
pai install smollm2
```

### Model switching doesn't work

**Cause**: Model file not found or wrong name.

**Fix**:
```bash
# List actual model files
ls -la ~/ALLM/pocketai/models/

# Use exact filename (without .gguf)
pai use qwen2.5-0.5b-instruct-q4_k_m
```

### Which model should I use?

| Your RAM | Recommended Model | Install Command |
|----------|-------------------|-----------------|
| < 512MB | smollm2 | `pai install smollm2` |
| 512MB-1GB | qwen2 | `pai install qwen2` |
| 1-2GB | qwen2-1b | `pai install qwen2-1b` |
| 2-3GB | gemma2b | `pai install gemma2b` |
| 3GB+ | qwen2-3b | `pai install qwen2-3b` |

---

## Performance Issues

### Slow responses

**Causes**: Model too large, too many threads, or low RAM.

**Fixes**:
```bash
# 1. Use smaller model
pai use smollm2

# 2. Reduce CPU threads
pai config set threads 2

# 3. Reduce context size
pai config set ctx_size 1024

# 4. Close other apps before chatting
```

### App crashes / Out of memory

**Cause**: Model requires more RAM than available.

**Fix**:
```bash
# Switch to tiny model
pai install smollm2
pai use smollm2

# Apply memory-saving settings
pai config set threads 1
pai config set ctx_size 512
```

### First response is slow, then faster

**Cause**: Normal behavior - model loads into memory on first use.

**Note**: This is expected. The model needs to load (~5-30 seconds depending on size).

---

## Container Issues

### "Container not created"

**Cause**: Setup incomplete or container removed.

**Fix**:
```bash
# Reinstall container
proot-distro install alpine --override-alias pocketai
./setup.sh
```

### "Engine not found in container"

**Cause**: Llamafile binary not copied to container.

**Fix**:
```bash
# Rerun setup to reinstall engine
rm -f ~/ALLM/pocketai/data/llamafile
./setup.sh
```

### Container runs but model fails

**Cause**: Architecture mismatch or corrupted model.

**Fix**:
```bash
# Check architecture
uname -m
# Should be: aarch64 (ARM64) or x86_64

# Redownload model
pai remove qwen2
pai install qwen2
```

---

## Chat Issues

### Empty AI responses

**Cause**: Model not loaded properly or prompt format issue.

**Fix**:
```bash
# Verify model works
pai ask "Hello"

# If still empty, reinstall model
pai remove <model>
pai install <model>
```

### Weird/random responses

**Cause**: Model confusion or context overflow.

**Fix**:
```bash
# Start fresh chat session
# (Just exit and restart)
pai chat

# Or use ask for single questions
pai ask "What is 2+2?"
```

### Responses in wrong language

**Cause**: Some models default to other languages.

**Fix**:
```bash
# Use English-focused model
pai install qwen2-1b
pai use qwen2-1b

# Or specify in your question
pai ask "Answer in English: What is AI?"
```

---

## Configuration Issues

### Config changes don't apply

**Cause**: Config file syntax error.

**Fix**:
```bash
# Reset config
pai config reset

# Set options again
pai config set threads 4
pai config set ctx_size 2048
```

### View current config

```bash
pai config
```

---

## Storage Issues

### Running out of space

**Fix**:
```bash
# Check model sizes
ls -lh ~/ALLM/pocketai/models/

# Remove unused models
pai remove tinyllama
pai remove phi2

# Check total usage
du -sh ~/ALLM/pocketai/
```

### Clean up everything

```bash
# Remove all models (keeps engine)
rm -rf ~/ALLM/pocketai/models/*

# Fresh start (removes data too)
rm -rf ~/ALLM/pocketai/data
./setup.sh
```

---

## Known Warnings (Can Ignore)

### "lscpu: cannot locate symbol"

**Status**: Cosmetic warning, doesn't affect functionality.

### "warning: cpu frequency detection not supported"

**Status**: Normal on Android, doesn't affect operation.

---

## Debug Mode

For detailed output when reporting issues:

```bash
# Verbose doctor
bash -x ~/ALLM/pocketai/bin/pai doctor

# Verbose chat
bash -x ~/ALLM/pocketai/bin/pai ask "test"
```

---

## Full Reset

If nothing works:

```bash
# Nuclear option - removes everything
rm -rf ~/ALLM/pocketai/data
rm -rf ~/ALLM/pocketai/models
proot-distro remove pocketai

# Reinstall
./setup.sh
```

---

## Get Help

1. Run `pai doctor` first
2. Check this troubleshooting guide
3. Look at error messages carefully
4. Report issues: [GitHub Issues](https://github.com/mithun50/PocketAi/issues)

When reporting issues, include:
- Output of `pai doctor`
- Output of `pai status`
- Your device RAM: `free -h`
- Your architecture: `uname -m`
