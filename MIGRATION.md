# Migration Guide

This document outlines the changes made during the project refactoring and how to update your code if you were using an earlier version.

## Project Structure Changes

### Directory Structure
```diff
flutter_llama_cpp/
├── lib/
-│   ├── llama_flutter.dart                      
-│   └── llama_flutter_bindings_generated.dart  
+│   ├── flutter_llama_cpp.dart                      # Renamed
+│   └── flutter_llama_cpp_bindings_generated.dart   # Renamed
-├── native/
-│   └── shim/
-│       ├── llama_flutter.h
-│       └── llama_flutter.c
+├── src/                                            # Moved from native/
+│   ├── flutter_llama_cpp.h                         # Renamed
+│   ├── flutter_llama_cpp.c                         # Renamed
+│   ├── flutter_llama_cpp_stub.c                    # Added for testing
+│   ├── CMakeLists.txt                               # Added
+│   └── vendor/
+│       └── llama.cpp/                               # Added as git subtree
```

### File Naming Changes

| Old Name | New Name | Notes |
|----------|----------|-------|
| `llama_flutter.h` | `flutter_llama_cpp.h` | C API header |
| `llama_flutter.c` | `flutter_llama_cpp.c` | C implementation |
| `llama_flutter_bindings_generated.dart` | `flutter_llama_cpp_bindings_generated.dart` | FFI bindings |
| `llama_flutter.dart` | `flutter_llama_cpp.dart` | High-level API |

### Import Changes

If you were importing the library directly:

```diff
-import 'package:flutter_llama_cpp/llama_flutter.dart';
+import 'package:flutter_llama_cpp/flutter_llama_cpp.dart';
```

The main API class name remains `LlamaFlutter`, so no code changes are needed there.

### Configuration Updates

#### ffigen.yaml
```diff
-  entry-points:
-    - 'native/shim/llama_flutter.h'
+  entry-points:
+    - 'src/flutter_llama_cpp.h'

-output: 'lib/llama_flutter_bindings_generated.dart'
+output: 'lib/flutter_llama_cpp_bindings_generated.dart'
```

#### hook/build.dart
```diff
-      sources: [
-        'native/shim/llama_flutter_stub.c',
-      ],
-      includes: [
-        'native/shim/',
-      ],
+      sources: [
+        'src/flutter_llama_cpp_stub.c',
+      ],
+      includes: [
+        'src/',
+      ],
```

## Benefits of the Refactoring

1. **Cleaner naming**: Consistent `flutter_llama_cpp` prefix
2. **Better organization**: All native sources in `src/`
3. **Integrated llama.cpp**: No more git submodules, using subtree
4. **Simplified structure**: Fewer nested directories
5. **CMake support**: Ready for complex build configurations

## Regenerating Bindings

After updating your configuration, regenerate the FFI bindings:

```bash
dart run ffigen --config ffigen.yaml
```

## No API Changes

The Dart API remains the same:
- `LlamaFlutter.initialize()`
- `LlamaModel.load()`
- `LlamaContext` methods
- `LlamaResult<T>` pattern

All existing code using the high-level API should continue to work without changes.
