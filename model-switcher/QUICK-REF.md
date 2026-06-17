# Model Switcher Quick Reference

## Common Commands

### Check Status
```bash
hermes model show              # Current model & provider
hermes model list              # All available models
```

### Quick Switching
```bash
# High reasoning (debugging, complex analysis)
hermes model high-thinking

# Medium reasoning (balanced tasks)
hermes model medium-thinking

# Low reasoning (execution, quick tasks)
hermes model low-thinking
```

### Provider Switch
```bash
# Default custom provider
hermes provider custom

# 9router routing
hermes provider 9router

# Deepseek API
hermes provider deepseek
```

## Provider-Model Matrix

| Provider | High-Thinking | Medium-Thinking | Low-Thinking |
|---|---|---|---|
| **custom** | ✓ | ✓ | ✓ |
| **9router** | ✓ | ✓ | ✓ |
| **deepseek** | ✓ | ✓ | ✓ |

## Session Restart Required (Always!)

```bash
# After any model change, MUST restart session:
/new

# Or restart gateway:
hermes gateway restart
```

## Troubleshooting Quick Fixes

### "Model not found"
```bash
hermes model list
hermes model high-thinking --provider custom
```

### "Provider connection failed"
```bash
curl -I http://localhost:20128/v1/models
hermes provider custom
```

### Gateway not working
```bash
pkill -f hermes-gateway
cd ~/.hermes/profiles/[PROFILE] && hermes gateway run
```

## Agent Usage Guidelines

### Xenna (Manager)
- Always use high-thinking for system analysis
- Switch to low-thinking for quick administrative tasks
- Cross-profile switching for coordination

### Nooku (Engineer)
- High-thinking: debugging, research, architecture
- Medium-thinking: coding, implementation
- Low-thinking: simple bug fixes, quick tests

### Naaza (Creative)
- Medium-thinking: brainstorming, content creation
- Low-thinking: execution, quick generation
- Rarely needs high-thinking

## Error Recovery Flow

1. `hermes model show` → Check current config
2. `hermes model list` → Verify model available
3. `hermes model [level] --provider custom` → Fallback to custom
4. `/new` → Restart session
5. If still broken: `hermes gateway restart`