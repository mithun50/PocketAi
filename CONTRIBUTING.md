# Contributing to PocketAI

Thank you for your interest in contributing to PocketAI!

## How to Contribute

### Reporting Issues

1. Check existing issues first to avoid duplicates
2. Include:
   - Output of `pai doctor`
   - Output of `pai status`
   - Your device RAM: `free -h`
   - Steps to reproduce

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test on Termux if possible
5. Commit with clear messages
6. Push and open a PR

### Code Style

- Use bash for all scripts
- Add comments for complex logic
- Follow existing naming conventions
- Test on low-RAM devices when possible

### Adding New Models

To add a new model to the catalog:

1. Find a GGUF model on HuggingFace
2. Add entry to `MODEL_CATALOG` in `core/engine.sh`:
   ```bash
   ["model-name"]="Description|Size|MinRAM_MB|URL"
   ```
3. Test the model works with `pai install` and `pai chat`
4. Update `docs/MODELS.md` with model info

### Testing

Before submitting:

```bash
# Check syntax
bash -n setup.sh
bash -n bin/pai
bash -n core/engine.sh

# Run doctor
pai doctor

# Test basic commands
pai help
pai models
pai status
```

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/PocketAi.git
cd PocketAi

# Make changes
# ...

# Test locally
./setup.sh
source ~/.pocketai_env
pai doctor
```

## Questions?

Open an issue or discussion on GitHub!
