# Strix Halo Quickstart

Use this repository when you want the clean ROCmFP4 patch package, not the full
llama.cpp fork. It is useful for reviewing the ROCmFP4 changes, carrying them
into another llama.cpp tree, or rebasing the format onto a newer base.

For the easiest path, use the ready fork instead:

```bash
git clone https://github.com/charlie12345/rocmfp4-llama.git
cd rocmfp4-llama
git checkout mtp-rocmfp4-strix
env JOBS=16 scripts/build-strix-rocmfp4-mtp.sh
```

Standalone package repository:

```bash
git clone https://github.com/charlie12345/rocmfp4.git
cd rocmfp4
```

If either repository is private, public users cannot clone it from a Twitter
link. Make the repositories public or invite collaborators before sharing.

## Target Hardware

The reference proof target is:

```text
Framework AMD Strix Halo 395+, 128 GB unified RAM, gfx1151
```

Other AMD systems may work, but benchmark claims should be treated as unproven
until rerun on that hardware.

## Patch A llama.cpp Checkout

The patch is generated against the same MTP base used by
`charlie12345/rocmfp4-llama`. The exact patch base is published as
`mtp-base-for-rocmfp4` in that reference fork. If the patch does not apply
cleanly to upstream `llama.cpp`, use the full fork or rebase the patch manually.

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

The helper runs `git apply --check` before applying the patch.

## Build

```bash
env JOBS=16 scripts/build-strix-rocmfp4-mtp.sh
```

The build script enables ROCm/HIP and Vulkan, disables NVIDIA CUDA, targets
`gfx1151`, and writes binaries under:

```text
build-strix-rocmfp4/bin/
```

## Quantize A Model

Start from an F16 or BF16 GGUF source for meaningful quality testing:

```bash
./build-strix-rocmfp4/bin/llama-quantize \
  /path/to/source-bf16.gguf \
  /path/to/model-ROCmFP4-STRIX_LEAN.gguf \
  Q4_0_ROCMFP4_STRIX_LEAN
```

Other exposed formats:

```bash
./build-strix-rocmfp4/bin/llama-quantize source.gguf out-strix.gguf Q4_0_ROCMFP4_STRIX
./build-strix-rocmfp4/bin/llama-quantize source.gguf out-dual.gguf Q4_0_ROCMFP4
./build-strix-rocmfp4/bin/llama-quantize source.gguf out-fast.gguf Q4_0_ROCMFP4_FAST
```

## Run Interactive ROCm

```bash
HSA_OVERRIDE_GFX_VERSION=11.5.1 \
GGML_HIP_ENABLE_UNIFIED_MEMORY=1 \
./build-strix-rocmfp4/bin/llama-cli \
  -m /path/to/model-ROCmFP4-STRIX_LEAN.gguf \
  -dev ROCm0 \
  -ngl 999 \
  -c 262144 \
  -b 512 \
  -ub 512 \
  -fa on \
  -ctk q8_0 \
  -ctv q8_0 \
  --jinja \
  -if
```

For MTP-capable models:

```bash
HSA_OVERRIDE_GFX_VERSION=11.5.1 \
GGML_HIP_ENABLE_UNIFIED_MEMORY=1 \
./build-strix-rocmfp4/bin/llama-cli \
  -m /path/to/model-ROCmFP4-STRIX_LEAN.gguf \
  -dev ROCm0 \
  -ngl 999 \
  -c 262144 \
  -b 512 \
  -ub 512 \
  -fa on \
  -ctk q8_0 \
  -ctv q8_0 \
  --spec-type draft-mtp \
  --spec-draft-n-max 4 \
  --spec-draft-n-min 0 \
  --spec-draft-p-min 0.0 \
  --spec-draft-p-split 0.10 \
  --spec-draft-type-k q4_0 \
  --spec-draft-type-v q4_0 \
  --jinja \
  -if
```

Remove the `--spec-*` flags for non-MTP models. Add `--reasoning on` only when
the model and chat template support reasoning.

## Validate

```bash
env HSA_OVERRIDE_GFX_VERSION=11.5.1 scripts/check-rocmfp4-all-regression.sh
```

Focused checks:

```bash
scripts/check-rocmfp4-quant-regression.sh
scripts/check-rocmfp4-rocm-runtime-regression.sh
scripts/check-rocmfp4-rocm-fattn-regression.sh
scripts/check-rocmfp4-vulkan-runtime-regression.sh
scripts/check-rocmfp4-qwen-mtp-regression.sh
```

Override `MODEL`, `ROCMFP4_MODEL`, or `BASELINE_MODEL` if your model paths do
not match the script defaults.

## Notes For Public Users

- No model weights are included. Download weights separately and respect each
  model license.
- ROCmFP4 is experimental and not upstream llama.cpp.
- The HIP backend lives in llama.cpp paths named `ggml-cuda`; this is upstream
  naming for shared CUDA/HIP code, not NVIDIA CUDA usage in this build.
- Published benchmark numbers should cite model, quant, context, backend, flags,
  hardware, date, and commit.
