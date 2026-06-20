#!/bin/bash

# Get the absolute path of the directory containing this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "==========================================="
echo " Starting Insightr Backend & Frontend..."
echo "==========================================="

# 1. Start the FastAPI backend in a new Terminal window
echo "[1/2] Starting backend API server in a new window..."
osascript -e "tell application \"Terminal\" to do script \"cd '$SCRIPT_DIR/backend' && .venv/bin/python api.py\""

# Wait a moment for backend to initialize
sleep 2

# 2. Start the Flutter web app on Chrome
echo "[2/2] Launching Flutter app on Chrome..."
cd "$SCRIPT_DIR/frontend/insightr_app"
flutter run -d chrome
