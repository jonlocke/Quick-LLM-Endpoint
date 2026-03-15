#!/usr/bin/env bash
set -euo pipefail

# Build a .deb for quick-llm-endpoint from local llama.cpp build artifacts.
# Uses tuned defaults discovered in go.sh.

VERSION="${1:-0.1.0}"
PKGNAME="quick-llm-endpoint"
ARCH="amd64"
ROOT="/tmp/${PKGNAME}_${VERSION}_${ARCH}"
DEB="/tmp/${PKGNAME}_${VERSION}_${ARCH}.deb"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

MODEL_FILE="${MODEL_FILE:-Qwen2.5-1.5B-Instruct-Q4_K_M.gguf}"
MODEL_SRC="models/${MODEL_FILE}"

if [[ ! -x build/bin/llama-server ]]; then
  echo "Missing build/bin/llama-server. Build first." >&2
  exit 1
fi

if [[ ! -f "$MODEL_SRC" ]]; then
  echo "Missing model file: $MODEL_SRC" >&2
  exit 1
fi

rm -rf "$ROOT"
mkdir -p "$ROOT/DEBIAN"
mkdir -p "$ROOT/opt/quick-llm-endpoint/bin"
mkdir -p "$ROOT/opt/quick-llm-endpoint/lib"
mkdir -p "$ROOT/opt/quick-llm-endpoint/models"
mkdir -p "$ROOT/etc/quick-llm-endpoint"
mkdir -p "$ROOT/lib/systemd/system"
mkdir -p "$ROOT/usr/local/bin"

install -m 0755 build/bin/llama-server "$ROOT/opt/quick-llm-endpoint/bin/llama-server"

cp -a build/bin/libllama.so* "$ROOT/opt/quick-llm-endpoint/lib/"
cp -a build/bin/libggml.so* "$ROOT/opt/quick-llm-endpoint/lib/"
cp -a build/bin/libggml-base.so* "$ROOT/opt/quick-llm-endpoint/lib/"
cp -a build/bin/libggml-cpu.so* "$ROOT/opt/quick-llm-endpoint/lib/"
cp -a build/bin/libggml-vulkan.so* "$ROOT/opt/quick-llm-endpoint/lib/"
cp -a build/bin/libmtmd.so* "$ROOT/opt/quick-llm-endpoint/lib/"

install -m 0644 "$MODEL_SRC" "$ROOT/opt/quick-llm-endpoint/models/$MODEL_FILE"

cat > "$ROOT/etc/quick-llm-endpoint/quick-llm-endpoint.env" <<ENV
MODEL=/opt/quick-llm-endpoint/models/$MODEL_FILE
HOST=0.0.0.0
PORT=10000
CTX_SIZE=1024
THREADS=2
BATCH_SIZE=8
UBATCH_SIZE=4
PARALLEL=1
N_GPU_LAYERS=999
FLASH_ATTN=1
CACHE_RAM=0
NO_WARMUP=1
ENV

cat > "$ROOT/usr/local/bin/quick-llm-endpoint" <<'LAUNCH'
#!/usr/bin/env bash
set -euo pipefail
: "${MODEL:=/opt/quick-llm-endpoint/models/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf}"
: "${HOST:=0.0.0.0}"
: "${PORT:=10000}"
: "${CTX_SIZE:=1024}"
: "${THREADS:=2}"
: "${BATCH_SIZE:=8}"
: "${UBATCH_SIZE:=4}"
: "${PARALLEL:=1}"
: "${N_GPU_LAYERS:=999}"
: "${FLASH_ATTN:=1}"
: "${CACHE_RAM:=0}"
: "${NO_WARMUP:=1}"
export LD_LIBRARY_PATH="/opt/quick-llm-endpoint/lib:${LD_LIBRARY_PATH:-}"
exec /opt/quick-llm-endpoint/bin/llama-server \
  -m "$MODEL" \
  --host "$HOST" \
  --port "$PORT" \
  --ctx-size "$CTX_SIZE" \
  --threads "$THREADS" \
  --batch-size "$BATCH_SIZE" \
  --ubatch-size "$UBATCH_SIZE" \
  --parallel "$PARALLEL" \
  --n-gpu-layers "$N_GPU_LAYERS" \
  -fa "$FLASH_ATTN" \
  --cache-ram "$CACHE_RAM" \
  $( [ "$NO_WARMUP" = "1" ] && echo --no-warmup )
LAUNCH
chmod 0755 "$ROOT/usr/local/bin/quick-llm-endpoint"

cat > "$ROOT/lib/systemd/system/quick-llm-endpoint.service" <<'UNIT'
[Unit]
Description=Quick LLM Endpoint (llama.cpp server)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=-/etc/quick-llm-endpoint/quick-llm-endpoint.env
ExecStart=/usr/local/bin/quick-llm-endpoint
Restart=on-failure
RestartSec=2
User=jonlo
Group=jonlo
WorkingDirectory=/opt/quick-llm-endpoint

[Install]
WantedBy=multi-user.target
UNIT

cat > "$ROOT/DEBIAN/control" <<CTRL
Package: $PKGNAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: Jon <jon@example.com>
Depends: libc6, libstdc++6, libgomp1
Description: Quick LLM endpoint packaged from llama.cpp build with tuned defaults
 Includes llama-server, required shared libs, and selected model.
CTRL

cat > "$ROOT/DEBIAN/postinst" <<'POST'
#!/bin/sh
set -e
systemctl daemon-reload || true
echo "Installed quick-llm-endpoint. Enable with: sudo systemctl enable --now quick-llm-endpoint"
POST
chmod 0755 "$ROOT/DEBIAN/postinst"

rm -f "$DEB"
dpkg-deb -Zgzip -z1 --build "$ROOT" "$DEB" >/dev/null

echo "Built: $DEB"
ls -lh "$DEB"
