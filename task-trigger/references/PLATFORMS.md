# Platform Implementation Guide

## Platform Detection

### Detection Commands

```bash
# WSL detection (Windows Subsystem for Linux)
if uname -r | grep -q microsoft; then
  PLATFORM="wsl"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="macos"
else
  PLATFORM="linux"
fi

echo "Detected platform: $PLATFORM"
```

### CLI Detection

```bash
# Check for opencode
if which opencode >/dev/null 2>&1; then
  CLI="opencode"
  OPENCODE_PATH=$(which opencode)
elif which kiro >/dev/null 2>&1; then
  CLI="kiro"
  KIRO_PATH=$(which kiro)
else
  echo "ERROR: Neither opencode nor kiro found in PATH"
  exit 1
fi

echo "Using CLI: $CLI"
```

## WSL/Linux Implementation

### Crontab Integration

#### Reading current crontab:
```bash
# Save current crontab to temp file
crontab -l > /tmp/current_crontab 2>/dev/null || echo "" > /tmp/current_crontab
```

#### Adding task entry:
```bash
# Add comment and entry
echo "# task-trigger: $TASK_ID" >> /tmp/current_crontab
echo "$CRON_EXPRESSION $CLI run --prompt '$PROMPT' >> $LOG_PATH 2>&1" >> /tmp/current_crontab

# If model specified:
if [ -n "$MODEL" ]; then
  echo "$CRON_EXPRESSION $CLI run --model '$MODEL' --prompt '$PROMPT' >> $LOG_PATH 2>&1" >> /tmp/current_crontab
else
  echo "$CRON_EXPRESSION $CLI run --prompt '$PROMPT' >> $LOG_PATH 2>&1" >> /tmp/current_crontab
fi
```

#### Writing back to crontab:
```bash
# ALWAYS ask confirmation
echo "I will add this to crontab:"
echo "----------------------------------------"
cat /tmp/current_crontab | tail -5
echo "----------------------------------------"
echo "Continue? [y/N]"
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  crontab /tmp/current_crontab
  echo "Crontab updated successfully"
else
  echo "Cancelled"
  exit 0
fi
```

#### Removing task from crontab:
```bash
# Remove lines containing task ID
crontab -l | grep -v "task-trigger: $TASK_ID" | crontab -
```

### WSL Specific Notes

1. **WSL must be running**: Cron jobs only fire when WSL is active
2. **Cron service**: Usually starts automatically in WSL
3. **Path issues**: Use full paths or ensure PATH is set in crontab
4. **User permissions**: Crontab runs as current user

## macOS Implementation

### Launchd Integration

#### PLIST File Location:
```
~/.task-trigger/launchd/com.task-trigger.$TASK_ID.plist
```

#### PLIST Template:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.task-trigger.$TASK_ID</string>
  
  <key>ProgramArguments</key>
  <array>
    <string>$CLI_PATH</string>
    <string>run</string>
    <!-- Add --model if specified -->
    <string>--prompt</string>
    <string>$PROMPT</string>
  </array>
  
  <key>StartCalendarInterval</key>
  <dict>
    <!-- Convert cron to StartCalendarInterval -->
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
    <!-- Add Weekday if needed -->
  </dict>
  
  <key>StandardOutPath</key>
  <string>$LOG_PATH</string>
  
  <key>StandardErrorPath</key>
  <string>$ERROR_LOG_PATH</string>
  
  <key>WorkingDirectory</key>
  <string>~</string>
  
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
```

#### Cron to StartCalendarInterval Conversion:

| Cron | StartCalendarInterval |
|------|----------------------|
| `0 9 * * *` | `Hour: 9, Minute: 0` |
| `30 8 * * 1` | `Hour: 8, Minute: 30, Weekday: 1` |
| `*/5 * * * *` | `Minute: 0,5,10,15,20,25,30,35,40,45,50,55` |

#### Loading/Unloading:

```bash
# Load task
launchctl load ~/.task-trigger/launchd/com.task-trigger.$TASK_ID.plist

# Unload task  
launchctl unload ~/.task-trigger/launchd/com.task-trigger.$TASK_ID.plist

# Check status
launchctl list | grep "com.task-trigger.$TASK_ID"
```

### macOS Specific Notes

1. **Full disk access**: Launchd may need permissions
2. **PATH in launchd**: Must be set explicitly in EnvironmentVariables
3. **.plist validation**: Use `plutil -lint` to validate
4. **LaunchAgents vs LaunchDaemons**: Use LaunchAgents for user tasks

## Cross-Platform Directory Structure

```
~/.task-trigger/
├── tasks.json                 # Main tasks database
├── tasks.json.backup         # Backup before modifications
├── logs/
│   ├── task-id.log          # Standard output
│   ├── task-id.error.log    # Error output (macOS)
│   └── rotation/            # Old logs (optional)
└── launchd/                  # macOS only
    └── com.task-trigger.*.plist
```

## Creation Scripts

### Create Directories:
```bash
mkdir -p ~/.task-trigger/logs
mkdir -p ~/.task-trigger/launchd  # macOS only
```

### Backup Tasks:
```bash
# Before modification
cp ~/.task-trigger/tasks.json ~/.task-trigger/tasks.json.backup.$(date +%Y%m%d_%H%M%S)
```

## Troubleshooting

### WSL/Linux Issues:
```bash
# Check cron service
sudo service cron status

# Check crontab entries
crontab -l

# Test cron syntax
echo "$CRON_EXPRESSION echo test" | crontab -
```

### macOS Issues:
```bash
# Validate PLIST
plutil -lint ~/.task-trigger/launchd/com.task-trigger.*.plist

# Check loaded agents
launchctl list | grep task-trigger

# Check logs
tail -f ~/.task-trigger/logs/*.log
```

### Common Problems:
1. **PATH issues**: Use full paths or set PATH in crontab/launchd
2. **Permission denied**: Check directory permissions (`ls -la ~/.task-trigger/`)
3. **Cron not running**: Start cron service (`sudo service cron start`)
4. **Launchd not loading**: Check plist syntax with `plutil`

## Platform-Specific Command Generation

### WSL/Linux Command:
```bash
# Without model
0 9 * * * /home/user/.opencode/bin/opencode run --prompt '...' >> ~/.task-trigger/logs/task.log 2>&1

# With model
0 9 * * * /home/user/.opencode/bin/opencode run --model 'deepseek/deepseek-chat' --prompt '...' >> ~/.task-trigger/logs/task.log 2>&1
```

### macOS Command (in PLIST):
```xml
<array>
  <string>/usr/local/bin/opencode</string>
  <string>run</string>
  <string>--prompt</string>
  <string>...</string>
</array>
```

## Best Practices

1. **Always use full paths** in scheduled commands
2. **Test commands manually** before scheduling
3. **Check logs immediately** after first execution
4. **Backup before modifications**
5. **Document platform-specific issues** for user