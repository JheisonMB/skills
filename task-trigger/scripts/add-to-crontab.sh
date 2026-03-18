#!/bin/bash
# Add a task to crontab (Linux/WSL)
# Usage: ./add-to-crontab.sh --task-id <id> --cron <expression> --command <command> [--dry-run]

set -e

TASK_ID=""
CRON_EXPR=""
COMMAND=""
DRY_RUN=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id)  TASK_ID="$2";   shift 2 ;;
    --cron)     CRON_EXPR="$2"; shift 2 ;;
    --command)  COMMAND="$2";   shift 2 ;;
    --dry-run)  DRY_RUN=true;   shift ;;
    --force)    FORCE=true;     shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate arguments
if [[ -z "$TASK_ID" || -z "$CRON_EXPR" || -z "$COMMAND" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --task-id <id> --cron <expression> --command <command>"
  exit 1
fi

# Create temporary crontab file
TEMP_CRONTAB=$(mktemp)

# Read current crontab or create empty
crontab -l 2>/dev/null > "$TEMP_CRONTAB" || echo "" > "$TEMP_CRONTAB"

# Add new entry
echo "# task-trigger: $TASK_ID" >> "$TEMP_CRONTAB"
echo "$CRON_EXPR $COMMAND" >> "$TEMP_CRONTAB"

echo "Crontab entry to add:"
echo "  # task-trigger: $TASK_ID"
echo "  $CRON_EXPR $COMMAND"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "=== DRY RUN — No changes made ==="
  rm -f "$TEMP_CRONTAB"
  exit 0
fi

if [[ "$FORCE" != true ]]; then
  echo "Press Enter to continue or Ctrl+C to cancel..."
  read -r
fi

# Apply new crontab
crontab "$TEMP_CRONTAB"

# Cleanup
rm -f "$TEMP_CRONTAB"

echo "Crontab updated successfully for task: $TASK_ID"