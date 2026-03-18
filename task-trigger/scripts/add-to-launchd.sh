#!/bin/bash
# Create and load launchd plist for macOS
# Usage: ./add-to-launchd.sh --task-id <id> --hour <hour> --minute <minute> --command <command> [--dry-run]

set -e

TASK_ID=""
HOUR=""
MINUTE=""
COMMAND=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id)  TASK_ID="$2";  shift 2 ;;
    --hour)     HOUR="$2";     shift 2 ;;
    --minute)   MINUTE="$2";   shift 2 ;;
    --command)  COMMAND="$2";  shift 2 ;;
    --dry-run)  DRY_RUN=true;  shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" || -z "$HOUR" || -z "$MINUTE" || -z "$COMMAND" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --task-id <id> --hour <hour> --minute <minute> --command <command>"
  exit 1
fi

LAUNCHD_DIR="$HOME/.task-trigger/launchd"
mkdir -p "$LAUNCHD_DIR"
mkdir -p "$HOME/.task-trigger/logs"

PLIST_FILE="$LAUNCHD_DIR/com.task-trigger.$TASK_ID.plist"
LOG_FILE="$HOME/.task-trigger/logs/$TASK_ID.log"
ERROR_LOG="$HOME/.task-trigger/logs/$TASK_ID.error.log"

# Bug 3: Capture current user PATH for launchd
USER_PATH=$(echo "$PATH")

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
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>$HOUR</integer>
    <key>Minute</key><integer>$MINUTE</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$LOG_FILE</string>
  <key>StandardErrorPath</key>
  <string>$ERROR_LOG</string>
  <key>WorkingDirectory</key>
  <string>$HOME</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$USER_PATH</string>
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
