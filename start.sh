#!/bin/bash
# Insightr — Development launcher script
#
# Usage:
#   ./start.sh              — Run both backend and frontend (Chrome)
#   ./start.sh all          — Same as above
#   ./start.sh app          — Run the production Flutter app in Chrome
#   ./start.sh backend      — Start the FastAPI backend server
#   ./start.sh prototype    — Run Phase 0 design-validation prototype (if it exists)
#
# Requirements:
#   - Flutter installed and on PATH
#   - Python 3.11+ for backend

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend/insightr_app"
BACKEND_DIR="$SCRIPT_DIR/backend"

MODE="${1:-all}"

case "$MODE" in
  all)
    echo "▶ Starting FastAPI backend server in the background..."
    cd "$BACKEND_DIR"
    if [ ! -d ".venv" ]; then
      echo "  Creating virtual environment..."
      python3 -m venv .venv
    fi
    source .venv/bin/activate
    pip install -q -r requirements.txt
    python api.py &
    BACKEND_PID=$!
    
    # Ensure backend is killed when the script exits
    trap "echo 'Stopping backend...'; kill $BACKEND_PID" EXIT
    
    # Wait for backend to spin up
    sleep 2
    
    echo "▶ Launching production Flutter app in Chrome..."
    cd "$FRONTEND_DIR"
    flutter run -d chrome --web-renderer html
    ;;

  prototype)
    echo "▶ Launching Phase 0 design-validation prototype (throwaway)..."
    echo "  This validates knowledge-network traversal before production code."
    echo ""
    cd "$FRONTEND_DIR"
    flutter run -t lib/prototype/main_prototype.dart
    ;;

  app)
    echo "▶ Launching production Flutter app in Chrome..."
    cd "$FRONTEND_DIR"
    flutter run -d chrome --web-renderer html
    ;;

  backend)
    echo "▶ Starting FastAPI backend server..."
    cd "$BACKEND_DIR"
    if [ ! -d ".venv" ]; then
      echo "  Creating virtual environment..."
      python3 -m venv .venv
    fi
    source .venv/bin/activate
    pip install -q -r requirements.txt
    echo "  Server starting on http://localhost:8000"
    python api.py
    ;;

  *)
    echo "Usage: $0 [all|app|backend|prototype]"
    exit 1
    ;;
esac
