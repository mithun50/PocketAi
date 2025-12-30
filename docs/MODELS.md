# PocketAI Models Guide

Complete guide to choosing and using AI models.

## Quick Recommendation

| Your RAM | Best Model | Install Command |
|----------|------------|-----------------|
| < 512MB | smollm2 | `pai install smollm2` |
| 512MB-1GB | qwen3 | `pai install qwen3` |
| 1-2GB | llama3.2 | `pai install llama3.2` |
| 2-3GB | llama3.2-3b | `pai install llama3.2-3b` |
| 3GB+ | qwen2-3b | `pai install qwen2-3b` |

---

## 2025 Models (Recommended)

These are the newest and best-performing models for their size.

### Qwen3 0.6B (Best for Low RAM)
```bash
pai install qwen3
```
- **Size**: 400MB
- **RAM**: 512MB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐⭐
- **Best for**: Low RAM devices, quick responses
- **Provider**: Alibaba (2025)
- **Features**: Thinking mode, multilingual

### Llama 3.2 1B (Best Balance)
```bash
pai install llama3.2
```
- **Size**: 700MB
- **RAM**: 1GB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Daily use, best quality-to-size ratio
- **Provider**: Meta (2025)
- **Features**: Instruction following, reasoning

### Llama 3.2 3B (Best Quality 2025)
```bash
pai install llama3.2-3b
```
- **Size**: 2.0GB
- **RAM**: 2GB minimum
- **Speed**: Medium
- **Quality**: ⭐⭐⭐⭐⭐
- **Best for**: Best overall quality in 2025 lineup
- **Provider**: Meta (2025)
- **Features**: Advanced reasoning, coding

---

## All Available Models

### Ultra-Light (Under 1GB RAM)

#### SmolLM2 360M
```bash
pai install smollm2
```
- **Size**: 270MB
- **RAM**: 400MB minimum
- **Speed**: Fastest
- **Quality**: ⭐⭐
- **Best for**: Ultra-low RAM, quick responses
- **Provider**: HuggingFace

#### Qwen3 0.6B
```bash
pai install qwen3
```
- **Size**: 400MB
- **RAM**: 512MB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐⭐
- **Best for**: Low RAM, good quality (2025)
- **Provider**: Alibaba

#### Qwen2.5 0.5B
```bash
pai install qwen2
```
- **Size**: 400MB
- **RAM**: 512MB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐⭐
- **Best for**: Low RAM, decent quality
- **Provider**: Alibaba

#### Qwen 0.5B (Legacy)
```bash
pai install qwen
```
- **Size**: 395MB
- **RAM**: 512MB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐
- **Best for**: Legacy support
- **Provider**: Alibaba

---

### Light (1-2GB RAM) - Recommended

#### Llama 3.2 1B
```bash
pai install llama3.2
```
- **Size**: 700MB
- **RAM**: 1GB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Daily use, best quality-to-size ratio (2025)
- **Provider**: Meta

#### Qwen2.5 1.5B
```bash
pai install qwen2-1b
```
- **Size**: 1.0GB
- **RAM**: 1.2GB minimum
- **Speed**: Medium
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Daily use, smartest small model
- **Provider**: Alibaba

#### SmolLM2 1.7B
```bash
pai install smollm2-1b
```
- **Size**: 1.0GB
- **RAM**: 1GB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐⭐
- **Best for**: Fast responses, good quality
- **Provider**: HuggingFace

#### TinyLlama 1.1B
```bash
pai install tinyllama
```
- **Size**: 669MB
- **RAM**: 1GB minimum
- **Speed**: Fast
- **Quality**: ⭐⭐
- **Best for**: Legacy support
- **Provider**: TinyLlama Project

---

### Medium (2-4GB RAM)

#### Llama 3.2 3B
```bash
pai install llama3.2-3b
```
- **Size**: 2.0GB
- **RAM**: 2GB minimum
- **Speed**: Medium
- **Quality**: ⭐⭐⭐⭐⭐
- **Best for**: Best 2025 quality, general tasks
- **Provider**: Meta

#### Gemma 2 2B
```bash
pai install gemma2b
```
- **Size**: 1.4GB
- **RAM**: 2GB minimum
- **Speed**: Medium
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Google quality, general tasks
- **Provider**: Google

#### Microsoft Phi-2 2.7B
```bash
pai install phi2
```
- **Size**: 1.6GB
- **RAM**: 3GB minimum
- **Speed**: Slow
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Coding, reasoning
- **Provider**: Microsoft

#### Qwen2.5 3B (Best Classic Quality)
```bash
pai install qwen2-3b
```
- **Size**: 2.0GB
- **RAM**: 3GB minimum
- **Speed**: Slow
- **Quality**: ⭐⭐⭐⭐⭐
- **Best for**: Best overall quality
- **Provider**: Alibaba

#### StableLM Zephyr 3B
```bash
pai install stablelm
```
- **Size**: 2.0GB
- **RAM**: 4GB minimum
- **Speed**: Slow
- **Quality**: ⭐⭐⭐⭐
- **Best for**: Creative writing
- **Provider**: Stability AI

---

## Model Comparison

### By Quality (2025 Rankings)
```
Best ──────────────────────────────────────────────► Basic
llama3.2-3b > qwen2-3b > llama3.2 > qwen2-1b > qwen3 > smollm2
```

### By Speed
```
Fastest ───────────────────────────────────────────► Slowest
smollm2 > qwen3 > llama3.2 > qwen2-1b > gemma2b > llama3.2-3b > qwen2-3b
```

### By Size
```
Smallest ──────────────────────────────────────────► Largest
smollm2 (270MB) < qwen3 (400MB) < llama3.2 (700MB) < qwen2-1b (1GB) < gemma2b (1.4GB) < llama3.2-3b (2GB)
```

---

## Use Cases

### General Chat
**Recommended**: `llama3.2` or `llama3.2-3b`
```bash
pai install llama3.2
pai chat
```

### Quick Answers
**Recommended**: `qwen3` or `smollm2`
```bash
pai install qwen3
pai ask "What time is it in Tokyo?"
```

### Coding Help
**Recommended**: `phi2` or `llama3.2-3b`
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
pai install qwen3
pai install llama3.2
```

### Switch Between Models
```bash
pai use smollm2      # Quick answers
pai use qwen3        # Better quality
pai use llama3.2     # Best quality
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
pai use llama3.2-3b

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
| Qwen3 | [HuggingFace/unsloth](https://huggingface.co/unsloth) |
| Llama 3.2 | [HuggingFace/hugging-quants](https://huggingface.co/hugging-quants) |
| SmolLM2 | [HuggingFace/bartowski](https://huggingface.co/bartowski) |
| Qwen2.5 | [HuggingFace/Qwen](https://huggingface.co/Qwen) |
| TinyLlama | [HuggingFace/TheBloke](https://huggingface.co/TheBloke) |
| Gemma | [HuggingFace/bartowski](https://huggingface.co/bartowski) |
| Phi-2 | [HuggingFace/TheBloke](https://huggingface.co/TheBloke) |
| StableLM | [HuggingFace/TheBloke](https://huggingface.co/TheBloke) |

---

## Model Changelog

### 2025 Additions
- **Qwen3 0.6B** - New thinking mode, better multilingual
- **Llama 3.2 1B** - Meta's latest small model
- **Llama 3.2 3B** - Best quality in 2025 lineup

### Legacy Models
- Qwen 0.5B, TinyLlama - Still available for compatibility
