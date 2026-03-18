# Changelog - Task Trigger Skill

## Version 2.1 (2026-03-18)

### New Features
- **`/task-trigger:update <id>`**: Update individual task fields (prompt, schedule, model, name, timeout, working-dir) without remove+add. Auto-reloads scheduler when schedule changes.
- **`/task-trigger:reload <id>`**: Reload task config into launchd/crontab after manual JSON edits. No more manual `launchctl unload + load`.
- **`/task-trigger:pause <id>` / `/task-trigger:resume <id>`**: Temporarily disable/enable tasks without removing them. Unloads from scheduler on pause, reloads on resume.
- **`/task-trigger:verify <id>`**: Confirm task is actually registered and active in OS scheduler (not just in JSON).
- **Scheduler cross-reference in list**: `list-tasks.py` now shows `Active` vs `JSON-only` vs `Paused` by checking launchctl/crontab.
- **`--force` flag on `add-to-crontab.sh`**: Non-interactive mode for automated/scripted use.

### Bug Fixes
- **remove-task.sh**: Now uses `launchctl remove <label>` before deleting plist to clear stale PID and prevent "Input/output error" on reload.
- **add-to-launchd.sh**: Added `--force` flag for non-interactive auto-load. Always unloads previous plist version before loading new one.
- **start-watcher.sh**: Now auto-loads the plist in launchd after creating it (was only printing instructions before).
- **reload-task.sh**: Complex cron expressions (e.g. `0 */2 * * *`) now fall back to 60s interval instead of generating invalid plist XML.

### New Scripts
- `update-task.sh` — Update task fields in-place
- `reload-task.sh` — Reload task config into scheduler
- `pause-resume-task.sh` — Pause/resume without removing
- `verify-task.sh` — Verify task is active in OS scheduler

## Version 2.0 (2026-03-18)

### New Features
- **File watchers**: Monitor files/directories for changes using inotifywait, fswatch, or polling
- **Pre-built scripts**: 12 scripts for all operations (detect, add, remove, watch, list, run, logs)
- **Commands**: `/task-trigger:watch`, `/task-trigger:watchers`, `/task-trigger:unwatch`
- **Dry-run mode**: `--dry-run` flag on add-to-crontab, add-to-launchd, and start-watcher scripts
- **Prompt templates**: `{{TIMESTAMP}}`, `{{FILE_PATH}}`, `{{TASK_ID}}`, `{{LOG_PATH}}` variable substitution
- **Auto-cleanup**: Temporal tasks with `expires_at` are automatically disabled when expired
- **Enhanced status**: Shows last execution, next run time, and time remaining for temporal tasks

### Bug Fixes
- Fixed `declare -A` incompatible with macOS bash 3.2 — polling watcher now uses temp dir for state
- Fixed file vs directory handling — start-watcher.sh detects path type and handles single files correctly
- Fixed PATH not available in launchd — plist now includes user's full PATH in EnvironmentVariables
- Added `--trust-all-tools` flag for kiro headless commands (required for file writes)
- Fixed relative paths in scripts — all scripts use `SCRIPT_DIR` for reliable execution from any directory
- Fixed `stat -c` on macOS — polling watcher uses cross-platform `get_mtime()` function
- Fixed debounce in watchers — replaced pipe subshell variable with temp file persistence
- Fixed `fswatch` output parsing — corrected variable order to `FILE EVENT`
- Fixed tasks.json format inconsistency — unified to plain array format across docs and scripts
- `detect-cli.sh` now outputs full binary path instead of just name
- `run-task.sh` uses `cli_path` from task JSON and adds `--trust-all-tools` for kiro
- All scripts now ship with +x permissions
- Updated README to v2.0 with file watcher docs and correct kiro CLI syntax

## Version 1.0 (2026-03-18)

### Initial Release

#### Core Features
- **Natural language parsing**: Convert user requests to cron expressions
- **Cross-platform support**: WSL/Linux (crontab) and macOS (launchd)
- **Temporal tasks**: Support for "every minute during the next X minutes"
- **CLI detection**: Automatic detection of opencode vs kiro
- **Model awareness**: Include `--model` flag only when user specifies
- **Confirmation required**: Always ask before modifying scheduler

#### Commands Implemented
- `/task-trigger:add` - Interactive task registration with confirmation
- `/task-trigger:list` - Display all registered tasks
- `/task-trigger:remove <id>` - Remove task + clean scheduler
- `/task-trigger:logs [id]` - View structured execution logs
- `/task-trigger:run <id>` - Execute task immediately for testing
- `/task-trigger:status` - Check scheduler health

#### File Structure
- `~/.task-trigger/tasks.json` - Central task database
- `~/.task-trigger/logs/` - Structured execution logs
- `~/.task-trigger/launchd/` - macOS plist files (macOS only)

#### Natural Language Support
- English and Spanish scheduling expressions
- Temporal durations: "during the next X minutes/hours"
- Model specification: "using deepseek", "con claude-3.5"
- Complex cron: "Monday and Wednesday at 8:30am"

#### Safety Features
- Never uses `--dangerously-skip-permissions`
- Always confirms before modifying crontab/launchd
- Validates platform and CLI before proceeding
- Creates backups before modifications

#### Documentation
- SKILL.md with detailed agent instructions
- References for task format, platforms, and logs
- README.md with usage examples
- Comprehensive error handling guidance

### Technical Implementation
- Pure skill-based approach (no external scripts)
- Agent performs all parsing and system integration
- Follows design document specifications exactly
- Compatible with existing opencode/kiro authentication

### Known Limitations
- Windows Task Scheduler not supported
- No event triggers (watch:mcp, watch:file) - planned for v2
- No automatic log rotation in v1
- Manual cleanup required for expired temporal tasks

### Next Version (v2) Planning
- Event-based triggers
- Automatic log rotation
- Enhanced error recovery
- Web interface for log viewing
- `npx task-trigger` package evolution