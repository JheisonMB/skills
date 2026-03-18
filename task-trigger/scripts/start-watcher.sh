#!/bin/bash
# Start a file/directory watcher
# Usage: ./start-watcher.sh --task-id <id> --path <path> --events <events> --command <command>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
WATCHER_TOOL=$("$SCRIPT_DIR/detect-watcher.sh")

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
    
    cat > "$WATCHER_SCRIPT" << 'WATCHER_EOF'
#!/bin/bash
set -e

LAST_RUN_FILE=$(mktemp)
echo 0 > "$LAST_RUN_FILE"
trap "rm -f $LAST_RUN_FILE" EXIT

inotifywait RECURSIVE_FLAG_PLACEHOLDER -m -e "INOTIFY_EVENTS_PLACEHOLDER" --format '%w%f %e' "WATCH_PATH_PLACEHOLDER" | while read FILE EVENT
do
  CURRENT_TIME=$(date +%s)
  LAST_RUN=$(cat "$LAST_RUN_FILE")
  if [[ $((CURRENT_TIME - LAST_RUN)) -ge DEBOUNCE_PLACEHOLDER ]]; then
    echo "[Watcher] File changed: $FILE ($EVENT)"
    bash -c "COMMAND_PLACEHOLDER"
    echo $CURRENT_TIME > "$LAST_RUN_FILE"
  fi
done
WATCHER_EOF
    # Replace placeholders
    RECURSIVE_FLAG=""
    if [[ "$RECURSIVE" == "true" ]]; then
      RECURSIVE_FLAG="-r"
    fi
    sed -i.bak \
      -e "s|RECURSIVE_FLAG_PLACEHOLDER|$RECURSIVE_FLAG|g" \
      -e "s|INOTIFY_EVENTS_PLACEHOLDER|$INOTIFY_EVENTS|g" \
      -e "s|WATCH_PATH_PLACEHOLDER|$WATCH_PATH|g" \
      -e "s|DEBOUNCE_PLACEHOLDER|$DEBOUNCE|g" \
      -e "s|COMMAND_PLACEHOLDER|$COMMAND|g" \
      "$WATCHER_SCRIPT"
    rm -f "${WATCHER_SCRIPT}.bak"
    ;;
  
  fswatch)
    # fswatch events mapping (macOS) — fswatch outputs: path flags
    cat > "$WATCHER_SCRIPT" << 'WATCHER_EOF'
#!/bin/bash
set -e

LAST_RUN_FILE=$(mktemp)
echo 0 > "$LAST_RUN_FILE"
trap "rm -f $LAST_RUN_FILE" EXIT

fswatch -x "WATCH_PATH_PLACEHOLDER" | while read FILE EVENT
do
  CURRENT_TIME=$(date +%s)
  LAST_RUN=$(cat "$LAST_RUN_FILE")
  if [[ $((CURRENT_TIME - LAST_RUN)) -ge DEBOUNCE_PLACEHOLDER ]]; then
    echo "[Watcher] File changed: $FILE ($EVENT)"
    bash -c "COMMAND_PLACEHOLDER"
    echo $CURRENT_TIME > "$LAST_RUN_FILE"
  fi
done
WATCHER_EOF
    sed -i.bak \
      -e "s|WATCH_PATH_PLACEHOLDER|$WATCH_PATH|g" \
      -e "s|DEBOUNCE_PLACEHOLDER|$DEBOUNCE|g" \
      -e "s|COMMAND_PLACEHOLDER|$COMMAND|g" \
      "$WATCHER_SCRIPT"
    rm -f "${WATCHER_SCRIPT}.bak"
    ;;
  
  polling)
    # Polling with find and stat (cross-platform stat)
    cat > "$WATCHER_SCRIPT" << 'WATCHER_EOF'
#!/bin/bash
set -e

# Cross-platform stat for modification time
get_mtime() {
  stat -f "%m %z" "$1" 2>/dev/null || stat -c "%Y %s" "$1" 2>/dev/null || echo "0 0"
}

LAST_RUN_FILE=$(mktemp)
echo 0 > "$LAST_RUN_FILE"
trap "rm -f $LAST_RUN_FILE" EXIT

declare -A FILE_STATES
POLL_INTERVAL=POLL_INTERVAL_PLACEHOLDER

# Initial scan
if [[ "RECURSIVE_PLACEHOLDER" == "true" ]]; then
  while IFS= read -r FILE; do
    FILE_STATES["$FILE"]="$(get_mtime "$FILE")"
  done < <(find "WATCH_PATH_PLACEHOLDER" -type f 2>/dev/null)
else
  for FILE in "WATCH_PATH_PLACEHOLDER"/*; do
    [[ -f "$FILE" ]] && FILE_STATES["$FILE"]="$(get_mtime "$FILE")"
  done
fi

while true; do
  sleep $POLL_INTERVAL

  check_file() {
    local FILE="$1"
    local CURRENT_STAT
    CURRENT_STAT="$(get_mtime "$FILE")"
    local OLD_STAT="${FILE_STATES[$FILE]}"

    if [[ "$CURRENT_STAT" != "$OLD_STAT" ]]; then
      local CURRENT_TIME
      CURRENT_TIME=$(date +%s)
      local LAST_RUN
      LAST_RUN=$(cat "$LAST_RUN_FILE")
      if [[ $((CURRENT_TIME - LAST_RUN)) -ge DEBOUNCE_PLACEHOLDER ]]; then
        echo "[Watcher] File changed: $FILE"
        bash -c "COMMAND_PLACEHOLDER"
        echo $CURRENT_TIME > "$LAST_RUN_FILE"
      fi
      FILE_STATES["$FILE"]="$CURRENT_STAT"
    fi
  }

  if [[ "RECURSIVE_PLACEHOLDER" == "true" ]]; then
    while IFS= read -r FILE; do
      check_file "$FILE"
    done < <(find "WATCH_PATH_PLACEHOLDER" -type f 2>/dev/null)
  else
    for FILE in "WATCH_PATH_PLACEHOLDER"/*; do
      [[ -f "$FILE" ]] && check_file "$FILE"
    done
  fi
done
WATCHER_EOF
    sed -i.bak \
      -e "s|WATCH_PATH_PLACEHOLDER|$WATCH_PATH|g" \
      -e "s|RECURSIVE_PLACEHOLDER|$RECURSIVE|g" \
      -e "s|POLL_INTERVAL_PLACEHOLDER|$POLL_INTERVAL|g" \
      -e "s|DEBOUNCE_PLACEHOLDER|$DEBOUNCE|g" \
      -e "s|COMMAND_PLACEHOLDER|$COMMAND|g" \
      "$WATCHER_SCRIPT"
    rm -f "${WATCHER_SCRIPT}.bak"
    ;;
  
  *)
    echo "No file monitoring tool available"
    exit 1
    ;;
esac

chmod +x "$WATCHER_SCRIPT"

# Create systemd service or launchd plist for persistence
PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

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