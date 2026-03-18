#!/bin/bash
# Create and load launchd plist for macOS
# Usage: ./add-to-launchd.sh --task-id <id> --hour <hour> --minute <minute> --command <command>

set -e

# Parse arguments
TASK_ID=""
HOUR=""
MINUTE=""
COMMAND=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    --hour)
      HOUR="$2"
      shift 2
      ;;
    --minute)
      MINUTE="$2"
      shift 2
      ;;
    --command)
      COMMAND="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate arguments
if [[ -z "$TASK_ID" || -z "$HOUR" || -z "$MINUTE" || -z "$COMMAND" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --task-id <id> --hour <hour> --minute <minute> --command <command>"
  exit 1
fi

# Create launchd directory
LAUNCHD_DIR="$HOME/.task-trigger/launchd"
mkdir -p "$LAUNCHD_DIR"

PLIST_FILE="$LAUNCHD_DIR/com.task-trigger.$TASK_ID.plist"
LOG_FILE="$HOME/.task-trigger/logs/$TASK_ID.log"
ERROR_LOG="$HOME/.task-trigger/logs/$TASK_ID.error.log"

# Create plist file
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
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
    <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
EOF

echo "Launchd plist created: $PLIST_FILE"
echo "Contents:"
cat "$PLIST_FILE"
echo ""
echo "Press Enter to load with launchctl or Ctrl+C to cancel..."
read -r

# Load the plist
launchctl load "$PLIST_FILE"

echo "Launchd job loaded successfully for task: $TASK_ID"
echo "To unload: launchctl unload $PLIST_FILE"