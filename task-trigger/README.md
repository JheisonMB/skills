# Task Trigger Skill v1.0

A skill that enables agents to register, manage, and execute scheduled tasks using OS native scheduler.

## Key Features

- **Natural language scheduling**: Convert "every day at 9am" to cron expressions
- **Cross-platform**: Works on WSL/Linux (crontab) and macOS (launchd)
- **Headless execution**: Tasks run without open session
- **Temporal tasks**: Support for "every minute during the next hour"
- **CLI detection**: Automatically detects opencode or kiro
- **Confirmation required**: Always asks before modifying scheduler
- **Model awareness**: Include model flag only when specified
- **Safe paths**: Uses `$HOME` instead of `~` for reliable expansion

## Usage

### Commands
- `/task-trigger:add` - Register new task (ALWAYS asks confirmation)
- `/task-trigger:list` - Show all registered tasks
- `/task-trigger:remove <id>` - Remove task + clean scheduler
- `/task-trigger:logs [id]` - View structured execution history
- `/task-trigger:run <id>` - Execute task immediately
- `/task-trigger:status` - Check scheduler health

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
```

## How It Works

1. **Agent parses** natural language into cron expression
2. **Detects platform** (WSL/Linux/macOS) and CLI (opencode/kiro)
3. **Creates task definition** in `$HOME/.task-trigger/tasks.json`
4. **Integrates with OS scheduler** (crontab or launchd)
5. **Task runs headless** at scheduled time
6. **Output goes to log file** in structured format
7. **User reads logs** when ready

## Platform Support

### WSL/Linux
- Uses `crontab` for scheduling
- Logs to `$HOME/.task-trigger/logs/`
- Requires cron service running
- Uses `$HOME` for reliable path expansion

### macOS
- Uses `launchd` with `.plist` files
- Logs to same location with error logs
- Requires proper permissions
- Dynamic paths using `$HOME`

## CLI Commands

### opencode
- Headless: `opencode run --prompt "message"`
- Model flag: `--model "provider/model"` (verified from `opencode --help`)

### kiro
- Headless: `kiro chat` (from `kiro --help-all`)
- Exact syntax may vary, check `kiro chat --help`

## Files Created

```
$HOME/.task-trigger/
├── tasks.json                 # Task definitions
├── logs/                     # Execution logs
│   └── {task-id}.log
└── launchd/                  # macOS plist files (macOS only)
    └── com.task-trigger.*.plist
```

## Safety Features

✅ **No git operations**
✅ **No `--dangerously-skip-permissions`**
✅ **No MCP Sampling dependency**
✅ **Confirmation required before scheduler modifications**
✅ **Validates platform and CLI before proceeding**
✅ **Creates backups before modifications**

## Requirements

- `opencode` or `kiro` CLI installed and in PATH
- WSL/Linux: `cron` service running
- macOS: Standard macOS with `launchd`
- Authentication already configured (uses existing auth)

## Installation

```bash
npx skills add https://github.com/jheisonmb/skills --skill task-trigger
```

## License

MIT