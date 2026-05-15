#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$(cd "$ROOT_DIR/../bus_api" && pwd)"

echo "[1/5] Flutter dependencies"
cd "$ROOT_DIR"
flutter pub get

echo "[2/5] Flutter static analysis"
flutter analyze

echo "[3/5] Flutter web build"
flutter build web

echo "[4/5] Verifying local CanvasKit bootstrap"
grep -q 'canvasKitBaseUrl: "canvaskit/"' "$ROOT_DIR/build/web/flutter_bootstrap.js"

echo "[5/5] Django checks"
cd "$BACKEND_DIR"
./venv/bin/python manage.py check

echo
echo "Health check passed."
echo "Flutter web build is current and configured to use local CanvasKit."
