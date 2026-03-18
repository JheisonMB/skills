# Task Format Reference

## Full Task JSON Schema

```json
{
  "id": "unique-task-id",
  "name": "Human readable name",
  "enabled": true,
  "trigger": {
    "type": "cron",
    "expression": "0 9 * * *",
    "timezone": "local",
    "duration_minutes": 30,
    "expires_at": "2026-03-18T15:30:00Z"
  },
  "execution": {
    "agent": "opencode",
    "model": "deepseek/deepseek-chat",
    "prompt": "Full prompt text...",
    "workingDirectory": "~",
    "timeout": 300
  },
  "created_at": "2026-03-18T10:00:00Z",
  "updated_at": "2026-03-18T10:00:00Z",
  "log_path": "~/.task-trigger/logs/unique-task-id.log"
}
```

## Field Descriptions

### `id` (required)
- Unique identifier for the task
- Format: lowercase, hyphens, descriptive
- Examples: `daily-memory-summary`, `log-analysis-30min`, `backup-monday-am`

### `name` (required)
- Human-readable description
- Used in confirmation messages and listings

### `enabled` (required)
- Boolean: `true` for active, `false` for disabled
- Disabled tasks remain in JSON but not in scheduler

### `trigger` (required)

#### `type`
- Currently always `"cron"`
- Future: `"interval"`, `"watch:mcp"`, `"watch:file"`

#### `expression`
- Cron expression in standard format
- Examples: `0 9 * * *`, `*/5 * * * *`, `30 8 * * 1,3,5`

#### `timezone`
- Timezone for execution
- Default: `"local"` (system timezone)
- Future: `"UTC"`, `"America/New_York"`, etc.

#### `duration_minutes` (optional)
- For temporal tasks: "every minute during the next 30 minutes"
- Number of minutes the task should run
- Null for indefinite tasks

#### `expires_at` (optional)
- ISO 8601 timestamp when task should auto-remove
- Calculated: `created_at + duration_minutes`
- Null for indefinite tasks

### `execution` (required)

#### `agent`
- CLI to use: `"opencode"` or `"kiro"`
- Detected automatically during creation

#### `model` (optional)
- Model specification: `"provider/model"`
- Examples: `"deepseek/deepseek-chat"`, `"opencode/zen"`
- Only include if user explicitly mentioned model
- If null/omitted: CLI uses last used model

#### `prompt`
- Full prompt text to execute
- Should include instruction to write to log file
- Example: "Check MCP memory... Write output to ~/.task-trigger/logs/task-id.log"

#### `workingDirectory`
- Directory to run the command in
- Default: `"~"` (user's home directory)

#### `timeout`
- Maximum execution time in seconds
- Default: `300` (5 minutes)
- After timeout, task is killed

### Timestamps
- `created_at`: ISO 8601 when task was created
- `updated_at`: ISO 8601 when task was last modified
- `expires_at`: ISO 8601 when temporal task expires

### `log_path`
- Full path to log file
- Format: `~/.task-trigger/logs/{task-id}.log`
- Error logs: `~/.task-trigger/logs/{task-id}.error.log` (macOS only)

## Examples

### Basic Daily Task
```json
{
  "id": "daily-backup",
  "name": "Daily Backup at 2am",
  "enabled": true,
  "trigger": {
    "type": "cron",
    "expression": "0 2 * * *",
    "timezone": "local"
  },
  "execution": {
    "agent": "opencode",
    "prompt": "Backup important documents to cloud storage. Write summary to ~/.task-trigger/logs/daily-backup.log",
    "workingDirectory": "~",
    "timeout": 600
  },
  "created_at": "2026-03-18T10:00:00Z",
  "log_path": "~/.task-trigger/logs/daily-backup.log"
}
```

### Temporal Task (30 minutes)
```json
{
  "id": "system-monitor-30min",
  "name": "System Monitor every minute for 30 minutes",
  "enabled": true,
  "trigger": {
    "type": "cron",
    "expression": "*/1 * * * *",
    "timezone": "local",
    "duration_minutes": 30,
    "expires_at": "2026-03-18T15:30:00Z"
  },
  "execution": {
    "agent": "opencode",
    "model": "deepseek/deepseek-chat",
    "prompt": "Check system resources (CPU, memory, disk) and log to ~/.task-trigger/logs/system-monitor-30min.log",
    "workingDirectory": "~",
    "timeout": 60
  },
  "created_at": "2026-03-18T15:00:00Z",
  "log_path": "~/.task-trigger/logs/system-monitor-30min.log"
}
```

### Task with Specific Model
```json
{
  "id": "weekly-report",
  "name": "Weekly Report on Mondays",
  "enabled": true,
  "trigger": {
    "type": "cron",
    "expression": "0 8 * * 1",
    "timezone": "local"
  },
  "execution": {
    "agent": "opencode",
    "model": "openrouter/anthropic/claude-3.5-sonnet",
    "prompt": "Generate weekly progress report from MCP memory. Write to ~/.task-trigger/logs/weekly-report.log",
    "workingDirectory": "~",
    "timeout": 900
  },
  "created_at": "2026-03-18T10:00:00Z",
  "log_path": "~/.task-trigger/logs/weekly-report.log"
}
```

## Tasks.json Structure

The main file `~/.task-trigger/tasks.json` contains an array of tasks:

```json
[
  { /* task 1 */ },
  { /* task 2 */ },
  { /* task 3 */ }
]
```

## Notes

1. **File location**: Always use `~/.task-trigger/tasks.json`
2. **Backup**: Consider creating backup before modifications
3. **Validation**: Validate JSON schema after modifications
4. **Atomic writes**: Write to temp file then move to ensure consistency