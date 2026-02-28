#!/bin/bash
# destroy.sh — Remove the Claude Dev VM and all generated artifacts
# The cached base image is kept by default (saves re-downloading ~600 MB).
# Pass --all to also remove the base image.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

ALL=false
for arg in "$@"; do
  [ "$arg" = "--all" ] && ALL=true
done

# ─── Stop VM if running ───────────────────────────────────────────────────────
if [ -f vm.pid ]; then
  PID=$(cat vm.pid)
  if kill -0 "$PID" 2>/dev/null; then
    echo "==> VM is running — shutting down first..."
    ./stop.sh
  else
    rm -f vm.pid qemu-monitor.sock
  fi
fi

# ─── Remove VM artifacts ──────────────────────────────────────────────────────
echo "==> Removing VM disk and generated files..."
rm -f disk.qcow2 disk.qcow2.initialized cloud-init.iso cloud-init/user-data
rm -f qemu-monitor.sock vm.pid

# ─── Optionally remove cached base image ─────────────────────────────────────
if $ALL; then
  echo "==> Removing cached base image (images/)..."
  rm -rf images/
  echo ""
  echo "Done. Everything removed. Next ./up.sh will re-download the base image."
else
  echo ""
  echo "Done. VM removed (base image kept in images/ for fast rebuild)."
  echo ""
  echo "  Rebuild:       ./up.sh"
  echo "  Remove image:  $0 --all"
fi
