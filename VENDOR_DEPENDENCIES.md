# Vendor Dependencies

This document tracks all vendored dependencies and their versions.

## llama.cpp

- **Version**: `b6316` (commit hash)
- **Actual commit**: `009b709d` (full hash from git subtree)
- **Repository**: https://github.com/ggerganov/llama.cpp
- **Location**: `src/vendor/llama.cpp/`
- **Integration**: Git subtree
- **Added**: 29 August 2025
- **Reason**: Core inference engine for LLM execution

### Integration Method

The llama.cpp dependency was added using git subtree to allow for:
- Local modifications if needed
- Clean integration with our build system
- Version pinning for stability
- Easier CI/CD without submodule complexity

### Adding/Updating llama.cpp

```bash
# Initial add (already done)
git subtree add --prefix=src/vendor/llama.cpp https://github.com/ggerganov/llama.cpp b6316 --squash

# To update to a newer version
git subtree pull --prefix=src/vendor/llama.cpp https://github.com/ggerganov/llama.cpp <new-commit> --squash
```

### Version Selection Criteria

Version `b6316` was selected because:
- Stable release with good performance
- Compatible with our C ABI requirements
- Tested cross-platform build support
- Active maintenance and community support

### Build Integration

The llama.cpp source is integrated via CMake:
- `src/CMakeLists.txt` includes the vendor directory
- Build flags optimized for mobile/desktop targets
- Static linking into our shared library
- Platform-specific optimizations enabled

## ggml

- **Version**: Included with llama.cpp `b6316`
- **Repository**: Part of llama.cpp repository
- **Location**: `src/vendor/llama.cpp/ggml/`
- **Integration**: Bundled with llama.cpp
- **Reason**: Tensor library required by llama.cpp

## Future Dependencies

Any additional vendor dependencies should be documented here with:
- Version/commit hash
- Integration method
- Justification for inclusion
- Update procedures
