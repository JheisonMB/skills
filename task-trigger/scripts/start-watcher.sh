#!/bin/bash
# Start a file/directory watcher
# Usage: ./start-watcher.sh --task-id <id> --path <path> --events <events> --command <command>

set -e

# Parse arguments
TASK_ID=""
WATCH_PATH=""
WATCH_EVENTS=""
COMMAND=""
RECURSIVE="false"
POLL_INTERVAL=5
DEBOUNCE=1

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    --path)
      WATCH_PATH="$2"
      shift 2
      ;;
    --events)
      WATCH_EVENTS="$2"
      shift 2
      ;;
    --command)
      COMMAND="$2"
      shift 2
      ;;
    --recursive)
      RECURSIVE="$2"
      shift 2
      ;;
    --poll-interval)
      POLL_INTERVAL="$2"
      shift 2
      ;;
    --debounce)
      DEBOUNCE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Validate arguments
if [[ -z "$TASK_ID" || -z "$WATCH_PATH" || -z "$WATCH_EVENTS" || -z "$COMMAND" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --task-id <id> --path <path> --events <events> --command <command>"
  exit 1
fi

# Create watchers directory
WATCHERS_DIR="$HOME/.task-trigger/watchers"
mkdir -p "$WATCHERS_DIR"

# Detect available watcher tool
WATCHER_TOOL=$(./detect-watcher.sh)

# Create watcher script based on tool
WATCHER_SCRIPT="$WATCHERS_DIR/$TASK_ID.sh"

case "$WATCHER_TOOL" in
  inotifywait)
    # inotifywait events mapping
    IFS=',' read -ra EVENTS <<< "$WATCH_EVENTS"
    INOTIFY_EVENTS=""
    for event in "${EVENTS[@]}"; do
      case "$event" in
        create) INOTIFY_EVENTS+="create," ;;
        modify) INOTIFY_EVENTS+="modify," ;;
        delete) INOTIFY_EVENTS+="delete," ;;
        move) INOTIFY_EVENTS+="moved_to,moved_from," ;;
        *) echo "Unknown event: $event" >&2; exit 1 ;;
      esac
    done
    INOTIFY_EVENTS="${INOTIFY_EVENTS%,}"
    
    RECURSIVE_FLAG=""
    if [[ "$RECURSIVE" == "true" ]]; then
      RECURSIVE_FLAG="-r"
    fi
    
    cat > "$WATCHER_SCRIPT" << EOF
#!/bin/bash
set -e

LAST_RUN=0
DEBOUNCE=$DEBOUNCE

inotifywait $RECURSIVE_FLAG -m -e "$INOTIFY_EVENTS" --format '%w%f %e' "$WATCH_PATH" | while read FILE EVENT
do
  CURRENT_TIME=\$(date +%s)
  if [[ \$((CURRENT_TIME - LAST_RUN)) -ge \$DEBOUNCE ]]; then
    echo "[Watcher] File changed: \$FILE (\$EVENT)"
    bash -c "$COMMAND"
    LAST_RUN=\$CURRENT_TIME
  fi
done
EOF
    ;;
  
  fswatch)
    # fswatch events mapping (macOS)
    cat > "$WATCHER_SCRIPT" << EOF
#!/bin/bash
set -e

LAST_RUN=0
DEBOUNCE=$DEBOUNCE

fswatch -x -r "$WATCH_PATH" | while read EVENT FILE
do
  CURRENT_TIME=\$(date +%s)
  if [[ \$((CURRENT_TIME - LAST_RUN)) -ge \$DEBOUNCE ]]; then
    echo "[Watcher] File changed: \$FILE (\$EVENT)"
    bash -c "$COMMAND"
    LAST_RUN=\$CURRENT_TIME
  fi
done
EOF
    ;;
  
  polling)
    # Polling with find and stat
    cat > "$WATCHER_SCRIPT" << EOF
#!/bin/bash
set -e

declare -A FILE_STATES
LAST_RUN=0
DEBOUNCE=$DEBOUNCE
POLL_INTERVAL=$POLL_INTERVAL

# Initial scan
if [[ "$RECURSIVE" == "true" ]]; then
  find "$WATCH_PATH" -type f 2>/dev/null | while read FILE; do
    STAT=\$(stat -c "%Y %s" "\$FILE" 2>/dev/null || echo "0 0")
    FILE_STATES["\$FILE"]="\$STAT"
  done
else
  for FILE in "$WATCH_PATH"/*; do
    if [[ -f "\$FILE" ]]; then
      STAT=\$(stat -c "%Y %s" "\$FILE" 2>/dev/null || echo "0 0")
      FILE_STATES["\$FILE"]="\$STAT"
    fi
  done
fi

while true; do
  sleep \$POLL_INTERVAL
  
  # Check for changes
  if [[ "$RECURSIVE" == "true" ]]; then
    find "$WATCH_PATH" -type f 2>/dev/null | while read FILE; do
      CURRENT_STAT=\$(stat -c "%Y %s" "\$FILE" 2>/dev/null || echo "0 0")
      OLD_STAT="\${FILE_STATES[\$FILE]}"
      
      if [[ "\$CURRENT_STAT" != "\$OLD_STAT" ]]; then
        CURRENT_TIME=\$(date +%s)
        if [[ \$((CURRENT_TIME - LAST_RUN)) -ge \$DEBOUNCE ]]; then
          echo "[Watcher] File changed: \$FILE"
          bash -c "$COMMAND"
          LAST_RUN=\$CURRENT_TIME
        fi
        FILE_STATES["\$FILE"]="\$CURRENT_STAT"
      fi
    done
  else
    for FILE in "$WATCH_PATH"/*; do
      if [[ -f "\$FILE" ]]; then
        CURRENT_STAT=\$(stat -c "%Y %s" "\$FILE" 2>/dev/null || echo "0 0")
        OLD_STAT="\${FILE_STATES[\$FILE]}"
        
        if [[ "\$CURRENT_STAT" != "\$OLD_STAT" ]]; then
          CURRENT_TIME=\$(date +%s)
          if [[ \$((CURRENT_TIME - LAST_RUN)) -ge \$DEBOUNCE ]]; then
            echo "[Watcher] File changed: \$FILE"
            bash -c "$COMMAND"
            LAST_RUN=\$CURRENT_TIME
          fi
          FILE_STATES["\$FILE"]="\$CURRENT_STAT"
        fi
      fi
    done
  fi
done
EOF
    ;;
  
  *)
    echo "No file monitoring tool available"
    exit 1
    ;;
esac

chmod +x "$WATCHER_SCRIPT"

# Create systemd service or launchd plist for persistence
PLATFORM=$(./detect-platform.sh)

case "$PLATFORM" in
  wsl|linux)
    # Create systemd user service
    SERVICE_FILE="$HOME/.config/systemd/user/task-trigger-$TASK_ID.service"
    mkdir -p "$(dirname "$SERVICE_FILE")"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Task Trigger Watcher: $TASK_ID
After=network.target

[Service]
Type=simple
ExecStart=$WATCHER_SCRIPT
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    
    echo "Systemd service created: $SERVICE_FILE"
    echo "To enable: systemctl --user enable task-trigger-$TASK_ID.service"
    echo "To start: systemctl --user start task-trigger-$TASK_ID.service"
    ;;
  
  macos)
    # Create launchd plist
    PLIST_FILE="$HOME/Library/LaunchAgents/com.task-trigger.$TASK_ID.plist"
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.task-trigger.$TASK_ID</string>
  <key>ProgramArguments</key>
  <array>
    <string>$WATCHER_SCRIPT</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/.task-trigger/logs/watcher-$TASK_ID.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.task-trigger/logs/watcher-$TASK_ID.error.log</string>
</dict>
</plist>
EOF
    
    echo "Launchd plist created: $PLIST_FILE"
    echo "To load: launchctl load $PLIST_FILE"
    ;;
esac

echo "Watcher created for task: $TASK_ID"
echo "Path: $WATCH_PATH"
echo "Events: $WATCH_EVENTS"
echo "Tool: $WATCHER_TOOL"