# Add Pi Coding Agent Support

**Goal:** Add Pi as a first-class alternative to Claude Code in every layer of the project — Justfile recipes, the `ccr` wrapper, Dockerfile config, and documentation.

**Architecture:** Pi is already installed in the Docker image (`npm install -g @mariozechner/pi-coding-agent`) and listed in `config/CLAUDE.md`. The work is adding parallel Justfile recipes (`pi`, `pi-safe`), a pi-specific settings/config file, updating `ccr`, and updating all documentation (README, getting-started guide) to present both tools as options.

**Tech Stack:** Just (Justfile), Bash (ccr script), Docker (Dockerfile), Markdown (docs)

---

## Task 1: Add Pi Justfile Recipes

**Files:**
- Modify: `Justfile`

**Step 1: Add `pi` recipe (YOLO-equivalent mode)**

Add a new recipe that mirrors `claude` but invokes `pi` inside the container. Pi doesn't have a `--dangerously-skip-permissions` flag — it uses built-in tools (read, bash, edit, write) that are enabled by default. We pass `--print` / `-p` for one-shot prompts, or run interactively without it.

Add after the `claude-safe` recipe:

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

Add a recipe that runs Pi with a limited tool set (read-only — no bash or write):

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

**Step 3: Verify recipes parse**

Run: `just --list`
Expected: `pi` and `pi-safe` appear in the recipe list.

**Step 4: Commit**

```bash
git add Justfile
git commit -m "feat: add pi and pi-safe Justfile recipes"
```

---

## Task 2: Add Pi Configuration File

**Files:**
- Create: `config/pi-settings.json`
- Modify: `Dockerfile`

**Step 1: Create Pi settings file**

Create `config/pi-settings.json` with sensible defaults for containerized use:

```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514"
}
```

> Note: Users can override provider/model via env vars or CLI flags. This just sets a reasonable default. Adjust model name to whatever is current.

**Step 2: Add COPY to Dockerfile**

Add a line after the existing Claude config copies to put Pi settings into the container:

```dockerfile
# ── Pi Config files ──────────────────────────────────────────────
RUN mkdir -p /home/coder/.pi/agent
COPY --chown=coder:coder config/pi-settings.json /home/coder/.pi/agent/settings.json
```

**Step 3: Verify Dockerfile builds**

Run: `just build`
Expected: Build succeeds. (Or dry-run: `docker build --check -t claude-container .` if available, otherwise full build.)

**Step 4: Commit**

```bash
git add config/pi-settings.json Dockerfile
git commit -m "feat: add pi settings config and copy into image"
```

---

## Task 3: Update `ccr` Script

**Files:**
- Modify: `ccr`

**Step 1: Add Pi examples to usage output**

Update the examples block in `ccr` to include Pi commands:

```bash
    echo "  ccr pi my-project              Start Pi coding agent"
    echo "  ccr pi my-project \"prompt\"      Run Pi with a prompt"
    echo "  ccr pi-safe my-project          Start Pi in restricted mode"
```

**Step 2: Verify script syntax**

Run: `zsh -n ccr`
Expected: No output (syntax OK).

**Step 3: Commit**

```bash
git add ccr
git commit -m "feat: add pi examples to ccr usage output"
```

---

## Task 4: Update `.env.example` for Pi API Keys

**Files:**
- Modify: `.env.example`
- Modify: `Justfile` (the `create` recipe, to pass additional env vars)

**Step 1: Add Pi-relevant env vars to `.env.example`**

Pi supports multiple providers. Add optional keys:

```
# Optional: only needed if using API-key billing instead of a Claude subscription.
# Subscription users can skip this and use `just login <name>` instead.
ANTHROPIC_API_KEY=

# Optional: for Pi coding agent with non-Anthropic providers.
# Pi defaults to the anthropic provider. Set keys for whichever provider you use.
# GOOGLE_API_KEY=
# OPENAI_API_KEY=
```

**Step 2: Update `create` recipe to pass Pi env vars**

Modify the `docker create` command in the `create` recipe to also forward `GOOGLE_API_KEY` and `OPENAI_API_KEY` (they'll be empty/unset if not configured, which is fine):

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
git commit -m "feat: support Pi provider API keys in container creation"
```

---

## Task 5: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Update title/description**

Change the opening to mention both tools. Update "Tools Inside the Container" to list Pi.

**Step 2: Add Pi recipes to the table**

Add rows:

```markdown
| `just pi <name> [prompt]` | Run Pi coding agent (auto-starts) |
| `just pi-safe <name> [prompt]` | Run Pi with restricted tools |
```

**Step 3: Add a "Choosing Between Claude and Pi" section**

Brief section explaining when you might pick one vs. the other:
- Claude Code: native Anthropic tool, deep integration with Claude subscription, YOLO mode
- Pi: multi-provider support (Anthropic, Google, OpenAI), extensible with skills/extensions/themes, TUI

**Step 4: Update Quick Start to show both paths**

Add a step 5b: `just pi my-project` as an alternative to step 5.

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add Pi coding agent to README"
```

---

## Task 6: Update `docs/getting-started.md`

**Files:**
- Modify: `docs/getting-started.md`

**Step 1: Add Pi to "Key Concepts" section**

Add a subsection explaining what Pi is:

```markdown
### Pi Coding Agent

**Pi** is an alternative AI coding agent that also runs inside the container. While Claude Code is Anthropic's native CLI, Pi is a more extensible harness that supports multiple AI providers (Anthropic, Google, OpenAI) and can be customized with skills, extensions, and themes. You can use either tool — or both — depending on your needs.
```

**Step 2: Add Pi to "Tools Inside the Container" table**

Add `pi` to the table in the CLAUDE.md reference or the tools list.

**Step 3: Add "Working With Pi" section**

Mirror the "Working With Claude Inside the Container" section with Pi equivalents:

| Command | Mode | When to Use |
|---------|------|-------------|
| `just pi my-project` | Full tools | Day-to-day work with Pi |
| `just pi-safe my-project` | Read-only | When you want Pi to only read, not modify |

**Step 4: Update Recipes Reference table**

Add `pi` and `pi-safe` rows.

**Step 5: Update Glossary**

Add entry for Pi:

```markdown
| **Pi** | An extensible AI coding agent that supports multiple providers (Anthropic, Google, OpenAI) |
```

**Step 6: Commit**

```bash
git add docs/getting-started.md
git commit -m "docs: add Pi coding agent to getting-started guide"
```

---

## Task 7: Update `config/CLAUDE.md`

**Files:**
- Modify: `config/CLAUDE.md`

**Step 1: Clarify Pi entry in tools table**

The current CLAUDE.md already lists `pi` in the tools table. Optionally add a note about how to configure the provider:

```markdown
| pi | Pi Coding Agent (AI coding harness) — run with `pi` or configure provider via env vars |
```

**Step 2: Commit**

```bash
git add config/CLAUDE.md
git commit -m "docs: clarify pi tool entry in container CLAUDE.md"
```

---

## Task 8: End-to-End Smoke Test

**Step 1: Rebuild the image**

Run: `just rebuild`
Expected: Build succeeds, Pi settings file is copied in.

**Step 2: Create a test container**

Run: `just create pi-test`
Expected: Container created, project dir created.

**Step 3: Verify Pi is accessible**

Run: `just shell pi-test` then inside: `pi --version`
Expected: Pi version prints.

**Step 4: Verify Pi recipe works**

Run: `just pi pi-test "echo hello"`
Expected: Pi starts, processes the prompt, exits.

**Step 5: Clean up**

Run: `just destroy pi-test`

**Step 6: Final commit (if any fixups needed)**

```bash
git add -A
git commit -m "chore: fixups from smoke test"
```

---

## Summary of Changes

| File | Change |
|------|--------|
| `Justfile` | Add `pi` and `pi-safe` recipes; forward extra API key env vars in `create` |
| `Dockerfile` | Copy `config/pi-settings.json` into image |
| `config/pi-settings.json` | New file: default Pi provider/model settings |
| `ccr` | Add Pi examples to usage output |
| `.env.example` | Add optional `GOOGLE_API_KEY` / `OPENAI_API_KEY` vars |
| `README.md` | Add Pi recipes, "choosing" section, update quick start |
| `docs/getting-started.md` | Add Pi concepts, working-with-pi section, update tables/glossary |
| `config/CLAUDE.md` | Clarify Pi entry |
