#!/bin/bash
# Create and load launchd plist for macOS
# Usage: ./add-to-launchd.sh --task-id <id> --hour <H> --minute <M> --command <cmd> [--interval <secs>] [--working-dir <path>] [--dry-run]
# Note: --hour/--minute and --interval are mutually exclusive

set -e

TASK_ID=""
HOUR=""
MINUTE=""
COMMAND=""
INTERVAL=""
WORKING_DIR="$HOME"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id)      TASK_ID="$2";      shift 2 ;;
    --hour)         HOUR="$2";         shift 2 ;;
    --minute)       MINUTE="$2";       shift 2 ;;
    --command)      COMMAND="$2";      shift 2 ;;
    --interval)     INTERVAL="$2";     shift 2 ;;
    --working-dir)  WORKING_DIR="$2";  shift 2 ;;
    --dry-run)      DRY_RUN=true;      shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required args
if [[ -z "$TASK_ID" || -z "$COMMAND" ]]; then
  echo "Error: --task-id and --command are required"
  echo "Usage: $0 --task-id <id> (--hour <H> --minute <M> | --interval <secs>) --command <cmd> [--working-dir <path>] [--dry-run]"
  exit 1
fi

# Validate mutually exclusive scheduling
if [[ -n "$INTERVAL" && (-n "$HOUR" || -n "$MINUTE") ]]; then
  echo "Error: --interval and --hour/--minute are mutually exclusive"
  exit 1
fi

if [[ -z "$INTERVAL" && (-z "$HOUR" || -z "$MINUTE") ]]; then
  echo "Error: Either --interval or both --hour and --minute are required"
  exit 1
fi

LAUNCHD_DIR="$HOME/.task-trigger/launchd"
mkdir -p "$LAUNCHD_DIR"
mkdir -p "$HOME/.task-trigger/logs"

PLIST_FILE="$LAUNCHD_DIR/com.task-trigger.$TASK_ID.plist"
LOG_FILE="$HOME/.task-trigger/logs/$TASK_ID.log"
ERROR_LOG="$HOME/.task-trigger/logs/$TASK_ID.error.log"

# Mejora 8: PATH limpio con solo directorios esenciales
CLEAN_PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Build schedule section
if [[ -n "$INTERVAL" ]]; then
  SCHEDULE_SECTION="  <key>StartInterval</key>
  <integer>$INTERVAL</integer>"
else
  SCHEDULE_SECTION="  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>$HOUR</integer>
    <key>Minute</key><integer>$MINUTE</integer>
  </dict>"
fi

PLIST_CONTENT="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
  <key>Label</key>
  <string>com.task-trigger.$TASK_ID</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>$COMMAND</string>
  </array>
$SCHEDULE_SECTION
  <key>StandardOutPath</key>
  <string>$LOG_FILE</string>
  <key>StandardErrorPath</key>
  <string>$ERROR_LOG</string>
  <key>WorkingDirectory</key>
  <string>$WORKING_DIR</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$CLEAN_PATH</string>
    <key>HOME</key>
    <string>$HOME</string>
  </dict>
</dict>
</plist>"

if [[ "$DRY_RUN" == true ]]; then
  echo "=== DRY RUN ==="
  echo "Would create: $PLIST_FILE"
  echo ""
  echo "$PLIST_CONTENT"
  echo ""
  echo "Would run: launchctl load $PLIST_FILE"
  echo "=== No changes made ==="
  exit 0
fi

echo "$PLIST_CONTENT" > "$PLIST_FILE"

echo "Launchd plist created: $PLIST_FILE"
echo "Contents:"
cat "$PLIST_FILE"
echo ""
echo "Press Enter to load with launchctl or Ctrl+C to cancel..."
read -r

launchctl load "$PLIST_FILE"

echo "Launchd job loaded successfully for task: $TASK_ID"
echo "To unload: launchctl unload $PLIST_FILE"
