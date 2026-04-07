# claude-container

Isolated Docker containers for running [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [Pi](https://github.com/mariozechner/pi-coding-agent) in fully autonomous mode without affecting your host machine.

Project files are bind-mounted so they persist on the host. Containers are long-lived (stop/start). Everything is managed through a Justfile.

## Prerequisites

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh)
- [just](https://github.com/casey/just) — `brew install just`
- A [Claude Pro or Max subscription](https://claude.ai), **or** an [Anthropic API key](https://console.anthropic.com/)

## Quick Start

```bash
# 1. Install Colima + Docker
just setup

# 2. Build the image
just build

# 3. Create a project
just create my-project

# 4. Log in (subscription users)
just login my-project

# Or for API key users: cp .env.example .env, set your key, recreate container

# 5a. Start Claude
just claude my-project

# 5b. Or start Pi
just pi my-project
```

## Tools Inside the Container

git, python3, uv, Node.js 22, R, DuckDB, just, build-essential, Claude Code CLI, Pi Coding Agent.

## Claude Code vs Pi

Both are available in every container. Use whichever fits your workflow:

| | Claude Code | Pi |
|---|---|---|
| Provider | Anthropic only | Anthropic (supports others via shell) |
| Auth | Subscription or API key | Subscription or API key |
| Autonomous mode | `--dangerously-skip-permissions` | Default (all tools enabled) |
| Extensibility | Hooks, commands, agents | Skills, extensions, themes, prompts |
| Best for | Deep Anthropic integration | Multi-provider, customizable workflows |

## Recipes

| Recipe | Purpose |
|--------|---------|
| `just setup` | Install Colima + Docker CLI, start VM |
| `just build` | Build the container image |
| `just rebuild` | Build without cache |
| `just create <name> [-- DOCKER_ARGS]` | Create container with bind-mounted project dir |
| `just start/stop/restart <name>` | Container lifecycle |
| `just login <name>` | Log in with Claude subscription (once per container) |
| `just shell <name>` | Open a bash shell (auto-starts) |
| `just claude <name> [prompt]` | Run Claude in YOLO mode (auto-starts) |
| `just claude-safe <name> [prompt]` | Run Claude with permission prompts |
| `just pi <name> [prompt]` | Run Pi coding agent (auto-starts) |
| `just pi-safe <name> [prompt]` | Run Pi with restricted tools |
| `just cp-to <name> <src> <dest>` | Copy files from host to container |
| `just cp-from <name> <src> <dest>` | Copy files from container to host |
| `just destroy <name>` | Remove container (project files kept) |
| `just list` | Show all claude containers |
| `just logs <name>` | Show container logs |
| `just stats` | Resource usage for all containers |
| `just colima-start/stop/status` | Manage the Colima VM |

## Per-Project Agent Config (Optional)

> **Note:** The `sync` recipes require [`agent-sync`](https://github.com/kljensen/agent-sync), a separate tool for managing per-project AI skills, extensions, and hooks. `agent-sync` is not included in this repo — you'll need to install it yourself and configure it to point at your own config catalog. The recipes are included here as an example of how to integrate such a tool; feel free to remove them from the Justfile if you don't need them.

If you have `agent-sync` set up, you can provision each project with specific skills and extensions on the **host**. Since the project directory is bind-mounted, the files appear inside the container automatically.

| Recipe | Purpose |
|--------|--------|
| `just sync <name> <items>` | Install agent config (skills, extensions) into project |
| `just sync-restore <name>` | Restore agent config from `state.json` |
| `just sync-status <name>` | Show agent-sync status |
| `just sync-remove <name> <items>` | Remove agent-sync items |

```bash
# Install a bundle (group of related skills)
just sync my-project bundle/research

# See what's installed
just sync-status my-project

# Collaborators restore the same setup from state.json
just sync-restore my-project
```

## Extra Docker Options

Pass additional mounts, ports, or env vars when creating a container:

```bash
just create my-project -- -p 8080:8080 -e SECRET=val --mount type=bind,src=/data,dst=/data
```

## Using `ccr` From Anywhere

The `ccr` (Claude Container Runner) script lets you run any recipe from any directory without `cd`-ing into this repo. To set it up:

```bash
# Copy the script to somewhere on your PATH
cp ccr ~/bin/ccr    # or /usr/local/bin/ccr
chmod +x ~/bin/ccr
```

If you cloned this repo somewhere other than `~/repos/claude-container`, set the path:

```bash
# In your ~/.zshrc
export CLAUDE_CONTAINER_DIR="$HOME/path/to/claude-container"
```

Then use `ccr` instead of `just` from anywhere:

```bash
ccr build
ccr create my-project
ccr claude my-project
ccr pi my-project
ccr list
ccr --recipes          # show all available recipes
```

## How It Works

- **Colima** provides the Docker runtime (free, uses Apple Virtualization.framework)
- Containers run `sleep infinity` and you `exec` into them
- `/workspace` inside the container is bind-mounted to `projects/<name>/` on the host
- **Subscription auth:** `just login <name>` runs `claude login` inside the container (once per container)
- **API key auth** (optional): set keys in `.env`; they're forwarded to containers only when present
- **agent-sync** (optional): runs on the host, writes skills/extensions into the project dir; the container sees them via bind mount
- `just destroy` removes the container but project files stay in `projects/`
