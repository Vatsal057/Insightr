#!/bin/bash
# Insightr — Development launcher
#
# Usage:
#   ./start.sh              — Start backend + open Flutter web app in Chrome
#   ./start.sh backend      — Start only the FastAPI backend (port 8000)
#   ./start.sh frontend     — Start only the Flutter web app (port 8080)
#
# Prerequisites:
#   - Flutter installed and on PATH
#   - Python 3.11+ with .venv in backend/ (created automatically if missing)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend/insightr_app"
BACKEND_DIR="$SCRIPT_DIR/backend"

MODE="${1:-all}"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

start_backend() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🐍 Starting FastAPI backend on port 8000"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cd "$BACKEND_DIR"

  if [ ! -d ".venv" ]; then
    echo "  Creating Python virtual environment..."
    python3 -m venv .venv
  fi

  source .venv/bin/activate

  echo "  Checking dependencies..."
  pip install -q -r requirements.txt || true

  echo -e "  Backend starting at → ${GREEN}http://localhost:8000${NC}"
  echo -e "  API docs available  → ${GREEN}http://localhost:8000/docs${NC}"
  echo ""
  python api.py
}

start_frontend() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  🌐 Starting Flutter web app on port 8080"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cd "$FRONTEND_DIR"

  echo "  Getting Flutter packages..."
  flutter pub get
  if [ $? -ne 0 ]; then
    echo -e "  ${RED}❌ flutter pub get failed. Check output above.${NC}"
    exit 1
  fi

  echo -e "  App starting at → ${GREEN}http://localhost:8080${NC}"
  echo ""
  flutter run -d chrome \
    --web-port 8080 \
    --dart-define=API_BASE_URL=http://localhost:8000
}

case "$MODE" in
  all)
    echo ""
    echo "╔═══════════════════════════════════════════╗"
    echo "║           Insightr — Starting Up          ║"
    echo "╚═══════════════════════════════════════════╝"

    # ── 1. Set up and start the backend in the background ──────────────────
    cd "$BACKEND_DIR"

    if [ ! -d ".venv" ]; then
      echo "  Creating Python virtual environment..."
      python3 -m venv .venv
    fi

    source .venv/bin/activate

    echo "  Checking backend dependencies..."
    pip install -q -r requirements.txt || true

    echo "  Launching backend on http://localhost:8000 ..."
    python api.py &
    BACKEND_PID=$!

    # Kill the backend when this script exits (Ctrl+C or frontend closes)
    trap "echo ''; echo 'Stopping backend (PID $BACKEND_PID)...'; kill $BACKEND_PID 2>/dev/null; wait $BACKEND_PID 2>/dev/null; echo 'Done.'" EXIT INT TERM

    # ── 2. Wait for backend to be ready (up to 30s) ────────────────────────
    echo "  Waiting for backend to be ready..."
    READY=0
    for i in $(seq 1 30); do
      if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo -e "  ${RED}❌ Backend process crashed. Check output above.${NC}"
        exit 1
      fi
      if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null | grep -qE "^(200|404)"; then
        READY=1
        break
      fi
      sleep 1
    done

    if [ $READY -eq 0 ]; then
      echo -e "  ${YELLOW}⚠️  Backend didn't respond in 30s — starting frontend anyway.${NC}"
    else
      echo -e "  ${GREEN}✅ Backend is ready.${NC}"
    fi
    echo ""

    # ── 3. Start the Flutter web frontend (blocks until Chrome is closed) ──
    cd "$FRONTEND_DIR"

    echo "  Getting Flutter packages..."
    flutter pub get
    if [ $? -ne 0 ]; then
      echo -e "  ${RED}❌ flutter pub get failed. Check output above.${NC}"
      exit 1
    fi

    echo -e "  Launching Flutter app in Chrome → ${GREEN}http://localhost:8080${NC}"
    echo ""
    flutter run -d chrome \
      --web-port 8080 \
      --dart-define=API_BASE_URL=http://localhost:8000
    ;;

  backend)
    start_backend
    ;;

  frontend)
    start_frontend
    ;;

  app)
    # Legacy alias
    start_frontend
    ;;

  *)
    echo ""
    echo "Usage: $0 [all|backend|frontend]"
    echo ""
    echo "  all       Start backend + open Flutter web app in Chrome (default)"
    echo "  backend   Start only the FastAPI backend on port 8000"
    echo "  frontend  Start only the Flutter web app on port 8080"
    echo ""
    exit 1
    ;;
esac
