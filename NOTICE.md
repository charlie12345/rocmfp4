# Notices

ROCmFP4 is experimental research and integration work for llama.cpp/ggml.

This repository includes:

- New ROCmFP4 source files under `rocmfp4/`.
- Integration patches against llama.cpp/ggml.
- Build and regression helper scripts copied from the reference implementation.

The integration patch modifies llama.cpp/ggml files. llama.cpp/ggml is licensed
under the MIT License. The MIT license text is included in `LICENSE`.

No model weights, Hugging Face tokens, GitHub tokens, API keys, SSH keys, or
other credentials are included in this repository.

ROCmFP4 is not an upstream llama.cpp format. Treat all performance and quality
claims as hardware- and model-specific until reproduced with the included
guards.
