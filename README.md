# ROCmFP4

ROCmFP4 is an experimental GGUF quantization and backend integration package
for AMD ROCm and Vulkan llama.cpp builds.

This repository is the clean integration package. The full reference fork lives
at `charlie12345/rocmfp4-llama` and remains useful when you want a buildable
llama.cpp tree with the ROCmFP4 patches already applied.

For a complete Strix Halo install path, see
`docs/STRIX-HALO-QUICKSTART.md`.

## What It Adds

- `Q4_0_ROCMFP4`: dual-scale 4-bit Codebook10 layout at 4.50 BPW.
- `Q4_0_ROCMFP4_FAST`: single-scale speed layout at 4.25 BPW.
- Tensor-aware STRIX presets for quality/speed experiments.
- CPU reference quantize, dequantize, validation, and fallback vec-dot paths.
- ROCm/HIP backend decode, copy, FlashAttention, MMVQ, MMQ, get-rows, and set-rows hooks.
- Vulkan shader and routing support for ROCmFP4 decode, matmul, attention, and copy paths.
- Regression guards for quantization, ROCm, Vulkan, and MTP decode.

ROCmFP4 is not MXFP4, NVFP4, or a renamed Q4 format. It uses packed 4-bit
Codebook10 values:

`0, +/-1, +/-2, +/-3, +/-4, +/-6, +/-8, +/-10`

Those values are paired with finite unsigned E4M3 half-scales. The dual-scale
layout stores one scale per 16-value half block; the FAST layout stores one
scale per 32-value block.

## Current Status

Experimental, Strix Halo focused, and not upstream llama.cpp. The reference
implementation has been tested on:

`Framework AMD Strix Halo 395+, 128 GB unified RAM`

Known promoted reference results are tracked in:

- `docs/IMPLEMENTATION-NOTES.md`
- `docs/ROCmFP4-MTP-COMPARISON.md`
- `docs/ROCmFP4-REPRODUCIBILITY.md`

## Repository Layout

- `rocmfp4/` - ROCmFP4-owned format source and HIP helper headers.
- `patches/0001-add-rocmfp4-to-llama-cpp-mtp.patch` - integration patch for the matching llama.cpp MTP base.
- `scripts/apply-rocmfp4.sh` - helper to apply the patch to a llama.cpp checkout.
- `scripts/build-strix-rocmfp4-mtp.sh` - reference Strix Halo build script after patching.
- `scripts/check-rocmfp4-*.sh` - focused regression guards after patching.
- `docs/` - implementation notes, reproducibility notes, and benchmark history.

## Apply To llama.cpp

Use a llama.cpp checkout that is close to the MTP base used by the reference
fork. The easiest route for most users is the full ready-to-build fork:

```bash
git clone https://github.com/charlie12345/rocmfp4-llama.git
cd rocmfp4-llama
git checkout mtp-rocmfp4-strix
env JOBS=16 scripts/build-strix-rocmfp4-mtp.sh
```

Use this standalone package when you want to apply the ROCmFP4 patch yourself.
The reproducible patch base is published as the
`mtp-base-for-rocmfp4` branch in the reference fork:

```bash
git clone https://github.com/charlie12345/rocmfp4-llama.git llama.cpp-rocmfp4
cd llama.cpp-rocmfp4
git checkout mtp-base-for-rocmfp4
cd ..

git clone https://github.com/charlie12345/rocmfp4.git
cd rocmfp4
scripts/apply-rocmfp4.sh ../llama.cpp-rocmfp4
cd ../llama.cpp-rocmfp4
```

The helper runs `git apply --check` first. If the base has drifted, resolve the
patch conflicts in the llama.cpp checkout and rerun the relevant build/tests.
Both reference repositories are public, so Strix Halo users can clone either
the ready-to-build fork or this standalone package directly.

## Build On Strix Halo

After applying the patch:

```bash
cd /path/to/llama.cpp
env JOBS=16 scripts/build-strix-rocmfp4-mtp.sh
```

The build enables ROCm/HIP and Vulkan, disables NVIDIA CUDA, and builds:

- `llama-cli`
- `llama-quantize`
- `llama-bench`
- `test-backend-ops`
- `test-quantize-fns`
- `test-quantize-perf`

## Quantize

Quantize from BF16/F16 sources when evaluating real quality:

```bash
./build-strix-rocmfp4/bin/llama-quantize \
  /path/to/source-bf16.gguf \
  /path/to/model-ROCmFP4-STRIX_LEAN.gguf \
  Q4_0_ROCMFP4_STRIX_LEAN
```

Direct type examples:

```bash
./build-strix-rocmfp4/bin/llama-quantize source.gguf out-dual.gguf Q4_0_ROCMFP4
./build-strix-rocmfp4/bin/llama-quantize source.gguf out-fast.gguf Q4_0_ROCMFP4_FAST
```

## Run

Example interactive ROCm run:

```bash
HSA_OVERRIDE_GFX_VERSION=11.5.1 \
GGML_HIP_ENABLE_UNIFIED_MEMORY=1 \
./build-strix-rocmfp4/bin/llama-cli \
  -m /path/to/model-ROCmFP4-STRIX_LEAN.gguf \
  -dev ROCm0 \
  -ngl 999 \
  -c 262144 \
  -fa on \
  -ctk q4_0 \
  -ctv q4_0 \
  --jinja \
  -if
```

For MTP-capable models, add the same `--spec-*` flags used in
`scripts/check-rocmfp4-qwen-mtp-regression.sh`.

## Validate

```bash
cd /path/to/llama.cpp
env HSA_OVERRIDE_GFX_VERSION=11.5.1 scripts/check-rocmfp4-all-regression.sh
```

Use the focused guards while iterating:

```bash
scripts/check-rocmfp4-quant-regression.sh
scripts/check-rocmfp4-rocm-runtime-regression.sh
scripts/check-rocmfp4-rocm-fattn-regression.sh
scripts/check-rocmfp4-vulkan-runtime-regression.sh
scripts/check-rocmfp4-qwen-mtp-regression.sh
```

## License

MIT. See `LICENSE` and `NOTICE.md`.

This package includes code and patches based on llama.cpp/ggml, which is MIT
licensed. No model weights, API keys, tokens, or private credentials are
included.
