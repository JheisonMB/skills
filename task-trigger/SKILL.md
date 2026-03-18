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
    version: "2.0"
    platforms: Linux/WSL/macOS
    compatible_with: opencode, kiro
    category: automation
    last_updated: "2026-03-18"
    includes_scripts: true
    features: ["cron scheduling", "file monitoring", "cross-platform"]
---

# Task Trigger Skill

This skill enables you to register, manage, and execute scheduled tasks using the OS native scheduler. You'll convert natural language into cron expressions, create task definitions, integrate with crontab (Linux/WSL) or launchd (macOS), and handle logs.

## Core Concept

```
user: "every day at 9am summarize my memory MCP entries"
  └→ You execute: /task-trigger:add
       └→ You write crontab entry (Linux) or .plist (macOS)
            └→ At scheduled time: CLI runs headless (opencode run or kiro chat)
                 └→ Output goes to log file
                      └→ User reads log when ready
```

## Commands

| Command | Description |
|---|---|
| `/task-trigger:add` | Register a new task interactively (ALWAYS ask confirmation) |
| `/task-trigger:watch` | Start monitoring a file/directory for changes |
| `/task-trigger:list` | Show all registered tasks |
| `/task-trigger:watchers` | List active file watchers |
| `/task-trigger:remove <id>` | Remove a task + clean scheduler |
| `/task-trigger:unwatch <id>` | Stop monitoring a file/directory |
| `/task-trigger:logs [id]` | View execution history |
| `/task-trigger:run <id>` | Execute task immediately |
| `/task-trigger:status` | Check scheduler health + time remaining |

## Available Scripts

This skill includes pre-built scripts for common operations. Use them to ensure consistency and reduce manual bash code:

| Script | Purpose | Usage |
|---|---|---|
| `detect-platform.sh` | Detect OS platform | `./scripts/detect-platform.sh` → outputs: `wsl`, `macos`, or `linux` |
| `detect-cli.sh` | Detect available CLI | `./scripts/detect-cli.sh` → outputs: `opencode`, `kiro`, or `none` |
| `add-to-crontab.sh` | Add task to crontab | `./scripts/add-to-crontab.sh --task-id <id> --cron <expr> --command <cmd>` |
| `add-to-launchd.sh` | Add task to launchd | `./scripts/add-to-launchd.sh --task-id <id> --hour <H> --minute <M> --command <cmd>` |
| `detect-watcher.sh` | Detect file monitoring tools | `./scripts/detect-watcher.sh` → outputs: `inotifywait`, `fswatch`, `polling`, or `none` |
| `start-watcher.sh` | Start file/directory watcher | `./scripts/start-watcher.sh --task-id <id> --path <path> --events <events> --command <cmd>` |
| `stop-watcher.sh` | Stop file watcher | `./scripts/stop-watcher.sh <task-id>` |
| `list-tasks.py` | List registered tasks | `./scripts/list-tasks.py` |
| `list-watchers.py` | List active file watchers | `./scripts/list-watchers.py` |
| `remove-task.sh` | Remove task completely | `./scripts/remove-task.sh <task-id>` |
| `view-logs.sh` | View task logs | `./scripts/view-logs.sh [task-id] [--tail] [--lines N]` |
| `run-task.sh` | Execute task now | `./scripts/run-task.sh <task-id>` |

**IMPORTANT:** Always use scripts for repetitive operations instead of writing bash code manually.

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

**Duration handling:** When user says "durante la próxima X", calculate expiration time.

### 2. CLI Detection
Use the script instead of manual bash:

```bash
# Instead of writing bash code, use:
CLI=$(./scripts/detect-cli.sh)
echo "Detected CLI: $CLI"
```

### 3. Platform Detection
Use the script instead of manual bash:

```bash
# Instead of writing bash code, use:
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
   - CLI: detect opencode/kiro
```

### Step 2: Generate Task ID
Create unique ID: `daily-memory-summary`, `log-analysis-30min`, etc.
Rules: lowercase, hyphens, based on description.

### Step 3: Create Task JSON
Create `$HOME/.task-trigger/tasks.json` (create directory if doesn't exist):

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

#### For WSL/Linux (crontab):
Use the script instead of manual bash:

```bash
# Detect CLI first
CLI=$(./scripts/detect-cli.sh)

# Build command based on CLI
if [[ "$CLI" == "opencode" ]]; then
  COMMAND="opencode run --prompt 'Check MCP memory for new entries since yesterday and summarize them. Write output to \$HOME/.task-trigger/logs/daily-memory-summary.log'"
elif [[ "$CLI" == "kiro" ]]; then
  COMMAND="kiro-cli chat --no-interactive 'Check MCP memory for new entries since yesterday and summarize them. Write output to \$HOME/.task-trigger/logs/daily-memory-summary.log'"
fi

# Use the script
./scripts/add-to-crontab.sh \
  --task-id "daily-memory-summary" \
  --cron "0 9 * * *" \
  --command "$COMMAND"
```

#### For macOS (launchd):
Use the script instead of manual XML creation:

```bash
# Detect CLI first
CLI=$(./scripts/detect-cli.sh)

# Build command based on CLI
if [[ "$CLI" == "opencode" ]]; then
  COMMAND="opencode run --prompt 'Check MCP memory for new entries since yesterday and summarize them. Write output to \$HOME/.task-trigger/logs/daily-memory-summary.log'"
elif [[ "$CLI" == "kiro" ]]; then
  COMMAND="kiro-cli chat --no-interactive 'Check MCP memory for new entries since yesterday and summarize them. Write output to \$HOME/.task-trigger/logs/daily-memory-summary.log'"
fi

# Use the script
./scripts/add-to-launchd.sh \
  --task-id "daily-memory-summary" \
  --hour 9 \
  --minute 0 \
  --command "$COMMAND"
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
- CLI: `opencode` (or `kiro` if detected and opencode not available)
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
# Detect CLI first
CLI=$(./scripts/detect-cli.sh)

# Build command based on CLI
if [[ "$CLI" == "opencode" ]]; then
  COMMAND="opencode run --prompt 'New log entry detected. Analyze the latest lines and notify if errors found. Write output to \$HOME/.task-trigger/logs/log-analyzer.log'"
elif [[ "$CLI" == "kiro" ]]; then
  COMMAND="kiro-cli chat --no-interactive 'New log entry detected. Analyze the latest lines and notify if errors found. Write output to \$HOME/.task-trigger/logs/log-analyzer.log'"
fi

# Detect available watcher tool
WATCHER_TOOL=$(./scripts/detect-watcher.sh)

# Start the watcher
./scripts/start-watcher.sh \
  --task-id "log-file-watcher" \
  --path "/var/log/app.log" \
  --events "modify" \
  --command "$COMMAND" \
  --recursive false \
  --poll-interval 5 \
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

**Implementation:** Add cleanup mechanism or note in confirmation.

### Model Specification
```
User: "using opencode/zen" or "con claude-3.5-sonnet"
→ Add to command: --model "opencode/zen"
→ If not specified: omit --model flag (uses last model)
```

### Working Directory
Always use `$HOME` (not `~`) in scheduled commands.

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

### Listing Watchers (`/task-trigger:watchers`)
List active file watchers:
```bash
./scripts/list-watchers.py
```

### Removing Tasks (`/task-trigger:remove <id>`)
Use the script instead of manual removal:
```bash
./scripts/remove-task.sh <task-id>
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

### Checking Status (`/task-trigger:status`)
- Verify scheduler is running
- Show temporal tasks with time remaining
- Check log directory health

## CLI Commands Reference

### opencode
- **Headless command**: `opencode run --prompt "message"`
- **Model flag**: `-m "provider/model"`
- **Example**: `opencode run --prompt "Check memory" -m "deepseek/deepseek-chat"`

### kiro
- **Binary name**: `kiro-cli` (not `kiro`)
- **Headless command**: `kiro-cli chat --no-interactive "message"`
- **Model flag**: `--model "provider/model"`
- **Example**: `kiro-cli chat --no-interactive "Check memory" --model "anthropic/claude-sonnet-4"`

## Important Rules

### ALWAYS:
1. **Ask confirmation** before modifying crontab/launchd
2. **Use scripts for detection** instead of manual bash code
3. **Parse natural language** into cron expressions (agent's strength)
4. **Handle temporal tasks** with duration/expiration
5. **Create necessary directories** (`$HOME/.task-trigger/`, `logs/`, `launchd/`, `watchers/`)
6. **Use structured logs** with timestamps
7. **Include model flag** ONLY if user explicitly mentions model
8. **Use $HOME, not ~** in scheduled commands and paths
9. **Verify CLI commands** with `--help` when uncertain
10. **Prefer scripts over manual operations** for consistency
11. **Detect available watcher tool** before starting file monitoring
12. **Set appropriate debounce** for file watchers (1-5 seconds)

### NEVER:
1. Use `--dangerously-skip-permissions`
2. Perform git operations
3. Depend on MCP sampling
4. Modify files without explicit instruction
5. Assume Windows Task Scheduler

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

Remember: You are the agent implementing this. Follow these instructions precisely, parse natural language, detect environment, and always confirm before making changes.