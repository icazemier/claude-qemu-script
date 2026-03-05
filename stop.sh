#!/bin/bash
# stop.sh — Gracefully shut down the Claude Dev VM
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f vm.pid ]; then
  echo "VM is not running (vm.pid not found)"
  exit 0
fi

PID=$(cat vm.pid)

if ! kill -0 "$PID" 2>/dev/null; then
  echo "VM is not running (stale vm.pid, cleaning up)"
  rm -f vm.pid qemu-monitor.sock
  exit 0
fi

if [ -S qemu-monitor.sock ]; then
  echo "==> Sending shutdown signal via QEMU monitor..."
  python3 - 2>/dev/null <<'EOF' || { echo "Monitor unresponsive, sending SIGTERM..."; kill "$PID"; }
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5)
try:
    s.connect('qemu-monitor.sock')
    s.recv(4096)          # drain QEMU banner + "(qemu) " prompt
    s.sendall(b'system_powerdown\n')
except Exception as e:
    print(f'monitor error: {e}', file=sys.stderr)
    sys.exit(1)
finally:
    s.close()
EOF
else
  echo "==> Monitor socket not found, sending SIGTERM..."
  kill "$PID"
fi

TIMEOUT=60
ELAPSED=0
while kill -0 "$PID" 2>/dev/null; do
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo ""
    echo "Timed out waiting for graceful shutdown, killing..."
    kill -9 "$PID" 2>/dev/null || true
    break
  fi
  printf "\r==> Waiting for VM to stop... (%ds)" "$ELAPSED"
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
printf "\r==> Waiting for VM to stop... done.    \n"

rm -f vm.pid qemu-monitor.sock
echo "VM stopped."
