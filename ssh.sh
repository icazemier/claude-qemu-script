#!/bin/bash
# ssh.sh — SSH into the Claude Dev VM as the claude user
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROVISION_KEY="$SCRIPT_DIR/provision_key"

KEY_OPT=()
[ -f "$PROVISION_KEY" ] && KEY_OPT=(-i "$PROVISION_KEY")

ssh -p 2222 \
  "${KEY_OPT[@]}" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o LogLevel=ERROR \
  -o ConnectTimeout=10 \
  -o ServerAliveInterval=5 \
  -o ServerAliveCountMax=3 \
  claude@localhost "$@"

status=$?
if [ "$status" -ne 0 ] && [ "$status" -ne 130 ]; then
  echo ""
  echo "Cannot connect to VM. Is it running? Try: ./up.sh"
  exit "$status"
fi
