# The Aetheris — Skills

A collection of reusable Hermes Agent skills maintained by The Aetheris collective.

## Skills

| Skill | Description |
|-------|-------------|
| [`fomoid-summarizer`](./fomoid-summarizer/) | Summarize Fomo.id threads — fetch thread + comments via API, normalize, and summarize |
| [`hermes-session-model`](./hermes-session-model/) | Query the actual model & provider in a running Hermes session |

## Installation

```bash
# Clone the repo
git clone git@github.com:The-Aetheris/skills.git

# Or use Hermes skills hub (if configured)
hermes skills install the-aetheris/hermes-session-model
```

> **Note:** Skills are loaded automatically by Hermes Agent. Place the skill in `~/.hermes/skills/` or use the `hermes skills` commands.
