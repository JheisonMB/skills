# Changelog - Task Trigger Skill

## Version 2.1 (2026-03-18)

### Bug Fixes
- **CRLF prevention**: Added `.gitattributes` to force LF line endings on all `.sh`, `.py`, `.md`, `.json` files — prevents `$'\r': command not found` errors in WSL
- **`detect-watcher.sh`**: Replaced `which` with `command -v` (POSIX-compliant)
- **`add-to-crontab.sh`**: Added `--force` flag to skip interactive `read -r` confirmation in agent/automated contexts
- **`add-to-launchd.sh`**: Added `--force` flag to skip interactive `read -r` confirmation in agent/automated contexts
- **`start-watcher.sh`**: Replaced `$PATH` capture from current shell with clean minimal PATH for launchd/systemd plists
- **`task-wrapper.sh`**: Added `python3` existence check before execution
- **`run-task.sh`**: Added `python3` existence check before execution
- **`remove-task.sh`**: Added `python3` existence check before JSON manipulation

### Documentation
- **`PLATFORMS.md`**: Rewritten to align with v2 — uses scripts instead of manual bash, documents `task-wrapper.sh` requirement, adds WSL CRLF troubleshooting
- **`SKILL.md`**: Updated script table with `--force` flags, added WSL CRLF notes, updated examples to use `--force`, updated rule 20 to cover all `--force`-capable scripts

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