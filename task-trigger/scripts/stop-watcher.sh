#!/bin/bash
# Stop a file/directory watcher
# Usage: ./stop-watcher.sh <task-id>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TASK_ID="$1"
if [[ -z "$TASK_ID" ]]; then
  echo "Usage: $0 <task-id>"
  exit 1
fi

WATCHERS_DIR="$HOME/.task-trigger/watchers"
WATCHER_SCRIPT="$WATCHERS_DIR/$TASK_ID.sh"

PLATFORM=$("$SCRIPT_DIR/detect-platform.sh")

echo "Stopping watcher: $TASK_ID"

# Stop based on platform
case "$PLATFORM" in
  wsl|linux)
    # Stop systemd service
    SERVICE_NAME="task-trigger-$TASK_ID.service"
    
    if systemctl --user list-units --full -all | grep -q "$SERVICE_NAME"; then
      echo "Stopping systemd service..."
      systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
      systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
      
      SERVICE_FILE="$HOME/.config/systemd/user/$SERVICE_NAME"
      if [[ -f "$SERVICE_FILE" ]]; then
        rm -f "$SERVICE_FILE"
      fi
      
      systemctl --user daemon-reload
    fi
    ;;
  
  macos)
    # Stop launchd job
    PLIST_FILE="$HOME/Library/LaunchAgents/com.task-trigger.$TASK_ID.plist"
    
    if [[ -f "$PLIST_FILE" ]]; then
      echo "Stopping launchd job..."
      launchctl unload "$PLIST_FILE" 2>/dev/null || true
      rm -f "$PLIST_FILE"
    fi
    ;;
esac

# Kill any running watcher process
if [[ -f "$WATCHER_SCRIPT" ]]; then
  echo "Killing watcher process..."
  pkill -f "$WATCHER_SCRIPT" 2>/dev/null || true
  rm -f "$WATCHER_SCRIPT"
fi

echo "Watcher stopped: $TASK_ID"