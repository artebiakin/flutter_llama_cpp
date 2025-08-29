## 0.0.1

* Initial release with FFI bindings for llama.cpp
* Cross-platform support (iOS, Android, macOS, Windows, Linux)
* Native assets build system integration
* Type-safe Dart API with error handling
* Refactored project structure:
  - Moved FFI sources from `native/` to `src/`
  - Added llama.cpp as git subtree in `src/vendor/llama.cpp/`
  - Updated bindings from `llama_flutter_*` to `flutter_llama_cpp_*`
  - Simplified library naming convention
