#!/bin/bash
# Insightr — Development launcher script
#
# Usage:
#   ./start.sh              — Run Phase 0 design-validation prototype (throwaway)
#   ./start.sh prototype    — Same as above
#   ./start.sh app          — Run the production Flutter app (coming soon)
#   ./start.sh backend      — Start the FastAPI backend server
#
# Requirements:
#   - Flutter installed and on PATH
#   - Python 3.11+ for backend

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend/insightr_app"
BACKEND_DIR="$SCRIPT_DIR/backend"

MODE="${1:-prototype}"

case "$MODE" in
  prototype)
    echo "▶ Launching Phase 0 design-validation prototype (throwaway)..."
    echo "  This validates knowledge-network traversal before production code."
    echo ""
    cd "$FRONTEND_DIR"
    flutter run -t lib/prototype/main_prototype.dart
    ;;

  app)
    echo "▶ Launching production Flutter app..."
    echo "  (Not yet implemented — run 'flutter run' manually after Task 1+)"
    cd "$FRONTEND_DIR"
    flutter run
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
    echo "Usage: $0 [prototype|app|backend]"
    exit 1
    ;;
esac
