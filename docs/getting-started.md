# Claude Container: A Complete Beginner's Guide

## Table of Contents

- [What Is This and Why Should I Care?](#what-is-this-and-why-should-i-care)
- [Key Concepts (Plain English)](#key-concepts-plain-english)
- [What You Need Before Starting](#what-you-need-before-starting)
- [Installation: Step by Step](#installation-step-by-step)
- [Your First Project](#your-first-project)
- [Working With Claude Inside the Container](#working-with-claude-inside-the-container)
- [Managing Your Containers](#managing-your-containers)
- [Moving Files In and Out](#moving-files-in-and-out)
- [Use Cases for Academic Research](#use-cases-for-academic-research)
- [Recipes Reference](#recipes-reference)
- [Troubleshooting](#troubleshooting)
- [Glossary](#glossary)

---

## What Is This and Why Should I Care?

Claude Code is an AI assistant that can read, write, and run code directly on your computer. It is incredibly powerful — it can install software, create files, run scripts, and modify your system. That power is also what makes it risky. If you ask Claude to "clean up my project" and it misunderstands, it could delete files you care about. If a script goes wrong, it could affect other things on your machine.

**Claude Container solves this problem.** It gives Claude its own isolated computer (a "container") to work in. Claude gets full, unrestricted access inside that container — it can install anything, run anything, break anything — and none of it touches your real computer. Your project files are shared between the container and your computer through a single folder, so you always have access to the work Claude produces.

Think of it like giving Claude its own office with a desk, tools, and a copy machine. Claude can make a mess in that office all day long, and your office stays clean. The copy machine (the shared folder) lets you exchange documents back and forth.

---

## Key Concepts (Plain English)

### The Terminal

The terminal (also called "command line" or "shell") is a text-based way to talk to your computer. Instead of clicking icons, you type commands. On a Mac, you can open it by pressing `Cmd + Space`, typing "Terminal", and pressing Enter.

When you see instructions like this:

```bash
just build
```

That means: open your terminal, type `just build`, and press Enter.

### Docker and Containers

A **container** is like a lightweight virtual computer running inside your real computer. It has its own operating system (Linux), its own installed programs, and its own files. But unlike a full **virtual machine** (a complete simulated computer, which is heavy and slow to start), a container starts in seconds and uses very little memory.

**Docker** is the software that creates and runs these containers. You tell Docker "here's a blueprint" (called a Dockerfile), and it builds a container from that blueprint.

You don't need to learn Docker commands — this project wraps everything in simple `just` commands for you.

### Colima

Docker normally requires "Docker Desktop," which is a large commercial application. **Colima** is a free, lightweight alternative that runs Docker on your Mac. Our setup script installs it for you.

Behind the scenes, Colima creates a small Linux virtual machine (a simulated computer) on your Mac, and Docker runs inside that. You'll never need to interact with Colima directly after the initial setup.

### Justfile and `just`

A **Justfile** is like a recipe book for your terminal. Instead of remembering long, complicated commands, you type short ones like `just build` or `just create my-project`. The Justfile translates these into the real commands behind the scenes.

**`just`** is the program that reads the Justfile and runs the recipes. It's similar to `make` if you've heard of that, but simpler.

### Bind Mounts (The Shared Folder)

When you create a container, a folder is created on your Mac at `projects/<name>/`. This same folder appears inside the container at `/workspace`. Any file you put in either location instantly appears in the other.

This is how your work survives even if the container is destroyed. The container is disposable; the project folder is permanent.

### YOLO Mode

Claude Code normally asks your permission before doing anything significant — "Can I create this file? Can I run this command?" This is safe but slow, especially for complex tasks.

**YOLO mode** (`--dangerously-skip-permissions`) tells Claude to just do it without asking. Inside a container, this is safe because Claude can't affect your real computer. It makes Claude dramatically faster and more autonomous for complex tasks.

### Authentication: Subscription vs API Key

There are two ways to use Claude Code:

1. **Claude subscription** (Pro or Max plan at [claude.ai](https://claude.ai)) — You log in once per container with `just login <name>`. Claude Code usage is included in your subscription. This is the simplest option.

2. **API key** — You get a key from [console.anthropic.com](https://console.anthropic.com/) and put it in a `.env` file. Usage is billed per conversation. The key looks something like `sk-ant-abc123...`.

**You only need one of these.** If you have a Claude Pro or Max subscription, you don't need an API key at all.

---

## What You Need Before Starting

1. **A Mac** with Apple Silicon (M1/M2/M3/M4). Intel Macs may work but require manual Colima configuration — see Troubleshooting.
2. **Homebrew** — a package manager for Mac. If you don't have it, open Terminal and paste:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   Follow the prompts. This may take a few minutes.
3. **just** — install it with Homebrew:
   ```bash
   brew install just
   ```
4. **A Claude subscription or API key** — either a [Claude Pro/Max subscription](https://claude.ai) or an [Anthropic API key](https://console.anthropic.com/) (Settings > API Keys). You only need one.

---

## Installation: Step by Step

### Step 1: Download this project

Open Terminal and run:

```bash
git clone https://github.com/YOUR_USERNAME/claude-container.git
cd claude-container
```

Replace `YOUR_USERNAME` with the actual GitHub username or organization where this repository (repo) is hosted.

> **Note:** If this is your first time using `git` on a Mac, you may see a pop-up asking to install "Xcode Command Line Tools." Click "Install" and wait for it to finish (this can take 5-10 minutes), then run the commands above again.
>
> **Alternative if you don't want to use git:** Download the project as a ZIP file from the GitHub page (look for a green "Code" button, then "Download ZIP"), unzip it, and open Terminal in that folder.

You are now "inside" the project folder. **All `just` commands must be run from this folder.** If you open a new Terminal window later, navigate back here first:

```bash
cd /path/to/claude-container
```

> **Tip: Run commands from anywhere with `ccr`**
>
> The repo includes a small script called `ccr` (Claude Container Runner) that lets you run any recipe from any folder — no need to `cd` back here each time. To set it up:
>
> ```bash
> # Copy the script to a folder on your PATH
> cp ccr ~/bin/ccr       # or /usr/local/bin/ccr
> chmod +x ~/bin/ccr
> ```
>
> If you cloned this repo somewhere other than `~/repos/claude-container`, tell `ccr` where to find it by adding this line to your `~/.zshrc`:
>
> ```bash
> export CLAUDE_CONTAINER_DIR="$HOME/path/to/claude-container"
> ```
>
> Then, anywhere on your system, use `ccr` instead of `just`:
>
> ```bash
> ccr build
> ccr create my-project
> ccr claude my-project
> ccr list
> ccr --recipes          # show all available recipes
> ```
>
> All the examples in this guide use `just`, but you can always substitute `ccr` if you've set it up.

### Step 2: Set up authentication

You have two options depending on how you pay for Claude. **Pick one:**

#### Option A: Claude subscription (Pro/Max) — recommended

No setup needed at this step. You'll log in after creating your first container (Step 5). Skip ahead to Step 3.

#### Option B: API key

```bash
cp .env.example .env
```

The `cp` command means "copy." This creates a new file called `.env` by copying the example template.

> **Note about dotfiles:** Files whose names start with a `.` (like `.env`) are "hidden files" on macOS. You won't see them in Finder by default. In Terminal, use `ls -a` (list all) to see them. In Finder, press `Cmd+Shift+.` to toggle hidden file visibility.

Now open `.env` in a text editor. You can use any editor you like, or use `nano` in the terminal:

```bash
nano .env
```

This opens a simple text editor in your terminal. Use the arrow keys to navigate. Change the `ANTHROPIC_API_KEY=` line to include your key:

```
ANTHROPIC_API_KEY=sk-ant-your-actual-key-here
```

Then press `Ctrl+O` (the letter O) to save, press Enter to confirm, and `Ctrl+X` to exit.

This file is private — it's listed in `.gitignore` (a special file that tells git "never upload these files"), so it will never be accidentally shared even if you publish your project.

### Step 3: Install Colima and Docker

```bash
just setup
```

**What this does:**
1. Installs Colima (the Docker runtime) and the Docker command-line tool via Homebrew
2. Starts a Linux virtual machine with 4 CPU cores, 8 GB of RAM, and 60 GB of disk space
3. Configures it to use Apple's native virtualization (fast and efficient on Apple Silicon)

This step typically takes 3-5 minutes the first time on a fast internet connection. You'll see download progress and Homebrew output scrolling by. When you see a message like `done` or your terminal prompt returns, Docker is ready.

**If you see an error about Colima already running**, that's fine — it means you've done this before.

### Step 4: Build the container image

```bash
just build
```

**What this does:** Docker reads the `Dockerfile` (the blueprint) and builds an image — a snapshot of a Linux system with all the tools pre-installed. This includes:

- Python 3 and uv (a fast Python package manager)
- Node.js 22 (for JavaScript)
- R (for statistical computing)
- DuckDB (a fast analytical database)
- git, just, and build tools
- Claude Code CLI

The first build downloads a lot and takes several minutes. Future builds are much faster because Docker caches each step.

---

## Your First Project

### Create a container

```bash
just create my-first-project
```

**What this does:**
1. Creates a folder on your Mac: `projects/my-first-project/`
2. Creates a Docker container named `claude-my-first-project`
3. Links the folder so the container can read and write to it

The container is created but not yet running (think of it as a powered-off computer).

### Log in (subscription users only)

If you use a Claude Pro or Max subscription, log in once per container:

```bash
just login my-first-project
```

**What this does:** Runs `claude login` inside the container. It will display a URL — open that URL in your browser, sign in with your Claude account, and the container will be authenticated. You only need to do this once per container (it survives stop/start, but not destroy/create).

API key users can skip this step — your key was already configured via `.env`.

### Start Claude

```bash
just claude my-first-project
```

**What this does:**
1. Starts the container (if it isn't already running)
2. Opens Claude Code inside the container in YOLO mode
3. You now have an interactive conversation with Claude, and Claude has full access to the container

You'll see Claude's interface appear. You can type requests like:

- "Create a Python script that analyzes a CSV file"
- "Set up a new R project with tidyverse"
- "Build me a simple web dashboard"

When you're done, press `Ctrl+C` or type `/exit` to leave Claude. The container stays running.

### Verify your files are shared

While Claude is running (or after, using `just shell`), any files Claude creates in `/workspace` will appear on your Mac in `projects/my-first-project/`. Try it:

```bash
ls projects/my-first-project/
```

The `ls` command means "list" — it shows the files in a folder. You'll see whatever Claude created.

### Open a plain shell (no Claude)

```bash
just shell my-first-project
```

This gives you a regular Linux command line inside the container. You can explore, run scripts, install packages, or do anything you'd do on a Linux machine. Type `exit` to leave.

---

## Working With Claude Inside the Container

### YOLO Mode vs Safe Mode

You have two ways to run Claude:

| Command | Mode | When to Use |
|---------|------|-------------|
| `just claude my-project` | YOLO | Day-to-day work. Claude acts autonomously. |
| `just claude-safe my-project` | Safe | When you want to approve each action Claude takes. |

YOLO mode is the default and recommended mode inside containers. Since the container is isolated, there's no risk to your real computer.

### Giving Claude a specific task

You can pass a prompt directly:

```bash
just claude my-project "Read the CSV files in this directory and create summary statistics"
```

Or start an interactive session (no prompt) and type your request:

```bash
just claude my-project
```

### What Claude can do inside the container

Claude has access to everything a regular Linux user would:

- **Read and write files** in `/workspace` (your shared project folder)
- **Run Python, R, Node.js, or shell scripts**
- **Install packages** (`uv pip install pandas`, `npm install express`, `R -e 'install.packages("ggplot2")'`)
- **Use git** to manage version control
- **Query databases** with DuckDB
- **Access the internet** to download data or packages
- **Use `sudo`** (run as administrator) to install system-level software

---

## Managing Your Containers

### Day-to-day workflow

```bash
# Start your work session
just claude my-project

# ... work with Claude ...

# When done for the day, stop the container to free resources
just stop my-project

# Next day, just run claude again — it auto-starts
just claude my-project
```

### See all your containers

```bash
just list
```

This shows every claude container, whether it's running or stopped.

### Stop a container (pause it)

```bash
just stop my-project
```

Everything on disk is preserved — installed packages, configuration files, and any files Claude created. It just stops using CPU and memory. Note: any scripts or processes that were actively running will be terminated and would need to be restarted.

### Start it again

```bash
just start my-project
```

Or just run `just claude my-project` or `just shell my-project` — they auto-start.

### Restart (if something is stuck)

```bash
just restart my-project
```

### Destroy a container (delete the virtual machine, keep your files)

```bash
just destroy my-project
```

This removes the container entirely. Any packages Claude installed, any configuration changes inside the container — gone. **But your project files in `projects/my-project/` are safe.** They live on your Mac, not inside the container.

You can recreate the container anytime:

```bash
just create my-project
just claude my-project
```

Claude will need to reinstall any packages it needs, but your files are all still there.

### Check resource usage

```bash
just stats
```

Shows CPU and memory usage for all running containers. Useful if your Mac feels sluggish.

### View container logs

```bash
just logs my-project
```

Shows the internal log output from the container. Mostly useful for debugging.

---

## Moving Files In and Out

### The easy way: the shared folder

Anything in `projects/my-project/` on your Mac is automatically in `/workspace` inside the container, and vice versa. For most workflows, this is all you need:

- Drop a CSV into `projects/my-project/data/` on your Mac, and Claude can read it at `/workspace/data/`
- Claude creates a report at `/workspace/output/report.pdf`, and you'll find it at `projects/my-project/output/report.pdf`

### Copying files to/from other locations in the container

Sometimes you need to move files to/from places other than `/workspace` (for example, a config file in `/home/coder/`):

```bash
# Copy a file from your Mac into the container
just cp-to my-project ./local-file.txt /home/coder/file.txt

# Copy a file from the container to your Mac
just cp-from my-project /home/coder/.bashrc ./container-bashrc.txt
```

### Advanced: Extra mounts at creation time

> This section uses Docker syntax and is optional. Skip it if you're just getting started.

If you have a large dataset somewhere else on your Mac that you don't want to copy, you can mount it as a second shared folder when creating the container. The `--` tells `just` that everything after it is extra options to pass to Docker:

```bash
just create my-project -- -v /Users/you/datasets:/data:ro
```

Breaking down `-v /Users/you/datasets:/data:ro`:
- `/Users/you/datasets` — the folder on your Mac
- `/data` — where it appears inside the container
- `:ro` — "read-only," so Claude can read but not modify your original data

---

## Use Cases for Academic Research

> **Before each example:** Every use case below assumes you have already created a container for that project with `just create <name>`. See [Your First Project](#your-first-project) above. For example, before the first use case, you would run `just create data-analysis`.

### 1. Data Analysis and Exploration

**Scenario:** You have a collection of CSV files, survey responses, or experimental data and need to understand it.

```bash
# Create the container first (one-time)
just create data-analysis

# Put your data in the project folder.
# "cp -r" means "copy recursively" (the folder and everything in it).
# "~" is shorthand for your home folder (e.g., /Users/yourname).
cp -r ~/Downloads/experiment_data/ projects/data-analysis/

# Ask Claude to explore it
just claude data-analysis "Explore the CSV files in this directory. \
  Summarize the structure, look for missing values, create basic \
  descriptive statistics, and generate visualizations."
```

Claude will write Python or R scripts, run them, and produce charts and summaries — all saved in your project folder.

### 2. Statistical Analysis and Modeling

**Scenario:** You need to run regressions, mixed-effects models, Bayesian analysis, or other statistical methods.

```bash
just claude stats-project "I have a dataset in data.csv with columns: \
  participant_id, condition (A/B/C), reaction_time, accuracy, age, gender. \
  Run a mixed-effects model predicting reaction_time from condition, \
  controlling for age and gender, with random intercepts for participant. \
  Use R with lme4. Create publication-ready tables and plots."
```

Claude installs the necessary R packages, writes the analysis script, runs it, and produces output you can put directly in a paper.

### 3. Literature Review and Text Analysis

**Scenario:** You have a collection of PDFs or text files and want to analyze themes, extract information, or build a structured database.

```bash
just claude lit-review "I have a folder of plain-text abstracts from a \
  systematic review. Categorize each abstract by methodology \
  (qualitative/quantitative/mixed), extract the sample size and \
  key findings, and create a summary spreadsheet."
```

### 4. Writing and Editing Assistance

**Scenario:** You're drafting a paper, grant proposal, or dissertation chapter.

```bash
just claude writing "Read draft.md in this directory. This is a methods \
  section for a psychology paper. Suggest improvements for clarity, \
  check that the statistical reporting follows APA format, and flag \
  any claims that aren't well-supported by the described methodology."
```

### 5. Web Scraping and Data Collection

**Scenario:** You need to collect data from public websites, government databases, or APIs.

```bash
just claude scraping "Write a Python script that downloads all publicly \
  available CSV datasets from data.gov matching the search term \
  'air quality'. Save them in a data/ subdirectory with a manifest \
  file listing each dataset's URL, title, and download date."
```

Claude can install `requests`, `beautifulsoup4`, `selenium`, or whatever is needed — without affecting your Mac.

### 6. Reproducible Research Environments

**Scenario:** You want to ensure your analysis can be reproduced exactly.

```bash
just claude repro-project "Set up a reproducible Python project. \
  Create a pyproject.toml with pinned dependencies, a Makefile that \
  runs the full analysis pipeline from raw data to final figures, \
  and a README explaining how to reproduce the results."
```

Because the container starts from a known image, your collaborators can recreate the exact same environment.

### 7. Teaching and Course Development

**Scenario:** You're preparing coding assignments, tutorials, or lecture materials.

```bash
just claude course-materials "Create a set of 5 progressive Python \
  exercises teaching pandas for data analysis. Each exercise should \
  have a starter file with instructions, a solution file, a sample \
  dataset, and auto-grading tests. Target audience: social science \
  graduate students with no prior Python experience."
```

### 8. Database Work

**Scenario:** You have large datasets that would benefit from SQL queries.

DuckDB is pre-installed and can directly query CSV and Parquet files without importing them:

```bash
just claude db-project "I have several large CSV files (>1GB each) in \
  this directory. Use DuckDB to: (1) explore their schemas, \
  (2) join them on participant_id, (3) run aggregate queries \
  to compute summary statistics by group, (4) export the results \
  as a clean CSV."
```

### 9. Simulation and Computational Experiments

**Scenario:** You need to run Monte Carlo simulations, agent-based models, or other computational experiments.

```bash
just claude simulation "Write a Python simulation of a Schelling \
  segregation model. Run it across a grid of parameters \
  (tolerance = 0.3, 0.5, 0.7; grid sizes = 50, 100, 200). \
  Save results as CSV and generate heatmap visualizations \
  of the final states."
```

If the simulation is CPU-intensive, it runs inside the container without slowing down your other Mac applications (much).

### 10. Multi-Language Projects

**Scenario:** Your workflow spans multiple languages — R for statistics, Python for data cleaning, JavaScript for a visualization dashboard.

The container has all three runtimes pre-installed. Claude can seamlessly switch between them:

```bash
just claude multi-lang "Clean the raw data using Python pandas, \
  run the statistical models in R, and build an interactive \
  HTML dashboard using Observable Plot in JavaScript. \
  Wire them together with a just recipe that runs the full pipeline."
```

### 11. Working on Multiple Projects Simultaneously

Each container is independent. You can have as many as you need:

```bash
just create dissertation-ch3
just create grant-nsf-2026
just create collab-with-jones-lab
just create teaching-stats101

# Work on one
just claude dissertation-ch3

# Switch to another (the first keeps running)
just claude grant-nsf-2026
```

Each project has its own folder, its own container, and its own installed packages. They don't interfere with each other.

### 12. Safe Experimentation

**Scenario:** You want to try a new tool, library, or approach without risking your current setup.

```bash
just create experiment
just shell experiment

# Inside the container, install and try anything
sudo apt-get install -y some-obscure-tool
uv pip install some-experimental-library

# If it all goes wrong
exit
just destroy experiment   # Gone. No trace.
just create experiment    # Fresh start.
```

---

## Recipes Reference

Run any of these from the `claude-container` directory:

| Command | What It Does |
|---------|-------------|
| `just setup` | One-time setup: installs Colima and Docker, starts the VM |
| `just build` | Builds the container image from the Dockerfile |
| `just rebuild` | Rebuilds from scratch (ignoring cache). Use if the image seems broken |
| `just create <name>` | Creates a new container and its project folder |
| `just create <name> -- <args>` | Creates a container with extra Docker options (ports, mounts, etc.) |
| `just login <name>` | Log in with Claude subscription (once per container) |
| `just start <name>` | Starts a stopped container |
| `just stop <name>` | Stops a running container (preserves state) |
| `just restart <name>` | Restarts a container |
| `just shell <name>` | Opens a terminal inside the container |
| `just claude <name>` | Opens Claude in YOLO mode (interactive) |
| `just claude <name> "prompt"` | Runs Claude with a specific task |
| `just claude-safe <name>` | Opens Claude with permission prompts |
| `just claude-safe <name> "prompt"` | Runs safe-mode Claude with a specific task |
| `just cp-to <name> <src> <dest>` | Copies a file from your Mac into the container |
| `just cp-from <name> <src> <dest>` | Copies a file from the container to your Mac |
| `just destroy <name>` | Deletes the container (project files are kept) |
| `just list` | Shows all claude containers and their status |
| `just logs <name>` | Shows the container's log output |
| `just stats` | Shows CPU/memory usage for all running containers |
| `just colima-start` | Starts the Colima VM (if you stopped it) |
| `just colima-stop` | Stops the Colima VM (frees all resources) |
| `just colima-status` | Shows whether the Colima VM is running |

---

## Troubleshooting

### `just` commands don't work / "No justfile found"

Make sure you are in the `claude-container` directory. All `just` commands must be run from inside this folder:

```bash
cd /path/to/claude-container
```

### "command not found: just"

Install just: `brew install just`

### "Cannot connect to the Docker daemon"

Colima isn't running. Start it:

```bash
just colima-start
```

### "just build" is failing or taking forever

Make sure Colima is running (`just colima-status`). If the build fails on a specific step, try `just rebuild` for a clean build. Check your internet connection — the build downloads packages from the internet.

### "Container already exists"

You already created a container with that name. Either use it (`just claude <name>`) or destroy and recreate it:

```bash
just destroy <name>
just create <name>
```

### Claude says it's not authenticated / "ANTHROPIC_API_KEY not set"

**Subscription users:** Run `just login <name>` to authenticate. You need to do this once per container (and again after `just destroy` + `just create`).

**API key users:** Make sure you have a `.env` file (not `.env.example`) with your actual API key:

```bash
cat .env
# Should show: ANTHROPIC_API_KEY=sk-ant-...
```

If you created the container before adding the key, destroy and recreate it:

```bash
just destroy <name>
just create <name>
```

### My Mac is slow with containers running

Stop containers you aren't using:

```bash
just stats        # See what's using resources
just stop <name>  # Stop idle containers
```

Or stop Colima entirely when you're done for the day:

```bash
just colima-stop
```

### `just setup` fails on an Intel Mac

The default setup uses Apple Silicon-specific options (`--vm-type vz --vz-rosetta`). On an Intel Mac, run the setup steps manually:

```bash
brew install colima docker
colima start --cpu 4 --memory 8 --disk 60
```

### I want to start completely fresh

```bash
just destroy <name>    # Remove the container
just create <name>     # Recreate it from the base image
```

Your project files in `projects/<name>/` are untouched. Only the container (installed packages, config changes) is reset.

---

## Advanced: Customizing Claude's Behavior

The project includes two configuration files that control how Claude behaves inside containers. You can edit these and then run `just rebuild` to apply changes to all future containers.

- **`config/CLAUDE.md`** — Instructions that Claude reads when it starts. You can add project-wide conventions, preferred libraries, coding style, or any other guidance. Think of it as a standing set of instructions for your research assistant.

- **`config/claude-settings.json`** — Controls Claude's permission settings. The default grants full access (YOLO mode). You generally don't need to change this.

After editing either file, rebuild the image:

```bash
just rebuild
```

Existing containers are **not** affected — only new containers created after the rebuild will pick up the changes.

---

## Glossary

| Term | Meaning |
|------|---------|
| **API key** | A secret string that authenticates you with Anthropic's servers |
| **Bind mount** | A shared folder between your Mac and a container |
| **Claude Code** | Anthropic's command-line AI coding assistant |
| **Colima** | A free, lightweight Docker runtime for macOS |
| **Container** | An isolated Linux environment running on your Mac |
| **Docker** | The software that creates and manages containers |
| **Dockerfile** | A blueprint that describes how to build a container image |
| **Image** | A snapshot/template used to create containers (like a class vs an instance) |
| **Justfile** | A file containing shortcut recipes for terminal commands |
| **Repository (repo)** | A project folder tracked by git, often hosted on GitHub |
| **`sudo`** | "Superuser do" — runs a command as the administrator. Inside the container, this works without a password |
| **Virtual machine (VM)** | A complete simulated computer running inside your real computer |
| **YOLO mode** | Running Claude without permission prompts (safe inside containers) |
| **`~`** | Shorthand for your home folder in the terminal (e.g., `/Users/yourname` on a Mac) |
| **`/workspace`** | The directory inside the container that maps to your project folder |
| **`projects/`** | The directory on your Mac that holds all project folders |
