#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$(cd "$ROOT_DIR/../bus_api" && pwd)"

"$ROOT_DIR/scripts/health_check.sh"

cd "$BACKEND_DIR"
exec ./venv/bin/python manage.py runserver 127.0.0.1:8000
