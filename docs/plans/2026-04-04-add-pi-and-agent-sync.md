# Add Pi + agent-sync Support

**Goal:** Make Pi a first-class alternative to Claude Code, and integrate `agent-sync` so each container can be provisioned with project-specific skills, extensions, and config — all managed from the host.

**Architecture:** Two complementary changes: (1) Add Pi Justfile recipes mirroring the existing Claude ones, and (2) add host-side `sync` recipes that run `agent-sync` in the project directory on the host. Since project dirs are bind-mounted, the installed skills/extensions/prompts appear inside the container automatically — no `agent-sync` binary needed in the Docker image, no network access required from inside containers.

**Tech Stack:** Just (Justfile), Bash (ccr script), Docker (Dockerfile), Markdown (docs)

---

## How It All Fits Together

```
Host (macOS)                              Container (Debian)
─────────────                             ─────────────────
agent-sync runs HERE                      /workspace/ (bind mount)
  ↓
projects/my-project/
  ├── .agent-sync/state.json              ──►  .agent-sync/state.json
  ├── .agents/skills/*/SKILL.md           ──►  .agents/skills/*/SKILL.md
  ├── .pi/extensions/*/                   ──►  .pi/extensions/*/
  ├── .pi/prompts/*.md                    ──►  .pi/prompts/*.md
  ├── .claude/commands/*.md               ──►  .claude/commands/*.md
  ├── .claude/hooks/...                   ──►  .claude/hooks/...
  └── your-project-files/                 ──►  your-project-files/
```

**Workflow:**
1. `just create my-project` — container created, project dir bind-mounted
2. `just sync my-project bundle/research` — runs `agent-sync add` on the **host** in `projects/my-project/`
3. Files appear in the container immediately via bind mount
4. `just pi my-project` or `just claude my-project` — both tools discover the installed skills

---

## Task 1: Add Pi Justfile Recipes ✅

**Files:**
- Modify: `Justfile`

**Step 1: Add `pi` recipe**

Add after the `claude-safe` recipe block:

```just
# Run Pi coding agent (auto-starts, optional prompt)
pi name *PROMPT:
    #!/usr/bin/env bash
    set -euo pipefail
    state=$(docker inspect -f '{{{{.State.Status}}}}' {{prefix}}{{name}} 2>/dev/null || true)
    if [ "$state" != "running" ]; then
        docker start {{prefix}}{{name}} > /dev/null
    fi
    if [ -n "{{PROMPT}}" ]; then
        docker exec -it {{prefix}}{{name}} pi -p "{{PROMPT}}"
    else
        docker exec -it {{prefix}}{{name}} pi
    fi
```

**Step 2: Add `pi-safe` recipe (restricted tools)**

```just
# Run Pi with restricted tools (read-only, no bash/write)
pi-safe name *PROMPT:
    #!/usr/bin/env bash
    set -euo pipefail
    state=$(docker inspect -f '{{{{.State.Status}}}}' {{prefix}}{{name}} 2>/dev/null || true)
    if [ "$state" != "running" ]; then
        docker start {{prefix}}{{name}} > /dev/null
    fi
    if [ -n "{{PROMPT}}" ]; then
        docker exec -it {{prefix}}{{name}} pi --tools read -p "{{PROMPT}}"
    else
        docker exec -it {{prefix}}{{name}} pi --tools read
    fi
```

**Step 3: Verify**

Run: `just --list`
Expected: `pi` and `pi-safe` appear.

**Step 4: Commit**

```bash
git add Justfile
git commit -m "feat: add pi and pi-safe Justfile recipes"
```

---

## Task 2: Add Host-Side `sync` Recipes ✅

**Files:**
- Modify: `Justfile`

These recipes run `agent-sync` on the **host** (not inside the container), targeting the project directory. The bind mount means everything appears in the container immediately.

**Step 1: Add `sync` recipe**

Runs `agent-sync add` in the project dir to install items/bundles:

```just
# ── agent-sync (host-side) ────────────────────────────────────────

# Install agent config (skills, extensions, hooks) into a project dir
sync name +ITEMS:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(pwd)/projects/{{name}}"
    agent-sync add {{ITEMS}}
```

**Step 2: Add `sync-restore` recipe**

Restores missing files from an existing `.agent-sync/state.json`:

```just
# Restore agent config from .agent-sync/state.json
sync-restore name:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(pwd)/projects/{{name}}"
    if [ ! -f .agent-sync/state.json ]; then
        echo "No .agent-sync/state.json in projects/{{name}}/."
        echo "Run 'just sync {{name}} <bundle/item>' first."
        exit 1
    fi
    agent-sync restore
```

**Step 3: Add `sync-status` recipe**

```just
# Show agent-sync status for a project
sync-status name:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(pwd)/projects/{{name}}"
    agent-sync status
```

**Step 4: Add `sync-remove` recipe**

```just
# Remove agent-sync items from a project
sync-remove name +ITEMS:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "$(pwd)/projects/{{name}}"
    agent-sync remove {{ITEMS}}
```

**Step 5: Verify**

Run: `just --list`
Expected: `sync`, `sync-restore`, `sync-status`, `sync-remove` appear.

**Step 6: Commit**

```bash
git add Justfile
git commit -m "feat: add host-side agent-sync recipes"
```

---

## Task 3: Update `create` Recipe for Pi Provider Keys ✅

**Files:**
- Modify: `Justfile`
- Modify: `.env.example`

**Step 1: Update `.env.example`**

```
# Optional: only needed if using API-key billing instead of a Claude subscription.
# Subscription users can skip this and use `just login <name>` instead.
ANTHROPIC_API_KEY=

# Optional: for Pi coding agent with non-Anthropic providers.
# Pi defaults to the anthropic provider. Set keys for whichever provider you use.
# GOOGLE_API_KEY=
# OPENAI_API_KEY=
```

**Step 2: Update `create` recipe to forward Pi provider env vars**

```just
    docker create \
        --name {{prefix}}{{name}} \
        --hostname {{name}} \
        -e ANTHROPIC_API_KEY \
        -e GOOGLE_API_KEY \
        -e OPENAI_API_KEY \
        -v "$(pwd)/projects/{{name}}:/workspace" \
        {{DOCKER_ARGS}} \
        {{image}} \
        sleep infinity
```

**Step 3: Commit**

```bash
git add .env.example Justfile
git commit -m "feat: forward Pi provider API keys to containers"
```

---

## Task 4: Add Pi Config File to Docker Image ✅

**Files:**
- Create: `config/pi-settings.json`
- Modify: `Dockerfile`

**Step 1: Create `config/pi-settings.json`**

```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514"
}
```

**Step 2: Add COPY to Dockerfile**

After the existing Claude config copies:

```dockerfile
# ── Pi Config ────────────────────────────────────────────────────
RUN mkdir -p /home/coder/.pi/agent
COPY --chown=coder:coder config/pi-settings.json /home/coder/.pi/agent/settings.json
```

**Step 3: Verify build**

Run: `just build`
Expected: Build succeeds.

**Step 4: Commit**

```bash
git add config/pi-settings.json Dockerfile
git commit -m "feat: add pi settings config and copy into image"
```

---

## Task 5: Update `ccr` Script ✅

**Files:**
- Modify: `ccr`

**Step 1: Add Pi and sync examples to usage output**

Add after the existing examples:

```bash
    echo "  ccr pi my-project              Start Pi coding agent"
    echo "  ccr pi my-project \"prompt\"      Run Pi with a prompt"
    echo "  ccr pi-safe my-project          Start Pi in restricted mode"
    echo "  ccr sync my-project bundle/research  Install a skill bundle"
    echo "  ccr sync-status my-project      Show agent-sync status"
    echo "  ccr sync-restore my-project     Restore from state.json"
```

**Step 2: Verify**

Run: `zsh -n ccr`
Expected: No output (syntax OK).

**Step 3: Commit**

```bash
git add ccr
git commit -m "feat: add pi and sync examples to ccr usage"
```

---

## Task 6: Update README.md ✅

**Files:**
- Modify: `README.md`

**Step 1: Update opening description**

Change first paragraph to mention both tools:

```markdown
Isolated Docker containers for running [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
and [Pi](https://github.com/mariozechner/pi-coding-agent) in fully autonomous mode
without affecting your host machine.
```

**Step 2: Update "Tools Inside the Container"**

```markdown
git, python3, uv, Node.js 22, R, DuckDB, just, build-essential, Claude Code CLI, Pi Coding Agent.
```

**Step 3: Add Pi and sync recipes to the table**

```markdown
| `just pi <name> [prompt]` | Run Pi coding agent (auto-starts) |
| `just pi-safe <name> [prompt]` | Run Pi with restricted tools |
| `just sync <name> <items>` | Install agent config (skills, extensions) into project |
| `just sync-restore <name>` | Restore agent config from `state.json` |
| `just sync-status <name>` | Show agent-sync status |
| `just sync-remove <name> <items>` | Remove agent-sync items |
```

**Step 4: Add "Per-Project Agent Config" section**

New section after Recipes:

```markdown
## Per-Project Agent Config

Each project can have its own AI skills, extensions, and hooks managed by
`agent-sync`. Config is managed on the **host** and appears in containers
via the bind mount.

### Prerequisites

Install `agent-sync` on your Mac (one-time):
```bash
curl -fsSL <install-url> | sh
```

### Adding skills and bundles

```bash
# Install a bundle (group of related skills)
just sync my-project bundle/research

# Install individual items
just sync my-project skill/python-data-sql pi/extension/forge

# See what's installed
just sync-status my-project

# Remove items
just sync-remove my-project skill/python-data-sql
```

### Sharing config with collaborators

The `.agent-sync/state.json` file tracks what's installed. Commit it to git.
Collaborators restore the same setup with:

```bash
just sync-restore my-project
```
```

**Step 5: Add "Choosing Between Claude and Pi" blurb**

```markdown
## Claude Code vs Pi

Both are available in every container. Use whichever fits your workflow:

| | Claude Code | Pi |
|---|---|---|
| Provider | Anthropic only | Anthropic, Google, OpenAI |
| Auth | Subscription or API key | API key |
| Autonomous mode | `--dangerously-skip-permissions` | Default (all tools enabled) |
| Extensibility | Hooks, commands, agents | Skills, extensions, themes, prompts |
| Best for | Deep Anthropic integration | Multi-provider, customizable workflows |
```

**Step 6: Update Quick Start**

Add step 5b showing Pi as an alternative:

```markdown
# 5a. Start Claude
just claude my-project

# 5b. Or start Pi
just pi my-project
```

**Step 7: Commit**

```bash
git add README.md
git commit -m "docs: add Pi and agent-sync to README"
```

---

## Task 7: Update `docs/getting-started.md` ✅

**Files:**
- Modify: `docs/getting-started.md`

**Step 1: Add "Pi Coding Agent" to Key Concepts**

```markdown
### Pi Coding Agent

**Pi** is an alternative AI coding agent that also runs inside the container.
While Claude Code is Anthropic's native CLI, Pi is a more extensible harness
that supports multiple AI providers (Anthropic, Google, OpenAI) and can be
customized with skills, extensions, and themes. You can use either — or both.
```

**Step 2: Add "agent-sync" to Key Concepts**

```markdown
### agent-sync

**agent-sync** manages AI agent configuration per project. It installs skills
(shared across Claude and Pi), Claude-specific hooks and commands, and
Pi-specific extensions and prompts. You run it on your Mac (not inside the
container), and the files appear in the container through the shared folder.
```

**Step 3: Add "Working With Pi" section**

Mirror the Claude section with Pi equivalents.

**Step 4: Add "Provisioning with agent-sync" section**

Walk through the host-side workflow.

**Step 5: Update Recipes Reference table**

Add all new recipes.

**Step 6: Update Glossary**

```markdown
| **Pi** | An extensible AI coding agent supporting multiple providers |
| **agent-sync** | A tool that manages per-project AI skills, extensions, and config |
| **Bundle** | A named collection of skills/extensions installed together via agent-sync |
```

**Step 7: Commit**

```bash
git add docs/getting-started.md
git commit -m "docs: add Pi and agent-sync to getting-started guide"
```

---

## Task 8: Update `config/CLAUDE.md` ✅

**Files:**
- Modify: `config/CLAUDE.md`

**Step 1: Update tools table**

```markdown
| pi | Pi Coding Agent — run with `pi`, configure provider via env vars |
```

(Pi is already listed; just clarify the entry.)

**Step 2: Commit**

```bash
git add config/CLAUDE.md
git commit -m "docs: clarify pi entry in container CLAUDE.md"
```

---

## Task 9: End-to-End Smoke Test

**Step 1: Rebuild the image**

Run: `just rebuild`
Expected: Build succeeds with Pi config copied in.

**Step 2: Create a test container**

Run: `just create sync-test`

**Step 3: Provision with agent-sync on the host**

```bash
just sync sync-test bundle/research
just sync-status sync-test
```

Expected: Skills installed in `projects/sync-test/.agents/skills/`.

**Step 4: Verify files visible inside container**

```bash
just shell sync-test
ls /workspace/.agents/skills/
ls /workspace/.pi/ 2>/dev/null
exit
```

Expected: Skills directories visible.

**Step 5: Test Pi recipe**

```bash
just pi sync-test
```

Expected: Pi starts, discovers installed skills.

**Step 6: Test Claude recipe still works**

```bash
just claude sync-test
```

Expected: Claude starts, discovers installed skills.

**Step 7: Clean up**

```bash
just destroy sync-test
```

**Step 8: Final commit if needed**

```bash
git add -A
git commit -m "chore: fixups from smoke test"
```

---

## Summary of Changes

| File | Change |
|------|--------|
| `Justfile` | Add `pi`, `pi-safe`, `sync`, `sync-restore`, `sync-status`, `sync-remove` recipes; forward extra env vars in `create` |
| `Dockerfile` | Copy `config/pi-settings.json` into image |
| `config/pi-settings.json` | **New:** default Pi provider/model settings |
| `ccr` | Add Pi and sync examples to usage output |
| `.env.example` | Add optional `GOOGLE_API_KEY`, `OPENAI_API_KEY` |
| `README.md` | Add Pi recipes, agent-sync workflow, comparison table, updated quick start |
| `docs/getting-started.md` | Add Pi/agent-sync concepts, working sections, updated tables/glossary |
| `config/CLAUDE.md` | Clarify Pi entry |

**What's NOT in the Docker image:** `agent-sync`. It runs on the host only. The container just sees the resulting files via bind mount.

**Prerequisite:** `agent-sync` must be installed on the host Mac (`~/.local/bin/agent-sync`).
