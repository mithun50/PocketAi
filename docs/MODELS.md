# 🧠 PocketAI Models Guide

Complete guide to choosing and using AI models.

## Quick Recommendation

| Your RAM | Best Model | Install Command |
|----------|------------|-----------------|
| < 512MB | smollm2 | `pai install smollm2` |
| 512MB-1GB | qwen2 | `pai install qwen2` |
| 1-2GB | qwen2-1b | `pai install qwen2-1b` |
| 2-3GB | gemma2b | `pai install gemma2b` |
| 3GB+ | qwen2-3b | `pai install qwen2-3b` |

---

## All Available Models

### 🪶 Ultra-Light (Under 1GB RAM)

#### SmolLM2 360M
```bash
pai install smollm2
```
- **Size**: 270MB
- **RAM**: 400MB minimum
- **Speed**: ⚡⚡⚡⚡⚡ Fastest
- **Quality**: ⭐⭐
- **Best for**: Ultra-low RAM, quick responses
- **Provider**: HuggingFace

#### Qwen2.5 0.5B
```bash
pai install qwen2
```
- **Size**: 400MB
- **RAM**: 512MB minimum
- **Speed**: ⚡⚡⚡⚡
- **Quality**: ⭐⭐⭐
- **Best for**: Low RAM, decent quality
- **Provider**: Alibaba

---

### 🎯 Light (1-2GB RAM) - Recommended

#### Qwen2.5 1.5B ✨ Best Balance
```bash
pai install qwen2-1b
```
- **Size**: 1.0GB
- **RAM**: 1.2GB minimum
- **Speed**: ⚡⚡⚡
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Daily use, best quality-to-size ratio
- **Provider**: Alibaba

#### SmolLM2 1.7B
```bash
pai install smollm2-1b
```
- **Size**: 1.0GB
- **RAM**: 1GB minimum
- **Speed**: ⚡⚡⚡⚡
- **Quality**: ⭐⭐⭐
- **Best for**: Fast responses, good quality
- **Provider**: HuggingFace

#### TinyLlama 1.1B
```bash
pai install tinyllama
```
- **Size**: 669MB
- **RAM**: 1GB minimum
- **Speed**: ⚡⚡⚡⚡
- **Quality**: ⭐⭐
- **Best for**: Legacy support
- **Provider**: TinyLlama Project

---

### 🚀 Medium (2-4GB RAM)

#### Gemma 2 2B
```bash
pai install gemma2b
```
- **Size**: 1.4GB
- **RAM**: 2GB minimum
- **Speed**: ⚡⚡⚡
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Google quality, general tasks
- **Provider**: Google

#### Microsoft Phi-2 2.7B
```bash
pai install phi2
```
- **Size**: 1.6GB
- **RAM**: 3GB minimum
- **Speed**: ⚡⚡
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Coding, reasoning
- **Provider**: Microsoft

#### Qwen2.5 3B ⭐ Best Quality
```bash
pai install qwen2-3b
```
- **Size**: 2.0GB
- **RAM**: 3GB minimum
- **Speed**: ⚡⚡
- **Quality**: ⭐⭐⭐⭐⭐
- **Best for**: Best overall quality
- **Provider**: Alibaba

#### StableLM Zephyr 3B
```bash
pai install stablelm
```
- **Size**: 2.0GB
- **RAM**: 4GB minimum
- **Speed**: ⚡⚡
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Creative writing
- **Provider**: Stability AI

---

## Model Comparison

### By Quality
```
Best ─────────────────────────────────► Basic
qwen2-3b > gemma2b > qwen2-1b > phi2 > smollm2-1b > qwen2 > smollm2
```

### By Speed
```
Fastest ──────────────────────────────► Slowest
smollm2 > qwen2 > smollm2-1b > qwen2-1b > gemma2b > phi2 > qwen2-3b
```

### By Size
```
Smallest ─────────────────────────────► Largest
smollm2 (270MB) < qwen2 (400MB) < tinyllama (669MB) < qwen2-1b (1GB) < gemma2b (1.4GB) < phi2 (1.6GB) < qwen2-3b (2GB)
```

---

## Use Cases

### General Chat
**Recommended**: `qwen2-1b` or `qwen2-3b`
```bash
pai install qwen2-1b
pai chat
```

### Quick Answers
**Recommended**: `smollm2` or `qwen2`
```bash
pai install smollm2
pai ask "What time is it in Tokyo?"
```

### Coding Help
**Recommended**: `phi2` or `qwen2-3b`
```bash
pai install phi2
pai ask "Write a Python function to sort a list"
```

### Creative Writing
**Recommended**: `stablelm` or `qwen2-3b`
```bash
pai install stablelm
pai ask "Write a short story about a robot"
```

### Low-End Device
**Recommended**: `smollm2`
```bash
pai install smollm2
pai config set threads 2
pai config set ctx_size 512
```

---

## Managing Models

### Install Multiple Models
```bash
pai install smollm2
pai install qwen2-1b
pai install qwen2-3b
```

### Switch Between Models
```bash
pai use smollm2      # Quick answers
pai use qwen2-1b     # Better quality
pai use qwen2-3b     # Best quality
```

### Check Installed Models
```bash
pai models installed
```

### Remove Models
```bash
pai remove tinyllama   # Free up space
```

### Check Storage Used
```bash
ls -lh ~/ALLM/pocketai/models/
```

---

## Custom Models

You can use any GGUF model from HuggingFace:

### Download Custom Model
```bash
# Example: Download a custom GGUF model
curl -L -o ~/ALLM/pocketai/models/custom-model.gguf \
  "https://huggingface.co/user/model/resolve/main/model.Q4_K_M.gguf"
```

### Use Custom Model
```bash
pai use custom-model
pai chat
```

### Requirements for Custom Models
- Format: GGUF (`.gguf` extension)
- Quantization: Q4_K_M recommended (balance of quality/size)
- Architecture: Must be supported by llamafile

---

## Performance Tips

### For Slow Responses
```bash
# Use smaller model
pai use smollm2

# Reduce threads
pai config set threads 2

# Reduce context
pai config set ctx_size 1024
```

### For Better Quality
```bash
# Use larger model
pai use qwen2-3b

# Increase context
pai config set ctx_size 4096
```

### For Low Memory Devices
```bash
# Smallest model
pai install smollm2
pai use smollm2

# Minimal settings
pai config set threads 1
pai config set ctx_size 512

# Close other apps before chatting
```

---

## Model Sources

All models are downloaded from trusted sources:

| Model | Source |
|-------|--------|
| SmolLM2 | [HuggingFace/bartowski](https://huggingface.co/bartowski) |
| Qwen2.5 | [HuggingFace/Qwen](https://huggingface.co/Qwen) |
| TinyLlama | [HuggingFace/TheBloke](https://huggingface.co/TheBloke) |
| Gemma | [HuggingFace/bartowski](https://huggingface.co/bartowski) |
| Phi-2 | [HuggingFace/TheBloke](https://huggingface.co/TheBloke) |
| StableLM | [HuggingFace/TheBloke](https://huggingface.co/TheBloke) |
