Quick LLM Endpoint packaging

Files
- build-deb.sh: builds /tmp/quick-llm-endpoint_<version>_amd64.deb
- install-deb.sh: installs deb and enables service

Defaults used (from tuned go.sh)
- MODEL=Qwen2.5-1.5B-Instruct-Q4_K_M.gguf
- HOST=0.0.0.0
- PORT=10000
- CTX_SIZE=1024
- THREADS=2
- BATCH_SIZE=8
- UBATCH_SIZE=4
- PARALLEL=1
- N_GPU_LAYERS=999
- FLASH_ATTN=1
- CACHE_RAM=0
- NO_WARMUP=1

Usage
1) Build
   cd ~/Quick-LLM-Endpoint
   ./packaging/build-deb.sh 0.1.1

2) Install
   ./packaging/install-deb.sh /tmp/quick-llm-endpoint_0.1.1_amd64.deb

Optional model override at build time
   MODEL_FILE=Qwen2.5-3B-Instruct-Q4_K_M.gguf ./packaging/build-deb.sh 0.1.2
