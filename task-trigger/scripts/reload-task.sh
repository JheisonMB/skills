#!/bin/bash
# Reload a task's configuration into the OS scheduler (launchd/crontab)
# Reads current task JSON and re-registers in scheduler
# Usage: ./reload-task.sh <task-id> [--force]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID=""
FORCE=false

if [[ $# -gt 0 && "$1" != "--"* ]]; then
  TASK_ID="$1"; shift
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --force) FORCE=true; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id> [--force]"
  exit 1
fi

TASKS_FILE="$HOME/.task-trigger/tasks.json"
if [[ ! -f "$TASKS_FILE" ]]; then
  echo "No tasks registered yet."
  exit 1
fi

PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

# Python extracts everything cleanly — no bash parsing of cron expressions
TASK_INFO=$(python3 -c "
import json, sys, os

TF = os.path.expanduser('~/.task-trigger/tasks.json')
with open(TF) as f:
    tasks = json.load(f)
task = next((t for t in tasks if t.get('id') == sys.argv[1]), None)
if not task:
    print('NOT_FOUND'); sys.exit(0)

trigger = task.get('trigger', {})
expr = trigger.get('expression', '')
enabled = task.get('enabled', True)
parts = expr.split()

# Determine schedule type and compute launchd args
# Simple interval: */N * * * * → every N minutes
if (len(parts) == 5 and parts[1] == '*' and parts[2] == '*'
        and parts[3] == '*' and parts[4] == '*' and parts[0].startswith('*/')):
    minutes = int(parts[0].replace('*/', ''))
    print(f'interval|{minutes * 60}|||{expr}|{enabled}')
# Simple calendar: M H * * * where M and H are plain integers
elif (len(parts) >= 2 and parts[0].isdigit() and parts[1].isdigit()):
    print(f'calendar|{parts[1]}|{parts[0]}||{expr}|{enabled}')
else:
    # Complex cron (*/2 in hour, weekday filters, etc.) — not expressible
    # as a single StartCalendarInterval. Use interval approximation or
    # fall back to crontab-style wrapper with launchd running every minute.
    print(f'complex||||{expr}|{enabled}')
" "$TASK_ID")

if [[ "$TASK_INFO" == "NOT_FOUND" ]]; then
  echo "Task '$TASK_ID' not found."
  exit 1
fi

IFS='|' read -r SCHED_TYPE ARG1 ARG2 _ARG3 CRON_EXPR ENABLED <<< "$TASK_INFO"

if [[ "$ENABLED" != "True" ]]; then
  echo "Task '$TASK_ID' is disabled. Enable it first."
  exit 1
fi

WRAPPER_CMD="$SCRIPT_DIR/task-wrapper.sh $TASK_ID"
FORCE_FLAG=""
[[ "$FORCE" == true ]] && FORCE_FLAG="--force"

case "$PLATFORM" in
  wsl|linux)
    echo "Reloading '$TASK_ID' in crontab..."
    TEMP_CRONTAB=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# task-trigger: $TASK_ID$" | grep -v "task-trigger: $TASK_ID" > "$TEMP_CRONTAB" || true
    echo "# task-trigger: $TASK_ID" >> "$TEMP_CRONTAB"
    echo "$CRON_EXPR $WRAPPER_CMD" >> "$TEMP_CRONTAB"

    if [[ "$FORCE" != true ]]; then
      echo "New crontab entry:"
      echo "  $CRON_EXPR $WRAPPER_CMD"
      echo ""
      echo "Press Enter to apply or Ctrl+C to cancel..."
      read -r
    fi

    crontab "$TEMP_CRONTAB"
    rm -f "$TEMP_CRONTAB"
    echo "Crontab reloaded for task: $TASK_ID"
    ;;

  macos)
    # Unload old job
    LABEL="com.task-trigger.$TASK_ID"
    PLIST_FILE="$HOME/.task-trigger/launchd/$LABEL.plist"
    if launchctl list "$LABEL" &>/dev/null; then
      echo "Unloading old job..."
      launchctl remove "$LABEL" 2>/dev/null || launchctl unload "$PLIST_FILE" 2>/dev/null || true
    elif [[ -f "$PLIST_FILE" ]]; then
      launchctl unload "$PLIST_FILE" 2>/dev/null || true
    fi

    case "$SCHED_TYPE" in
      interval)
        "$SCRIPT_DIR/add-to-launchd.sh" --task-id "$TASK_ID" --interval "$ARG1" --command "$WRAPPER_CMD" $FORCE_FLAG
        ;;
      calendar)
        "$SCRIPT_DIR/add-to-launchd.sh" --task-id "$TASK_ID" --hour "$ARG1" --minute "$ARG2" --command "$WRAPPER_CMD" $FORCE_FLAG
        ;;
      complex)
        # Complex cron can't map to a single StartCalendarInterval.
        # Use StartInterval=60 so launchd fires every minute, and let
        # task-wrapper.sh + cron-check decide whether to actually run.
        echo "Warning: Complex cron '$CRON_EXPR' — using 60s interval with wrapper-side cron check."
        "$SCRIPT_DIR/add-to-launchd.sh" --task-id "$TASK_ID" --interval 60 --command "$WRAPPER_CMD" $FORCE_FLAG
        ;;
    esac

    echo "Launchd reloaded for task: $TASK_ID"
    ;;
esac

"$SCRIPT_DIR/verify-task.sh" "$TASK_ID" 2>/dev/null || true
