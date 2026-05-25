# ROCmFP4 Specification v1.2-codebook10

**Format Name:** ROCmFP4 (`Q4_0_ROCMFP4`)  
**Target Hardware:** AMD Strix Halo (gfx1151) + ROCm / Vulkan  
**Design Goals:** High inference speed + strong model coherence at 4-bit

---

## 1. Bit Layout

Each block contains 32 weights + 2 scales. The packed 4-bit values stay in a
32-weight block so llama.cpp kernels can use the existing Q4/Q8 reduction
shape, but each 16-weight half gets its own unsigned E4M3 scale. This is the
current AMD/Strix Halo quality-focused variant.

### Per-Element Format (ROCmFP4 Codebook)

ROCmFP4 uses an E2M1-derived 4-bit codebook, but the largest magnitude is
retuned for Strix Halo LLM weights:

```
integer levels: 0, +1, +2, +3, +4, +6, +8, +10,
                0, -1, -2, -3, -4, -6, -8, -10
```

The stored integers are half-scale values. With a decoded UE4M3 scale `s`, the
represented values are:

```
integer_level * s * 0.5
```

Possible normalized values are therefore: 0, ±0.5, ±1.0, ±1.5, ±2.0, ±3.0,
±4.0, ±5.0. The top level is intentionally lower than standard E2M1's ±6.0 to
reduce outlier pull on dense LLM tensors while retaining the same packed 4-bit
and integer-dot kernel shape.

### Scale Format (UE4M3)
- Unsigned FP8-style scale
- 4 exponent bits, 3 mantissa bits, bias 7
- Stored as `uint8_t`
- Represents the local FP4 scale, with the decode implementation returning
  half the raw UE4M3 value because the ROCmFP4 codebook stores half-scale
  integer values
- Two scales are stored per 32 weights:
  - `scale[0]` covers weights 0-15
  - `scale[1]` covers weights 16-31

### Block Layout (32 elements)
```
[ 16 bytes of packed 4-bit values ]   // 32 × 4-bit = 16 bytes
[ 1 byte  UE4M3 scale for weights 0-15 ]
[ 1 byte  UE4M3 scale for weights 16-31 ]
Total: 18 bytes per block (= 4.50 bits per weight)
```

---

## 2. Quantization Algorithm (Coherence-First)

```python
def quantize_block(weights_32):
    # 1. Find optimal scale for each 16-weight half-block.
    scales = []
    for half in (weights_32[:16], weights_32[16:]):
        scales.append(mse_optimal_ue4m3_scale(half))

    # 2. Quantize each weight
    qvals = []
    for i, w in enumerate(weights_32):
        scale = scales[0 if i < 16 else 1]
        q = nearest_rocmfp4_code(w / scale)
        qvals.append(q)

    return qvals, scales
```

Key coherence improvements:
- Use **FP8 local scales** with MSE-optimal local search.
- Use **16-weight scale granularity** to reduce local outlier damage while
  staying below Q4_K_M size.
- Future: outlier block detection or tensor-specific codebook tuning.

---

## 3. Dequantization

```c
float dequantize(int8_t q_halfscale, uint8_t scale) {
    float s = ue4m3_to_fp32(scale) * 0.5f;
    return q_halfscale * s;
}
```

---

## 4. GGUF Type ID (proposed)

```c
#define GGML_TYPE_Q4_0_ROCMFP4  100   // temporary ID
```

---

## 5. Kernel Requirements

- HIP dequant + matmul kernel must achieve >80% of `Q4_K_M` speed on Strix Halo
- Must support `-ngl` offloading
- Must be compatible with speculative decoding (MTP)

---

*This spec is the source of truth for all implementation work.*
