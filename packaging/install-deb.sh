#!/usr/bin/env bash
set -euo pipefail

DEB_PATH="${1:-/tmp/quick-llm-endpoint_0.1.0_amd64.deb}"

if [[ ! -f "$DEB_PATH" ]]; then
  echo "Deb not found: $DEB_PATH" >&2
  exit 1
fi

sudo dpkg -i "$DEB_PATH"
sudo systemctl daemon-reload
sudo systemctl enable --now quick-llm-endpoint

sleep 2
systemctl --no-pager --full status quick-llm-endpoint | sed -n '1,40p'
echo "Health check:"
curl -sS --max-time 120 http://127.0.0.1:10000/health || true
