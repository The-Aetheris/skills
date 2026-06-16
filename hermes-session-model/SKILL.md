---
name: hermes-session-model
description: "Query the actual model & provider running in the current Hermes session, bypassing stale session metadata."
version: 1.0.0
author: Nooku <nooku@the-aetheris.dev>
platforms: [macos, linux]
metadata:
  hermes:
    tags: [hermes, model, provider, session, debugging, diagnostics]
    related_skills: []
---

# Hermes Session Model

## Problem

Session metadata injected into the agent's system prompt (`Model: ..., Provider: ...`) is **often stale** — it reflects the config default at session start, NOT runtime overrides like `--model` flags from TUI workers. This causes the agent to give incorrect information about its own identity.

## Solution

Query the Hermes dashboard API (`GET /api/model/info`) which returns the **actual** model and provider being used at runtime.

This skill includes a companion script (`scripts/hermes-session-model`) that automates port discovery and API querying.

## How to Use

### Quick Answer (Recommended)

When the user asks "what model/provider are you?", instead of trusting session metadata:

```bash
python3 scripts/hermes-session-model --json
```

Or for human-readable:

```bash
python3 scripts/hermes-session-model
```

### Manual Fallback (if script unavailable)

If the script isn't available, use `terminal` directly:

```bash
# Find dashboard port by scanning processes
PORT=$(ps aux | grep -oP 'hermes.*dashboard.*--port \K\d+' | head -1)
# Or try common ports: 9120, 9121, 9122

# Query model info
curl -s http://127.0.0.1:$PORT/api/model/info
```

### Response Format (JSON)

```json
{
  "model": "deepseek-v4-flash",
  "provider": "deepseek",
  "auto_context_length": 1000000,
  "capabilities": {
    "supports_tools": true,
    "supports_vision": false,
    "supports_reasoning": true,
    "context_window": 1000000,
    "max_output_tokens": 384000,
    "model_family": "deepseek-flash"
  }
}
```

### When to Use

- User asks "model apa kamu?" or "provider apa?"
- Need to confirm actual capabilities (tools, vision, reasoning, context window)
- Session metadata looks suspicious or contradicts user's UI indicator
- Debugging model routing issues (is the `--model` override actually taking effect?)

## Background

The Hermes dashboard (FastAPI, port auto-detected) exposes `GET /api/model/info` with **no auth required from localhost**. This endpoint returns the actual model and provider being used — NOT the stale session metadata.

The companion script at `scripts/hermes-session-model` automates port discovery and querying.

## Verification

After running the script or curl command, you should get a response like:

```
Model       : deepseek-v4-flash
Provider    : deepseek
Context     : 1,000,000 tokens
Max output  : 384,000 tokens
Family      : deepseek-flash
Tools       : ✅
Vision      : ❌
Reasoning   : ✅
```

## Notes

- The dashboard port may vary (9120, 9121, 9122 depending on profile). The script auto-detects it.
- Only `GET /api/model/info` works without auth from localhost. Other endpoints (`/api/model/options`, `/api/model/auxiliary`) require auth.
- For Telegram/Discord gateway sessions (not TUI), `--model` override still applies — the dashboard API will reflect the correct model.
