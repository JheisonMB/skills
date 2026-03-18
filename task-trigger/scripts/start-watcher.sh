#!/bin/bash
# Start a file/directory watcher
# Usage: ./start-watcher.sh --task-id <id> --path <path> --events <events> --command <command>
#        [--recursive true|false] [--poll-interval N] [--debounce N] [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK_ID=""
WATCH_PATH=""
WATCH_EVENTS=""
COMMAND=""
RECURSIVE="false"
POLL_INTERVAL=5
DEBOUNCE=1
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --task-id)     TASK_ID="$2";       shift 2 ;;
    --path)        WATCH_PATH="$2";    shift 2 ;;
    --events)      WATCH_EVENTS="$2";  shift 2 ;;
    --command)     COMMAND="$2";       shift 2 ;;
    --recursive)   RECURSIVE="$2";    shift 2 ;;
    --poll-interval) POLL_INTERVAL="$2"; shift 2 ;;
    --debounce)    DEBOUNCE="$2";     shift 2 ;;
    --dry-run)     DRY_RUN=true;      shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "$TASK_ID" || -z "$WATCH_PATH" || -z "$WATCH_EVENTS" || -z "$COMMAND" ]]; then
  echo "Error: Missing required arguments"
  echo "Usage: $0 --task-id <id> --path <path> --events <events> --command <command>"
  exit 1
fi

# Bug 2: Detect if path is file or directory
IS_FILE=false
IS_DIR=false
if [[ -f "$WATCH_PATH" ]]; then
  IS_FILE=true
elif [[ -d "$WATCH_PATH" ]]; then
  IS_DIR=true
else
  echo "Error: Path does not exist: $WATCH_PATH"
  exit 1
fi

WATCHERS_DIR="$HOME/.task-trigger/watchers"
mkdir -p "$WATCHERS_DIR"

WATCHER_TOOL=$("$SCRIPT_DIR/detect-watcher.sh")
WATCHER_SCRIPT="$WATCHERS_DIR/$TASK_ID.sh"
PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

# Bug 8: Dry-run mode
if [[ "$DRY_RUN" == true ]]; then
  echo "=== DRY RUN ==="
  echo "Task ID:    $TASK_ID"
  echo "Path:       $WATCH_PATH ($([ "$IS_FILE" = true ] && echo "file" || echo "directory"))"
  echo "Events:     $WATCH_EVENTS"
  echo "Tool:       $WATCHER_TOOL"
  echo "Platform:   $PLATFORM"
  echo "Recursive:  $RECURSIVE"
  echo "Debounce:   ${DEBOUNCE}s"
  echo "Command:    $COMMAND"
  echo ""
  echo "Would create: $WATCHER_SCRIPT"
  if [[ "$PLATFORM" == "macos" ]]; then
    echo "Would create: $HOME/Library/LaunchAgents/com.task-trigger.$TASK_ID.plist"
  else
    echo "Would create: $HOME/.config/systemd/user/task-trigger-$TASK_ID.service"
  fi
  echo "=== No changes made ==="
  exit 0
fi

case "$WATCHER_TOOL" in
  inotifywait)
    IFS=',' read -ra EVENTS <<< "$WATCH_EVENTS"
    INOTIFY_EVENTS=""
    for event in "${EVENTS[@]}"; do
      case "$event" in
        create) INOTIFY_EVENTS+="create," ;;
        modify) INOTIFY_EVENTS+="modify," ;;
        delete) INOTIFY_EVENTS+="delete," ;;
        move)   INOTIFY_EVENTS+="moved_to,moved_from," ;;
        *) echo "Unknown event: $event" >&2; exit 1 ;;
      esac
    done
    INOTIFY_EVENTS="${INOTIFY_EVENTS%,}"

    RECURSIVE_FLAG=""
    if [[ "$RECURSIVE" == "true" && "$IS_DIR" == true ]]; then
      RECURSIVE_FLAG="-r"
    fi

    cat > "$WATCHER_SCRIPT" << 'WATCHER_EOF'
#!/bin/bash
set -e
LAST_RUN_FILE=$(mktemp)
echo 0 > "$LAST_RUN_FILE"
trap "rm -f $LAST_RUN_FILE" EXIT

inotifywait __RECURSIVE_FLAG__ -m -e "__INOTIFY_EVENTS__" --format '%w%f %e' "__WATCH_PATH__" | while read FILE EVENT
do
  CURRENT_TIME=$(date +%s)
  LAST_RUN=$(cat "$LAST_RUN_FILE")
  if [[ $((CURRENT_TIME - LAST_RUN)) -ge __DEBOUNCE__ ]]; then
    echo "[Watcher] File changed: $FILE ($EVENT)"
    bash -c "__COMMAND__"
    echo $CURRENT_TIME > "$LAST_RUN_FILE"
  fi
done
WATCHER_EOF
    sed -i.bak \
      -e "s|__RECURSIVE_FLAG__|$RECURSIVE_FLAG|g" \
      -e "s|__INOTIFY_EVENTS__|$INOTIFY_EVENTS|g" \
      -e "s|__WATCH_PATH__|$WATCH_PATH|g" \
      -e "s|__DEBOUNCE__|$DEBOUNCE|g" \
      -e "s|__COMMAND__|$COMMAND|g" \
      "$WATCHER_SCRIPT"
    rm -f "${WATCHER_SCRIPT}.bak"
    ;;

  fswatch)
    cat > "$WATCHER_SCRIPT" << 'WATCHER_EOF'
#!/bin/bash
set -e
LAST_RUN_FILE=$(mktemp)
echo 0 > "$LAST_RUN_FILE"
trap "rm -f $LAST_RUN_FILE" EXIT

fswatch -x "__WATCH_PATH__" | while read FILE EVENT
do
  CURRENT_TIME=$(date +%s)
  LAST_RUN=$(cat "$LAST_RUN_FILE")
  if [[ $((CURRENT_TIME - LAST_RUN)) -ge __DEBOUNCE__ ]]; then
    echo "[Watcher] File changed: $FILE ($EVENT)"
    bash -c "__COMMAND__"
    echo $CURRENT_TIME > "$LAST_RUN_FILE"
  fi
done
WATCHER_EOF
    sed -i.bak \
      -e "s|__WATCH_PATH__|$WATCH_PATH|g" \
      -e "s|__DEBOUNCE__|$DEBOUNCE|g" \
      -e "s|__COMMAND__|$COMMAND|g" \
      "$WATCHER_SCRIPT"
    rm -f "${WATCHER_SCRIPT}.bak"
    ;;

  polling)
    # Bug 1: No declare -A — use temp dir for state files (bash 3.2 compatible)
    # Bug 2: Handle single file vs directory
    cat > "$WATCHER_SCRIPT" << 'WATCHER_EOF'
#!/bin/bash
set -e

get_mtime() {
  stat -f "%m %z" "$1" 2>/dev/null || stat -c "%Y %s" "$1" 2>/dev/null || echo "0 0"
}

LAST_RUN_FILE=$(mktemp)
STATE_DIR=$(mktemp -d)
echo 0 > "$LAST_RUN_FILE"
trap "rm -f $LAST_RUN_FILE; rm -rf $STATE_DIR" EXIT

POLL_INTERVAL=__POLL_INTERVAL__
IS_SINGLE_FILE=__IS_FILE__

file_state_key() {
  echo "$STATE_DIR/$(echo "$1" | md5sum 2>/dev/null | cut -d' ' -f1 || md5 -q -s "$1" 2>/dev/null || echo "$1" | shasum | cut -d' ' -f1)"
}

save_state() {
  local KEY
  KEY=$(file_state_key "$1")
  get_mtime "$1" > "$KEY"
}

get_state() {
  local KEY
  KEY=$(file_state_key "$1")
  cat "$KEY" 2>/dev/null || echo ""
}

scan_files() {
  if [[ "$IS_SINGLE_FILE" == "true" ]]; then
    echo "__WATCH_PATH__"
  elif [[ "__RECURSIVE__" == "true" ]]; then
    find "__WATCH_PATH__" -type f 2>/dev/null
  else
    for F in "__WATCH_PATH__"/*; do
      [[ -f "$F" ]] && echo "$F"
    done
  fi
}

# Initial scan
while IFS= read -r FILE; do
  save_state "$FILE"
done < <(scan_files)

while true; do
  sleep $POLL_INTERVAL
  while IFS= read -r FILE; do
    CURRENT_STAT="$(get_mtime "$FILE")"
    OLD_STAT="$(get_state "$FILE")"
    if [[ "$CURRENT_STAT" != "$OLD_STAT" ]]; then
      CURRENT_TIME=$(date +%s)
      LAST_RUN=$(cat "$LAST_RUN_FILE")
      if [[ $((CURRENT_TIME - LAST_RUN)) -ge __DEBOUNCE__ ]]; then
        echo "[Watcher] File changed: $FILE"
        bash -c "__COMMAND__"
        echo $CURRENT_TIME > "$LAST_RUN_FILE"
      fi
      save_state "$FILE"
    fi
  done < <(scan_files)
done
WATCHER_EOF
    sed -i.bak \
      -e "s|__WATCH_PATH__|$WATCH_PATH|g" \
      -e "s|__RECURSIVE__|$RECURSIVE|g" \
      -e "s|__POLL_INTERVAL__|$POLL_INTERVAL|g" \
      -e "s|__DEBOUNCE__|$DEBOUNCE|g" \
      -e "s|__COMMAND__|$COMMAND|g" \
      -e "s|__IS_FILE__|$IS_FILE|g" \
      "$WATCHER_SCRIPT"
    rm -f "${WATCHER_SCRIPT}.bak"
    ;;

  *)
    echo "No file monitoring tool available"
    exit 1
    ;;
esac

# Bug 6: Ensure script is executable
chmod +x "$WATCHER_SCRIPT"

# Use clean PATH for launchd/systemd (don't capture shell's PATH)
CLEAN_PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

case "$PLATFORM" in
  wsl|linux)
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
Environment=PATH=$CLEAN_PATH

[Install]
WantedBy=default.target
EOF

    echo "Systemd service created: $SERVICE_FILE"
    echo "To enable: systemctl --user enable task-trigger-$TASK_ID.service"
    echo "To start: systemctl --user start task-trigger-$TASK_ID.service"
    ;;

  macos)
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
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$CLEAN_PATH</string>
  </dict>
</dict>
</plist>
EOF

    echo "Launchd plist created: $PLIST_FILE"
    # Auto-load the plist
    LABEL="com.task-trigger.$TASK_ID"
    if launchctl list "$LABEL" &>/dev/null; then
      launchctl remove "$LABEL" 2>/dev/null || launchctl unload "$PLIST_FILE" 2>/dev/null || true
    fi
    launchctl load "$PLIST_FILE"
    echo "Launchd job loaded for watcher: $TASK_ID"
    ;;
esac

echo "Watcher created for task: $TASK_ID"
echo "Path: $WATCH_PATH ($([ "$IS_FILE" = true ] && echo "file" || echo "directory"))"
echo "Events: $WATCH_EVENTS"
echo "Tool: $WATCHER_TOOL"
