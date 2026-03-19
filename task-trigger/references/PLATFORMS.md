# Platform Implementation Guide

## Platform Detection

Use the provided script instead of manual detection:

```bash
PLATFORM=$(./scripts/detect-platform.sh)
echo "Detected platform: $PLATFORM"  # wsl, macos, or linux
```

### CLI Detection

Use the provided script — returns full path or "none":

```bash
CLI_PATH=$(./scripts/detect-cli.sh)
echo "Using CLI: $CLI_PATH"
```

## WSL/Linux Implementation (crontab)

**CRITICAL: Crontab MUST call `task-wrapper.sh`, never the CLI directly.**

### Adding a task:
```bash
SCRIPT_DIR="$(pwd)/scripts"
COMMAND="$SCRIPT_DIR/task-wrapper.sh daily-summary"

./scripts/add-to-crontab.sh \
  --task-id "daily-summary" \
  --cron "0 9 * * *" \
  --command "$COMMAND" \
  --force
```

### Removing a task:
```bash
./scripts/remove-task.sh daily-summary --force
```

### WSL Specific Notes

1. **WSL must be running** — cron jobs only fire when WSL is active
2. **Cron service** — may need `sudo service cron start`
3. **CRLF** — if scripts fail with `$'\r'` errors, run `dos2unix scripts/*.sh` or ensure `.gitattributes` forces LF
4. **Permissions** — files on `/mnt/c/` always show 777; move skill to `~/` for proper Unix permissions

## macOS Implementation (launchd)

**CRITICAL: Plist MUST call `task-wrapper.sh`, never the CLI directly.**

### Adding a task (calendar):
```bash
SCRIPT_DIR="$(pwd)/scripts"
COMMAND="$SCRIPT_DIR/task-wrapper.sh daily-summary"

./scripts/add-to-launchd.sh \
  --task-id "daily-summary" \
  --hour 9 --minute 0 \
  --command "$COMMAND" \
  --working-dir "$HOME" \
  --force
```

### Adding a task (interval):
```bash
./scripts/add-to-launchd.sh \
  --task-id "health-check" \
  --interval 300 \
  --command "$SCRIPT_DIR/task-wrapper.sh health-check" \
  --force
```

### macOS Specific Notes

1. **Full disk access** — launchd may need permissions in System Settings
2. **PATH** — scripts use a clean PATH, not the shell's PATH
3. **Validate plist** — `plutil -lint ~/.task-trigger/launchd/com.task-trigger.*.plist`

## Cross-Platform Directory Structure

```
~/.task-trigger/
├── tasks.json              # Task database (plain JSON array)
├── logs/
│   ├── <task-id>.log       # Standard output
│   └── <task-id>.error.log # Error output (macOS)
├── launchd/                # macOS only
│   └── com.task-trigger.*.plist
└── watchers/               # File watcher scripts
    └── <task-id>.sh
```

## Troubleshooting

### WSL/Linux:
```bash
sudo service cron status        # Check cron service
crontab -l                      # List entries
```

### macOS:
```bash
plutil -lint ~/.task-trigger/launchd/*.plist  # Validate
launchctl list | grep task-trigger            # Check loaded
```

### Common Problems:
- **`$'\r': command not found`** — CRLF line endings. Fix: `dos2unix scripts/*.sh` or use `.gitattributes`
- **Permission denied** — check `ls -la ~/.task-trigger/`
- **CLI not found** — use full path from `detect-cli.sh`
- **777 permissions on WSL** — move files off `/mnt/c/` to `~/`
