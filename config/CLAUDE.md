# Container Environment

You are running inside an isolated Docker container (Debian bookworm). You have full root-equivalent access via passwordless sudo.

## Directory Layout

- `/workspace` — **Persistent project files** (bind-mounted from the host). All work should happen here.
- `/home/coder` — Your home directory. Ephemeral — lost when the container is destroyed.

## Available Tools

| Tool | Version/Notes |
|------|---------------|
| git | System package |
| python3 + uv | Use `uv` for Python package/project management |
| Node.js | v22 LTS via NodeSource |
| R | r-base from Debian repos |
| DuckDB | CLI binary |
| just | Command runner |
| build-essential | gcc, g++, make, etc. |
| claude | Claude Code CLI |
| pi | Pi Coding Agent — run with `pi`, configure provider via env vars |

## Installing Extra Packages

```bash
# System packages
sudo apt-get update && sudo apt-get install -y <package>

# Python packages (prefer uv)
uv pip install <package>

# Node packages
npm install -g <package>

# R packages
R -e 'install.packages("tidyverse", repos="https://cloud.r-project.org")'
```

## Tips

- The container is yours to break. Install anything, change any config.
- If something goes wrong, the host can destroy and recreate the container without losing `/workspace` files.
- Authentication is handled either via `claude login` (subscription) or the `ANTHROPIC_API_KEY` environment variable (API key).
