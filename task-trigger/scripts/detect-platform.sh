#!/bin/bash
# Detect operating system platform
# Outputs: wsl, macos, or linux

set -e

if uname -r | grep -q microsoft; then
  echo "wsl"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macos"
else
  echo "linux"
fi