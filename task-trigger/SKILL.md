---
name: task-trigger
description: >
  Enables agents to register, manage, and execute scheduled tasks using OS native scheduler (crontab for Linux/WSL, launchd for macOS). No git, no dangerous flags, no session dependency. Tasks run headless, output to log files, user reads when ready.
  
  Use this skill when:
  - User wants to schedule recurring tasks with natural language
  - User mentions "every day at", "cada hora", "schedule", "programar", "automatizar"
  - User needs tasks to run without open session (headless)
  - User wants OS-level scheduling (crontab/launchd)
  - User mentions "cada minuto durante la próxima hora" or temporal intervals
  
  ACTIVATE when user mentions:
  "schedule", "programar", "cron", "cada día", "every hour", "automate", 
  "tarea programada", "ejecutar automáticamente", "recordatorio",
  "cada minuto durante", "durante la próxima", "intervalo",
  "task scheduler", "opencode headless", "kiro scheduled",
  "background task", "tarea en segundo plano"
  
  DO NOT USE for: git operations, dangerous permissions, MCP sampling dependency.

license: MIT
metadata:
    author: jheison.martinez
    version: "2.1"
    platforms: Linux/WSL/macOS
    compatible_with: opencode, kiro
    category: automation
    last_updated: "2026-03-18"
    includes_scripts: true
    features: ["cron scheduling", "file monitoring", "cross-platform", "auto-cleanup", "interval scheduling", "update-in-place", "pause/resume", "scheduler verification"]
---

# Task Trigger Skill

This skill enables you to register, manage, and execute scheduled tasks using the OS native scheduler. You'll convert natural language into cron expressions, create task definitions, integrate with crontab (Linux/WSL) or launchd (macOS), and handle logs.

## Core Concept

```
user: "every day at 9am summarize my memory MCP entries"
  └→ You execute: /task-trigger:add
       └→ You write crontab entry (Linux) or .plist (macOS)
            └→ Scheduler calls task-wrapper.sh (NOT the CLI directly)
                 └→ Wrapper checks expiration, then runs the CLI headless
                      └→ Output goes to log file
                           └→ User reads log when ready
```

## Commands

| Command | Description |
|---|---|
| `/task-trigger:add` | Register a new task interactively (ALWAYS ask confirmation) |
| `/task-trigger:watch` | Start monitoring a file/directory for changes |
| `/task-trigger:list` | Show all registered tasks (cross-references with scheduler) |
| `/task-trigger:watchers` | List active file watchers |
| `/task-trigger:remove <id>` | Remove a task + clean scheduler |
| `/task-trigger:unwatch <id>` | Stop monitoring a file/directory |
| `/task-trigger:logs [id]` | View execution history |
| `/task-trigger:run <id>` | Execute task immediately |
| `/task-trigger:status` | Check scheduler health + time remaining |
| `/task-trigger:update <id>` | Update individual fields (prompt, schedule, model, etc.) |
| `/task-trigger:reload <id>` | Reload task config into scheduler after manual JSON edits |
| `/task-trigger:pause <id>` | Temporarily disable task without removing |
| `/task-trigger:resume <id>` | Re-enable a paused task |
| `/task-trigger:verify <id>` | Confirm task is actually active in OS scheduler |

## Available Scripts

This skill includes pre-built scripts for common operations. Use them to ensure consistency and reduce manual bash code:

| Script | Purpose | Usage |
|---|---|---|
| `detect-platform.sh` | Detect OS platform | `./scripts/detect-platform.sh` → outputs: `wsl`, `macos`, or `linux` |
| `detect-cli.sh` | Detect available CLI | `./scripts/detect-cli.sh` → outputs: full path (e.g. `/usr/local/bin/opencode`) or `none` |
| `add-to-crontab.sh` | Add task to crontab | `./scripts/add-to-crontab.sh --task-id <id> --cron <expr> --command <cmd> [--dry-run] [--force]` |
| `add-to-launchd.sh` | Add task to launchd | `./scripts/add-to-launchd.sh --task-id <id> (--hour <H> --minute <M> \| --interval <secs>) --command <cmd> [--working-dir <path>] [--dry-run] [--force]` |
| `task-wrapper.sh` | Wrapper for scheduler | `./scripts/task-wrapper.sh <task-id>` — launchd/crontab call THIS, not the CLI |
| `detect-watcher.sh` | Detect file monitoring tools | `./scripts/detect-watcher.sh` → outputs: `inotifywait`, `fswatch`, `polling`, or `none` |
| `start-watcher.sh` | Start file/directory watcher | `./scripts/start-watcher.sh --task-id <id> --path <path> --events <events> --command <cmd> [--dry-run]` |
| `stop-watcher.sh` | Stop file watcher | `./scripts/stop-watcher.sh <task-id>` |
| `list-tasks.py` | List registered tasks | `./scripts/list-tasks.py` |
| `list-watchers.py` | List active file watchers | `./scripts/list-watchers.py` |
| `remove-task.sh` | Remove task completely | `./scripts/remove-task.sh <task-id> [--force]` |
| `view-logs.sh` | View task logs | `./scripts/view-logs.sh [task-id] [--tail] [--lines N]` |
| `run-task.sh` | Execute task now | `./scripts/run-task.sh <task-id>` |
| `update-task.sh` | Update task fields | `./scripts/update-task.sh <task-id> [--prompt "..."] [--schedule "..."] [--model "..."] [--name "..."] [--timeout N] [--working-dir /path] [--force]` |
| `reload-task.sh` | Reload task in scheduler | `./scripts/reload-task.sh <task-id> [--force]` |
| `pause-resume-task.sh` | Pause/resume task | `./scripts/pause-resume-task.sh <task-id> --pause\|--resume [--force]` |
| `verify-task.sh` | Verify task in scheduler | `./scripts/verify-task.sh <task-id>` |

**IMPORTANT:**
- Always use scripts for repetitive operations instead of writing bash code manually.
- Run `chmod +x scripts/*.sh` after first install to ensure all scripts are executable.
- **The plist/crontab MUST call `task-wrapper.sh`, never the CLI directly.**

## How to Use This Skill

### 1. Natural Language Parsing
You MUST parse natural language into cron expressions. This is best done by you (the agent) because you understand context and nuances.

**Examples:**
- "every day at 9am" → `0 9 * * *`
- "every hour" → `0 * * * *`
- "every minute during the next 30 minutes" → `*/1 * * * *` + `duration_minutes: 30`
- "every Monday at 8:30am" → `30 8 * * 1`
- "cada día a las 10am" → `0 10 * * *`
- "cada minuto durante la próxima hora" → `*/1 * * * *` + `duration_minutes: 60`
- "every 5 minutes" → use `--interval 300` (StartInterval)

**Duration handling:** When user says "durante la próxima X", calculate expiration time.

**Interval vs Calendar:**
- "every day at 9am" → calendar schedule (--hour/--minute)
- "every 5 minutes" / "cada minuto" → interval schedule (--interval N seconds)

### 2. CLI Detection
`detect-cli.sh` returns the **full path** to the CLI binary (e.g. `/usr/local/bin/opencode` or `/Users/you/.local/bin/kiro-cli`). Store this full path in the task JSON — launchd and crontab don't inherit the user's PATH.

```bash
CLI_PATH=$(./scripts/detect-cli.sh)
echo "Detected CLI: $CLI_PATH"
# Use $CLI_PATH in commands, not just "opencode" or "kiro-cli"
```

### 3. Platform Detection
Use the script instead of manual bash:

```bash
PLATFORM=$(./scripts/detect-platform.sh)
echo "Detected platform: $PLATFORM"
```

## Task Creation Workflow

### Step 1: Parse User Request
```
User: "every day at 9am summarize my memory MCP entries using deepseek"
→ You extract:
   - Trigger: "every day at 9am" → cron: `0 9 * * *`
   - Prompt: "summarize my memory MCP entries"
   - Model: "deepseek" (if mentioned, else null)
   - CLI: detect with full path
```

### Step 2: Generate Task ID
Create unique ID: `daily-memory-summary`, `log-analysis-30min`, etc.
Rules: lowercase, hyphens, based on description.

### Step 3: Create Task JSON
Create `$HOME/.task-trigger/tasks.json` (create directory if doesn't exist).

The file is a plain JSON array: `[{task1}, {task2}, ...]`

#### For cron-based tasks:
```json
{
  "id": "daily-memory-summary",
  "name": "Daily Memory Summary",
  "enabled": true,
  "trigger": {
    "type": "cron",
    "expression": "0 9 * * *",
    "timezone": "local",
    "duration_minutes": null,
    "expires_at": null
  },
  "execution": {
    "cli_path": "/usr/local/bin/opencode",
    "agent": "opencode",
    "model": "deepseek/deepseek-chat",
    "prompt": "Check MCP memory for new entries since yesterday and summarize them. Write output to $HOME/.task-trigger/logs/daily-memory-summary.log",
    "workingDirectory": "$HOME",
    "timeout": 300
  },
  "created_at": "2026-03-18T10:00:00Z",
  "log_path": "$HOME/.task-trigger/logs/daily-memory-summary.log"
}
```

#### For file watcher tasks:
```json
{
  "id": "log-file-watcher",
  "name": "Log File Watcher",
  "enabled": true,
  "trigger": {
    "type": "file",
    "path": "/var/log/myapp.log",
    "watch_events": ["create", "modify"],
    "recursive": false,
    "poll_interval": 5,
    "debounce": 1
  },
  "execution": {
    "agent": "opencode",
    "model": "deepseek/deepseek-chat",
    "prompt": "New log entry detected. Analyze the latest lines and notify if errors found. Write output to $HOME/.task-trigger/logs/log-analyzer.log",
    "workingDirectory": "$HOME",
    "timeout": 60
  },
  "created_at": "2026-03-18T10:00:00Z",
  "log_path": "$HOME/.task-trigger/logs/log-analyzer.log"
}
```

### Step 4: Platform-Specific Integration

**CRITICAL: The plist/crontab command MUST call `task-wrapper.sh`, not the CLI directly.** The wrapper handles expiration checks and auto-cleanup.

#### For WSL/Linux (crontab):
```bash
SCRIPT_DIR="$(pwd)/scripts"

# The crontab entry calls the wrapper
COMMAND="$SCRIPT_DIR/task-wrapper.sh daily-memory-summary"

./scripts/add-to-crontab.sh \
  --task-id "daily-memory-summary" \
  --cron "0 9 * * *" \
  --command "$COMMAND" \
  --dry-run
```

#### For macOS (launchd) — Calendar schedule:
```bash
SCRIPT_DIR="$(pwd)/scripts"
COMMAND="$SCRIPT_DIR/task-wrapper.sh daily-memory-summary"

./scripts/add-to-launchd.sh \
  --task-id "daily-memory-summary" \
  --hour 9 \
  --minute 0 \
  --command "$COMMAND" \
  --working-dir "$HOME"
```

#### For macOS (launchd) — Interval schedule (every N seconds):
```bash
SCRIPT_DIR="$(pwd)/scripts"
COMMAND="$SCRIPT_DIR/task-wrapper.sh system-check-5min"

# Every 5 minutes = 300 seconds
./scripts/add-to-launchd.sh \
  --task-id "system-check-5min" \
  --interval 300 \
  --command "$COMMAND" \
  --working-dir "/path/to/project"
```

### Step 5: Create Log Directory
```bash
mkdir -p $HOME/.task-trigger/logs
mkdir -p $HOME/.task-trigger/launchd  # macOS only
mkdir -p $HOME/.task-trigger/watchers  # For file watchers
```

### Step 6: Confirm to User
Show summary:
- Task ID: `daily-memory-summary`
- Schedule: `0 9 * * *` (every day at 9am)
- CLI: `/usr/local/bin/opencode` (full path)
- Model: `deepseek/deepseek-chat` (or "last used model" if not specified)
- Logs: `$HOME/.task-trigger/logs/daily-memory-summary.log`
- Platform: WSL/macOS/Linux
- Status: Enabled

## File Watcher Workflow

### Step 1: Parse User Request
```
User: "watch my log file at /var/log/app.log and analyze new entries"
→ You extract:
   - Path: "/var/log/app.log"
   - Events: ["modify"] (default for files)
   - Prompt: "analyze new log entries"
   - CLI: detect opencode/kiro
```

### Step 2: Generate Task ID
Create unique ID: `log-file-watcher`, `config-monitor`, etc.

### Step 3: Create Task JSON (File Trigger)
Use the file trigger format shown in Step 3.

### Step 4: Start Watcher
```bash
CLI_PATH=$(./scripts/detect-cli.sh)

if [[ "$CLI_PATH" == *opencode* ]]; then
  COMMAND="$CLI_PATH run --prompt 'New log entry detected. Analyze the latest lines and notify if errors found.'"
else
  COMMAND="$CLI_PATH chat --no-interactive --trust-all-tools 'New log entry detected. Analyze the latest lines and notify if errors found.'"
fi

./scripts/start-watcher.sh \
  --task-id "log-file-watcher" \
  --path "/var/log/app.log" \
  --events "modify" \
  --command "$COMMAND" \
  --debounce 1
```

### Step 5: Confirm to User
Show summary:
- Task ID: `log-file-watcher`
- Path: `/var/log/app.log`
- Events: `modify`
- Tool: `inotifywait` (or detected tool)
- CLI: `opencode` / `kiro`
- Status: Watching

## Special Cases

### Temporal Tasks ("during next X")
```
User: "check logs every minute during the next 30 minutes"
→ cron: `*/1 * * * *`
→ duration_minutes: 30
→ expires_at: current_time + 30 minutes
```

**Implementation:** When creating temporal tasks:
1. Calculate `expires_at` = current_time + duration_minutes
2. Store both `duration_minutes` and `expires_at` in task JSON
3. `task-wrapper.sh` checks `expires_at` before executing — if expired, it disables the task, calls `remove-task.sh --force` to unload from scheduler, and exits
4. `/task-trigger:status` shows time remaining for temporal tasks

### Model Specification
```
User: "using opencode/zen" or "con claude-3.5-sonnet"
→ Add to command: --model "opencode/zen"
→ If not specified: omit --model flag (uses last model)
```

### Prompt Templates
Prompts support variable substitution for reusable tasks:
- `{{TIMESTAMP}}` → current ISO 8601 timestamp
- `{{FILE_PATH}}` → the watched file path (file watchers only)
- `{{TASK_ID}}` → the task's ID
- `{{LOG_PATH}}` → the task's log file path

**Example:**
```
"prompt": "Analyze {{FILE_PATH}} for errors since {{TIMESTAMP}}. Write results to {{LOG_PATH}}"
```
The agent expands these variables at execution time in `run-task.sh`.

### Working Directory
Always use `$HOME` (not `~`) in scheduled commands. Use `--working-dir` flag in `add-to-launchd.sh` when the task needs a specific directory.

### File Watcher Events
Available events: `create`, `modify`, `delete`, `move`
- **Files**: Use `modify` for content changes
- **Directories**: Use `create`, `delete`, `move` for structure changes
- **Default**: `modify` for files, `create,modify,delete` for directories

## Task Management

### Listing Tasks (`/task-trigger:list`)
Use the script instead of manual JSON parsing:
```bash
./scripts/list-tasks.py
```
Note: Expired tasks are automatically shown as "Expired" and marked disabled.

### Listing Watchers (`/task-trigger:watchers`)
List active file watchers:
```bash
./scripts/list-watchers.py
```

### Removing Tasks (`/task-trigger:remove <id>`)
Use the script instead of manual removal:
```bash
# Interactive (asks confirmation)
./scripts/remove-task.sh <task-id>

# Non-interactive (for headless/automated use)
./scripts/remove-task.sh <task-id> --force
```

### Stopping Watchers (`/task-trigger:unwatch <id>`)
Stop a file watcher:
```bash
./scripts/stop-watcher.sh <task-id>
```

### Viewing Logs (`/task-trigger:logs [id]`)
Use the script instead of manual log viewing:
```bash
# List all available logs
./scripts/view-logs.sh

# View specific log (last 50 lines)
./scripts/view-logs.sh <task-id>

# Tail log in real-time
./scripts/view-logs.sh <task-id> --tail

# View more lines
./scripts/view-logs.sh <task-id> --lines 100
```

### Running Immediately (`/task-trigger:run <id>`)
Use the script instead of manual execution:
```bash
./scripts/run-task.sh <task-id>
```

### Updating Tasks (`/task-trigger:update <id>`)
Update individual fields without removing and recreating:
```bash
# Update prompt only
./scripts/update-task.sh <task-id> --prompt "new prompt text"

# Update schedule (auto-reloads in scheduler)
./scripts/update-task.sh <task-id> --schedule "30 8 * * *"

# Update multiple fields at once
./scripts/update-task.sh <task-id> --prompt "new prompt" --model "deepseek/deepseek-chat" --timeout 600

# Non-interactive (for automated use)
./scripts/update-task.sh <task-id> --schedule "0 10 * * *" --force
```
Available fields: `--prompt`, `--schedule`, `--model`, `--name`, `--timeout`, `--working-dir`
If `--schedule` changes, the script automatically calls `reload-task.sh`.

### Reloading Tasks (`/task-trigger:reload <id>`)
After editing tasks.json manually, reload the config into the scheduler:
```bash
# Interactive
./scripts/reload-task.sh <task-id>

# Non-interactive
./scripts/reload-task.sh <task-id> --force
```

### Pausing/Resuming Tasks (`/task-trigger:pause <id>` / `/task-trigger:resume <id>`)
Temporarily disable a task without removing it:
```bash
# Pause — unloads from scheduler, marks disabled in JSON
./scripts/pause-resume-task.sh <task-id> --pause

# Resume — reloads in scheduler, marks enabled in JSON
./scripts/pause-resume-task.sh <task-id> --resume
```

### Verifying Tasks (`/task-trigger:verify <id>`)
Confirm a task is actually registered and active in the OS scheduler:
```bash
./scripts/verify-task.sh <task-id>
# ✓ Task 'daily-backup' is active in launchd
# ✗ Task 'daily-backup' NOT found in crontab
# ⚠ Task 'daily-backup' has plist but is NOT loaded in launchd
```

### Checking Status (`/task-trigger:status`)
- Verify scheduler is running (crontab entries / launchctl list)
- Show temporal tasks with time remaining until `expires_at`
- Show last execution timestamp and result from log
- Show next scheduled execution time
- Check log directory health

## CLI Commands Reference

### opencode
- **Headless command**: `opencode run --prompt "message"`
- **Model flag**: `-m "provider/model"`
- **Example**: `opencode run --prompt "Check memory" -m "deepseek/deepseek-chat"`

### kiro
- **Binary name**: `kiro-cli` (not `kiro`)
- **Headless command**: `kiro-cli chat --no-interactive "message"`
- **Trust flag**: `--trust-all-tools` (required for file writes and tool access)
- **Model flag**: `--model "provider/model"`
- **Example**: `kiro-cli chat --no-interactive --trust-all-tools "Check memory" --model "anthropic/claude-sonnet-4"`

**Important**: Always use `--trust-all-tools` with kiro headless commands, otherwise the agent cannot write files or use tools.

## Important Rules

### ALWAYS:
1. **Ask confirmation** before modifying crontab/launchd
2. **Use scripts for detection** instead of manual bash code
3. **Parse natural language** into cron expressions (agent's strength)
4. **Handle temporal tasks** with duration/expiration and auto-cleanup
5. **Create necessary directories** (`$HOME/.task-trigger/`, `logs/`, `launchd/`, `watchers/`)
6. **Use structured logs** with timestamps
7. **Include model flag** ONLY if user explicitly mentions model
8. **Use $HOME, not ~** in scheduled commands and paths
9. **Verify CLI commands** with `--help` when uncertain
10. **Prefer scripts over manual operations** for consistency
11. **Detect available watcher tool** before starting file monitoring
12. **Set appropriate debounce** for file watchers (1-5 seconds)
13. **Store full CLI path** in task JSON (from `detect-cli.sh`)
14. **Use --trust-all-tools** with kiro headless commands
15. **Use --dry-run** to preview changes before applying
16. **Ensure scripts are executable** (`chmod +x`) before first use
17. **Use task-wrapper.sh** as the command in plist/crontab, never the CLI directly
18. **Use --interval** for "every N minutes/seconds" schedules on macOS
19. **Use --working-dir** when the task needs a specific directory
20. **Use --force** with remove-task.sh when calling from scripts/automated contexts

### NEVER:
1. Use `--dangerously-skip-permissions`
2. Perform git operations
3. Depend on MCP sampling
4. Modify files without explicit instruction
5. Assume Windows Task Scheduler
6. Use `sleep &` or background processes for auto-cleanup — the wrapper handles expiration
7. Call the CLI directly from plist/crontab — always go through `task-wrapper.sh`
8. Use `which` for CLI detection — use `command -v` (POSIX)
9. Hardcode PATH from the current shell into plist — use the clean PATH from the script

## What the Agent Must NOT Do

- **DO NOT** use `sleep N && remove-task.sh &` or any background process for cleanup. The `task-wrapper.sh` handles expiration automatically on the next scheduled run.
- **DO NOT** put the CLI command directly in the plist/crontab. Always use `task-wrapper.sh <task-id>` as the command.
- **DO NOT** use interactive `read -r` prompts in automated/headless contexts. Use `--force` flag.
- **DO NOT** capture `$PATH` from the current shell for launchd. The script uses a clean, minimal PATH.

## Troubleshooting

### Common Issues:
1. **Crontab not available**: User may need to install cron service
2. **Launchd permissions**: macOS may require full disk access
3. **opencode/kiro not in PATH**: Suggest adding to PATH or using full path
4. **$HOME expansion**: Some shells may not expand $HOME in crontab

### Error Handling:
- If platform detection fails, ask user
- If CLI not found, suggest installation
- If cron expression invalid, show examples
- If write permission denied, suggest `sudo` (with warning)

## Examples for Testing

Test these cases:
1. `every day at 9am summarize memory`
2. `cada hora analiza logs usando deepseek`  
3. `every minute during the next 30 minutes check emails`
4. `cada minuto durante la próxima hora revisa sistema`
5. `Monday and Wednesday at 8:30am backup files`
6. `watch my log file at /var/log/app.log and alert on errors`
7. `monitor the downloads folder for new PDF files`
8. `if config.json changes, restart the service`
9. `when new files appear in /data/uploads, process them`
10. `track changes to source code and run tests`
11. `every 5 minutes check system health` (uses --interval 300)

Remember: You are the agent implementing this. Follow these instructions precisely, parse natural language, detect environment, and always confirm before making changes.
