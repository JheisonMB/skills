#!/bin/bash
# View logs for a task
# Usage: ./view-logs.sh [task-id] [--tail] [--lines N]

set -e

TASK_ID=""
TAIL_MODE=false
LINES=50

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tail)
      TAIL_MODE=true
      shift
      ;;
    --lines)
      LINES="$2"
      shift 2
      ;;
    *)
      if [[ -z "$TASK_ID" ]]; then
        TASK_ID="$1"
      else
        echo "Unknown argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

LOG_DIR="$HOME/.task-trigger/logs"

if [[ ! -d "$LOG_DIR" ]]; then
  echo "Log directory not found: $LOG_DIR"
  exit 1
fi

if [[ -z "$TASK_ID" ]]; then
  # List available logs
  echo "Available logs:"
  echo "---------------"
  for log in "$LOG_DIR"/*.log; do
    if [[ -f "$log" ]]; then
      filename=$(basename "$log")
      task_id="${filename%.log}"
      size=$(stat -c%s "$log" 2>/dev/null || stat -f%z "$log" 2>/dev/null)
      lines=$(wc -l < "$log" 2>/dev/null || echo "0")
      echo "$task_id - ${size} bytes, ${lines} lines"
    fi
  done
  exit 0
fi

LOG_FILE="$LOG_DIR/$TASK_ID.log"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Log file not found: $LOG_FILE"
  exit 1
fi

echo "=== Log for task: $TASK_ID ==="
echo "File: $LOG_FILE"
echo ""

if [[ "$TAIL_MODE" == true ]]; then
  tail -f -n "$LINES" "$LOG_FILE"
else
  tail -n "$LINES" "$LOG_FILE"
fi