# Log Format Reference

## Standard Log Format

All task executions produce structured logs with this format:

```
[2026-03-18 09:00:01] task=daily-memory-summary status=started
[2026-03-18 09:00:47] task=daily-memory-summary status=completed duration=46s
--- output ---
Found 3 new memory entries since yesterday:
- Tesis: added note about denoising comparison methodology
- Accenture: Kiro MCP config updated
- Personal: scheduled dentist appointment
```

## Log File Structure

### Standard Output Log
```
~/.task-trigger/logs/{task-id}.log
```

### Error Log (macOS only)
```
~/.task-trigger/logs/{task-id}.error.log
```

## Log Entry Types

### 1. Task Start
```
[YYYY-MM-DD HH:MM:SS] task={task-id} status=started
```

### 2. Task Completion
```
[YYYY-MM-DD HH:MM:SS] task={task-id} status=completed duration={seconds}s
```

### 3. Task Error
```
[YYYY-MM-DD HH:MM:SS] task={task-id} status=error error={error-message} duration={seconds}s
```

### 4. Task Timeout
```
[YYYY-MM-DD HH:MM:SS] task={task-id} status=timeout duration={seconds}s
```

### 5. Task Output
```
--- output ---
{output from CLI}
```

### 6. System Messages
```
[YYYY-MM-DD HH:MM:SS] system={message}
```

## Timestamp Format

- **Format**: `[YYYY-MM-DD HH:MM:SS]`
- **Timezone**: Local system time
- **Example**: `[2026-03-18 09:00:01]`

## Duration Format

- **Units**: seconds (`s`)
- **Precision**: integer seconds
- **Example**: `duration=46s`

## Field Separation

- **Fields separated by spaces**: `task=id status=value`
- **No commas** between fields
- **Consistent spacing** for parsing

## Special Cases

### Multi-line Output
```
--- output ---
Line 1 of output
Line 2 of output
Line 3 with special characters: !@#$%^&*()
```

### Empty Output
```
--- output ---
(no output)
```

### Truncated Output
```
--- output ---
[output truncated after 10000 characters]
```

## Log Rotation

### Manual Rotation
```bash
# Archive old log
mv ~/.task-trigger/logs/task-id.log ~/.task-trigger/logs/rotation/task-id.log.$(date +%Y%m%d)

# Create new log
touch ~/.task-trigger/logs/task-id.log
```

### Size-based Rotation (optional)
```bash
# Check log size
LOG_SIZE=$(stat -c%s ~/.task-trigger/logs/task-id.log)
if [ $LOG_SIZE -gt 10485760 ]; then  # 10MB
    mv ~/.task-trigger/logs/task-id.log ~/.task-trigger/logs/rotation/task-id.log.$(date +%Y%m%d_%H%M%S)
fi
```

## Log Viewing Commands

### Basic View
```bash
# View entire log
cat ~/.task-trigger/logs/task-id.log

# View last 50 lines
tail -50 ~/.task-trigger/logs/task-id.log

# Follow log in real-time
tail -f ~/.task-trigger/logs/task-id.log
```

### Filtered View
```bash
# View only task executions
grep "status=" ~/.task-trigger/logs/task-id.log

# View errors only
grep "status=error" ~/.task-trigger/logs/task-id.log

# View by date
grep "^\[2026-03-18" ~/.task-trigger/logs/task-id.log
```

### Statistics
```bash
# Count executions
grep "status=completed" ~/.task-trigger/logs/task-id.log | wc -l

# Average duration
grep "duration=" ~/.task-trigger/logs/task-id.log | awk -F'duration=' '{print $2}' | awk -F's' '{sum+=$1; count++} END {print "Average: " sum/count "s"}'

# Last execution time
grep "status=completed" ~/.task-trigger/logs/task-id.log | tail -1 | awk '{print $1}'
```

## Log Parsing Examples

### Parse with awk:
```bash
# Extract task IDs
awk -F'task=' '{print $2}' ~/.task-trigger/logs/task-id.log | awk '{print $1}' | sort | uniq

# Extract durations
awk -F'duration=' '{print $2}' ~/.task-trigger/logs/task-id.log | awk -F's' '{print $1}' | grep -v "^$"
```

### Parse with Python:
```python
import re

log_pattern = r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] task=(\S+) status=(\S+)(?: duration=(\d+)s)?'

with open('~/.task-trigger/logs/task-id.log', 'r') as f:
    for line in f:
        match = re.match(log_pattern, line)
        if match:
            timestamp, task_id, status, duration = match.groups()
            print(f"{timestamp}: {task_id} - {status} ({duration}s)")
```

## Best Practices

1. **Always write to log**: Ensure prompt includes log instruction
2. **Structured format**: Maintain consistent format for parsing
3. **Timestamp everything**: Every entry must have timestamp
4. **Include task ID**: Every entry must identify which task
5. **Separate output clearly**: Use `--- output ---` separator
6. **Handle special characters**: Escape or encode as needed
7. **Monitor log size**: Implement rotation for long-running tasks
8. **Backup important logs**: Archive before cleanup

## Example Prompts with Log Instructions

### Good:
```
Check MCP memory for new entries since yesterday and summarize them. Write output to ~/.task-trigger/logs/daily-memory-summary.log
```

### Better (includes error handling):
```
Check system resources and log results. If successful, write to ~/.task-trigger/logs/system-check.log. If error occurs, include error details in log.
```

### Best (structured output):
```
Analyze project status and produce report. Format output as:
[SUMMARY]
- Completed items: X
- Pending items: Y
- Issues: Z

Write full output to ~/.task-trigger/logs/project-status.log
```

## Troubleshooting Log Issues

### No Log Created
1. Check directory permissions: `ls -la ~/.task-trigger/logs/`
2. Check prompt includes log instruction
3. Check redirection in crontab/plist

### Log Format Errors
1. Verify timestamp format
2. Check field spacing
3. Ensure special characters are handled

### Log Size Issues
1. Implement log rotation
2. Consider output truncation
3. Archive old logs periodically