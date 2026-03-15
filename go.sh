#!/usr/bin/env bash
set -euo pipefail
export LD_LIBRARY_PATH="$PWD/build/bin:${LD_LIBRARY_PATH:-}"
unset GGML_VK_DISABLE
MODEL="Qwen2.5-1.5B-Instruct-Q4_K_M.gguf" # Works good
#MODEL="Qwen3.5-4B-Q4_K_M.gguf" # Too big..
#MODEL="Qwen3.5-2B-Q4_K_M.gguf"

exec ./build/bin/llama-server \
  -m "models/$MODEL" \
  --host 0.0.0.0 \
  --port 10000 \
  --ctx-size 1024 \
  --threads 2 \
  --batch-size 8 \
  --ubatch-size 4 \
  --parallel 1 \
  --n-gpu-layers 999 \
  -fa 1 \
  --cache-ram 0 \
  --no-warmup
