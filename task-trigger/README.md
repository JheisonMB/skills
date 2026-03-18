# Task Trigger Skill v2.1

A skill that enables agents to register, manage, and execute scheduled tasks using OS native scheduler.

## Key Features

- **Natural language scheduling**: Convert "every day at 9am" to cron expressions
- **Cross-platform**: Works on WSL/Linux (crontab) and macOS (launchd)
- **Headless execution**: Tasks run without open session
- **Temporal tasks**: Support for "every minute during the next hour"
- **File watchers**: Monitor files/directories for changes (inotifywait/fswatch/polling)
- **Update in-place**: Modify task fields without remove+add
- **Pause/Resume**: Temporarily disable tasks without removing
- **Scheduler verification**: Confirm tasks are actually active in OS scheduler
- **CLI detection**: Automatically detects opencode or kiro
- **Confirmation required**: Always asks before modifying scheduler

## Usage

### Commands
- `/task-trigger:add` - Register new task (ALWAYS asks confirmation)
- `/task-trigger:watch` - Start monitoring a file/directory for changes
- `/task-trigger:list` - Show all registered tasks (cross-references with scheduler)
- `/task-trigger:watchers` - List active file watchers
- `/task-trigger:remove <id>` - Remove task + clean scheduler
- `/task-trigger:unwatch <id>` - Stop monitoring a file/directory
- `/task-trigger:logs [id]` - View structured execution history
- `/task-trigger:run <id>` - Execute task immediately
- `/task-trigger:status` - Check scheduler health
- `/task-trigger:update <id>` - Update individual fields (prompt, schedule, model, etc.)
- `/task-trigger:reload <id>` - Reload task config into scheduler after manual edits
- `/task-trigger:pause <id>` - Temporarily disable task without removing
- `/task-trigger:resume <id>` - Re-enable a paused task
- `/task-trigger:verify <id>` - Confirm task is active in OS scheduler

### Natural Language Examples

```bash
# Basic scheduling
"every day at 9am summarize my memory MCP entries"
"cada hora analiza logs usando deepseek"

# Temporal tasks
"every minute during the next 30 minutes check emails"
"cada minuto durante la próxima hora revisa sistema"

# Complex scheduling
"Monday and Wednesday at 8:30am backup files"

# File watchers
"watch my log file at /var/log/app.log and alert on errors"
"monitor the downloads folder for new PDF files"
```

## How It Works

1. **Agent parses** natural language into cron expression
2. **Detects platform** (WSL/Linux/macOS) and CLI (opencode/kiro)
3. **Creates task definition** in `$HOME/.task-trigger/tasks.json`
4. **Integrates with OS scheduler** (crontab or launchd)
5. **Task runs headless** at scheduled time via `task-wrapper.sh`
6. **Output goes to log file** in structured format
7. **User reads logs** when ready

## Scripts (17)

| Script | Purpose |
|---|---|
| `detect-platform.sh` | Detect OS (wsl/macos/linux) |
| `detect-cli.sh` | Detect CLI binary (full path) |
| `detect-watcher.sh` | Detect file monitoring tool |
| `add-to-crontab.sh` | Add task to crontab `[--force]` |
| `add-to-launchd.sh` | Add task to launchd `[--force]` |
| `task-wrapper.sh` | Scheduler entry point (expiration + cron check) |
| `run-task.sh` | Execute task immediately |
| `start-watcher.sh` | Start file/directory watcher |
| `stop-watcher.sh` | Stop file watcher |
| `list-tasks.py` | List tasks (cross-references scheduler) |
| `list-watchers.py` | List active watchers |
| `remove-task.sh` | Remove task completely |
| `view-logs.sh` | View task logs |
| `update-task.sh` | Update task fields in-place |
| `reload-task.sh` | Reload task config into scheduler |
| `pause-resume-task.sh` | Pause/resume without removing |
| `verify-task.sh` | Verify task is active in scheduler |

## Files Created

```
$HOME/.task-trigger/
├── tasks.json                 # Task definitions
├── logs/                     # Execution logs
│   └── {task-id}.log
├── watchers/                 # File watcher scripts
│   └── {task-id}.sh
└── launchd/                  # macOS plist files (macOS only)
    └── com.task-trigger.*.plist
```

## Safety Features

✅ No git operations
✅ No `--dangerously-skip-permissions`
✅ No MCP Sampling dependency
✅ Confirmation required before scheduler modifications
✅ `--force` flag for automated/scripted use

## Installation

```bash
npx skills add https://github.com/jheisonmb/skills --skill task-trigger
```

## License

MIT
