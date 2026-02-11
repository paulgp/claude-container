set dotenv-load

image := "claude-container"
prefix := "claude-"

# ── Colima / Docker setup ────────────────────────────────────────

# Install Colima + Docker CLI and start the VM
setup:
    brew install colima docker docker-buildx
    colima start --cpu 4 --memory 8 --disk 60 --vm-type vz --vz-rosetta

# Start Colima VM
colima-start:
    colima start

# Stop Colima VM
colima-stop:
    colima stop

# Show Colima status
colima-status:
    colima status

# ── Image ─────────────────────────────────────────────────────────

# Build the container image
build:
    docker build -t {{image}} .

# Rebuild without cache
rebuild:
    docker build --no-cache -t {{image}} .

# ── Container lifecycle ───────────────────────────────────────────

# Create a new container with bind-mounted project dir
create name *DOCKER_ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    if docker inspect {{prefix}}{{name}} &>/dev/null; then
        echo "Container {{prefix}}{{name}} already exists. Use 'just destroy {{name}}' first."
        exit 1
    fi
    mkdir -p "$(pwd)/projects/{{name}}"
    docker create \
        --name {{prefix}}{{name}} \
        --hostname {{name}} \
        -e ANTHROPIC_API_KEY \
        -v "$(pwd)/projects/{{name}}:/workspace" \
        {{DOCKER_ARGS}} \
        {{image}} \
        sleep infinity
    echo "Container {{prefix}}{{name}} created. Project dir: projects/{{name}}/"

# Start a stopped container
start name:
    docker start {{prefix}}{{name}}

# Stop a running container
stop name:
    docker stop {{prefix}}{{name}}

# Restart a container
restart name:
    docker restart {{prefix}}{{name}}

# Open a shell (auto-starts if stopped)
shell name:
    #!/usr/bin/env bash
    set -euo pipefail
    state=$(docker inspect -f '{{{{.State.Status}}}}' {{prefix}}{{name}} 2>/dev/null || true)
    if [ "$state" != "running" ]; then
        docker start {{prefix}}{{name}} > /dev/null
    fi
    docker exec -it {{prefix}}{{name}} bash

# Log in to Claude with your subscription (opens a URL to authenticate)
login name:
    #!/usr/bin/env bash
    set -euo pipefail
    state=$(docker inspect -f '{{{{.State.Status}}}}' {{prefix}}{{name}} 2>/dev/null || true)
    if [ "$state" != "running" ]; then
        docker start {{prefix}}{{name}} > /dev/null
    fi
    docker exec -it {{prefix}}{{name}} claude login

# Run Claude in YOLO mode (auto-starts, optional prompt)
claude name *PROMPT:
    #!/usr/bin/env bash
    set -euo pipefail
    state=$(docker inspect -f '{{{{.State.Status}}}}' {{prefix}}{{name}} 2>/dev/null || true)
    if [ "$state" != "running" ]; then
        docker start {{prefix}}{{name}} > /dev/null
    fi
    if [ -n "{{PROMPT}}" ]; then
        docker exec -it {{prefix}}{{name}} claude --dangerously-skip-permissions -p "{{PROMPT}}"
    else
        docker exec -it {{prefix}}{{name}} claude --dangerously-skip-permissions
    fi

# Run Claude in normal (permission-prompting) mode
claude-safe name *PROMPT:
    #!/usr/bin/env bash
    set -euo pipefail
    state=$(docker inspect -f '{{{{.State.Status}}}}' {{prefix}}{{name}} 2>/dev/null || true)
    if [ "$state" != "running" ]; then
        docker start {{prefix}}{{name}} > /dev/null
    fi
    if [ -n "{{PROMPT}}" ]; then
        docker exec -it {{prefix}}{{name}} claude -p "{{PROMPT}}"
    else
        docker exec -it {{prefix}}{{name}} claude
    fi

# Copy files from host to container
cp-to name src dest:
    docker cp {{src}} {{prefix}}{{name}}:{{dest}}

# Copy files from container to host
cp-from name src dest:
    docker cp {{prefix}}{{name}}:{{src}} {{dest}}

# Stop and remove a container (project files preserved on host)
destroy name:
    -docker stop {{prefix}}{{name}} 2>/dev/null
    docker rm {{prefix}}{{name}}
    @echo "Container removed. Project files preserved in projects/{{name}}/"

# ── Info / diagnostics ────────────────────────────────────────────

# List all claude containers
list:
    #!/usr/bin/env bash
    docker ps -a --filter "name=^{{prefix}}" --format "table {{'{{'}}.Names{{'}}'}}\t{{'{{'}}.Status{{'}}'}}\t{{'{{'}}.Image{{'}}'}}"

# Show container logs
logs name:
    docker logs {{prefix}}{{name}}

# Show resource usage for all claude containers
stats:
    docker stats --no-stream --filter "name=^{{prefix}}"
