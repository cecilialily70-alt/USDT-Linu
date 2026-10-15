#!/bin/sh
cd "$(dirname "$0")"
export ENV=production
PORT="${PORT:-8000}"
exec python -m uvicorn server:app --host 127.0.0.1 --port "$PORT" --workers 1
