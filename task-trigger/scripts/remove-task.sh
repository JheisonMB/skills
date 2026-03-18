#!/bin/bash
# Remove a scheduled task
# Usage: ./remove-task.sh <task-id>

set -e

TASK_ID="$1"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id>"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"

# Check if tasks file exists
if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks registered yet."
  exit 0
fi

# Check if task exists
if ! grep -q "\"id\": \"$TASK_ID\"" "$TASKS_FILE" 2>/dev/null; then
  echo "Task '$TASK_ID' not found."
  exit 1
fi

echo "Removing task: $TASK_ID"
echo "This will:"
echo "1. Remove from tasks.json"
echo "2. Remove from crontab (Linux/WSL) or launchd (macOS)"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read -r

# Detect platform
PLATFORM=$(./detect-platform.sh)

# Remove from crontab or launchd
case "$PLATFORM" in
  wsl|linux)
    echo "Removing from crontab..."
    TEMP_CRONTAB=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# task-trigger: $TASK_ID$" | grep -v "task-trigger: $TASK_ID" > "$TEMP_CRONTAB" || true
    crontab "$TEMP_CRONTAB"
    rm -f "$TEMP_CRONTAB"
    ;;
  macos)
    echo "Removing from launchd..."
    PLIST_FILE="$HOME/.task-trigger/launchd/com.task-trigger.$TASK_ID.plist"
    if [[ -f "$PLIST_FILE" ]]; then
      launchctl unload "$PLIST_FILE" 2>/dev/null || true
      rm -f "$PLIST_FILE"
    fi
    ;;
esac

# Remove from tasks.json
TEMP_JSON=$(mktemp)
python3 -c "
import json, sys
with open('$TASKS_FILE', 'r') as f:
    tasks = json.load(f)
filtered = [t for t in tasks if t.get('id') != '$TASK_ID']
if len(filtered) == len(tasks):
    print('Task not found in JSON')
    sys.exit(1)
with open('$TEMP_JSON', 'w') as f:
    json.dump(filtered, f, indent=2)
" && mv "$TEMP_JSON" "$TASKS_FILE"

echo "Task '$TASK_ID' removed successfully."