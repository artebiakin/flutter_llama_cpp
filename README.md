# flutter_llama_cpp

A Flutter plugin that provides Dart FFI bindings for llama.cpp, enabling you to run large language models directly on mobile and desktop platforms.

## Features

- 🚀 High-performance inference using llama.cpp
- 📱 Cross-platform support (iOS, Android, macOS, Windows, Linux)
- 🔧 C++ shim layer for stable FFI interface
- 🎯 Type-safe Dart API with error handling
- 🛠️ Automatic native builds using CMake
- 💾 Support for GGUF model format

## Quick Start

### 1. Add to your pubspec.yaml

```yaml
dependencies:
  flutter_llama_cpp: ^0.0.1
```

### 2. Initialize the library

```dart
import 'package:flutter_llama_cpp/flutter_llama_cpp.dart';

// Initialize llama.cpp
final initResult = LlamaFlutter.initialize();
if (initResult.isError) {
  print('Failed to initialize: ${initResult.error}');
  return;
}

// Get library info
final infoResult = LlamaFlutter.getInfo();
if (infoResult.isSuccess) {
  print('Library info: ${infoResult.value}');
}
```

### 3. Load a model and generate text

```dart
// Load a GGUF model
final modelResult = LlamaModel.load('/path/to/your/model.gguf');
if (modelResult.isError) {
  print('Failed to load model: ${modelResult.error}');
  return;
}

final model = modelResult.value;

// Create inference context
final contextResult = model.createContext();
if (contextResult.isError) {
  print('Failed to create context: ${contextResult.error}');
  model.dispose();
  return;
}

final context = contextResult.value;

// Evaluate a prompt
final evalResult = context.evaluatePrompt("Hello, my name is");
if (evalResult.isError) {
  print('Failed to evaluate prompt: ${evalResult.error}');
  context.dispose();
  model.dispose();
  return;
}

// Generate tokens
final params = GenerationParams(
  nPredict: 50,
  temperature: 0.8,
  topK: 40,
  topP: 0.9,
);

String generatedText = "Hello, my name is";
for (int i = 0; i < 50; i++) {
  final genResult = context.generateNext(params);
  if (genResult.isError) {
    print('Generation error: ${genResult.error}');
    break;
  }
  
  final result = genResult.value;
  if (result.isEndOfSequence) {
    print('End of sequence reached');
    break;
  }
  
  generatedText += result.token;
  print('Generated: $generatedText');
}

// Clean up
context.dispose();
model.dispose();
```

## API Reference

### LlamaFlutter

The main class for library initialization and global operations.

- `LlamaFlutter.initialize()` - Initialize the llama.cpp library
- `LlamaFlutter.getInfo()` - Get library version and build information

### LlamaModel

Represents a loaded language model.

- `LlamaModel.load(String path)` - Load a model from a GGUF file
- `getInfo()` - Get model information (architecture, size, etc.)
- `createContext([int? contextSize])` - Create an inference context
- `dispose()` - Free the model resources

### LlamaContext

Represents an inference context for text generation.

- `evaluatePrompt(String prompt)` - Process initial prompt
- `generateNext([GenerationParams? params])` - Generate next token
- `cancel()` - Cancel ongoing generation
- `reset()` - Reset context state
- `dispose()` - Free context resources

### GenerationParams

Configuration for text generation.

```dart
GenerationParams({
  int nPredict = -1,        // Number of tokens to generate
  int topK = 40,            // Top-K sampling
  double topP = 0.9,        // Top-P sampling
  double temperature = 0.8,  // Temperature for randomness
  double repeatPenalty = 1.1, // Repetition penalty
  bool penalizeNewlines = false, // Penalize newlines
  int seed = -1,            // Random seed (-1 for random)
})
```

### LlamaResult<T>

A result type that represents either success or error.

- `isSuccess` / `isError` - Check result status
- `value` - Get the result value (throws if error)
- `error` - Get the error message (throws if success)
- `map<U>(transform)` - Transform the value if successful
- `fold<U>(onSuccess, onError)` - Handle both cases

## Development Setup

### Prerequisites

- Flutter SDK
- CMake 3.18+
- C++17 compatible compiler
- Git with submodules support

### Building from Source

1. Initialize the llama.cpp submodule:
```bash
git submodule update --init --recursive
```

2. Generate FFI bindings:
```bash
dart run ffigen --config ffigen.yaml
```

3. Run the example:
```bash
cd example
flutter run
```

### Project Structure

The project has been refactored for better organization:

```
flutter_llama_cpp/
├── lib/
│   ├── flutter_llama_cpp.dart                      # High-level Dart API
│   └── flutter_llama_cpp_bindings_generated.dart   # Generated FFI bindings
├── src/
│   ├── flutter_llama_cpp.h                         # C API header
│   ├── flutter_llama_cpp.c                         # C implementation
│   ├── flutter_llama_cpp_stub.c                    # Stub for testing
│   ├── CMakeLists.txt                               # CMake build configuration
│   └── vendor/
│       └── llama.cpp/                               # llama.cpp git subtree
├── hook/
│   └── build.dart                                   # Native assets build hook
├── ffigen.yaml                                      # FFI generation config
└── example/                                         # Demo application
```

### Recent Changes

- **Simplified naming**: Changed from `llama_flutter_*` to `flutter_llama_cpp_*`
- **Moved sources**: Relocated from `native/` to `src/` directory
- **Added llama.cpp**: Integrated as git subtree in `src/vendor/llama.cpp/`
- **Updated paths**: All documentation and build files reflect new structure

### Architecture

The plugin uses a layered architecture:

1. **llama.cpp** - The core C++ inference engine (`src/vendor/llama.cpp/`)
2. **C++ Shim Layer** (`src/`) - Stable C API wrapper
3. **FFI Bindings** (`lib/flutter_llama_cpp_bindings_generated.dart`) - Generated Dart bindings
4. **High-level API** (`lib/flutter_llama_cpp.dart`) - Type-safe Dart interface
5. **Build Hook** (`hook/build.dart`) - Native asset compilation

## Platform Support

| Platform | Architecture | Status |
|----------|--------------|--------|
| Android  | ARM64, x86_64 | ✅ |
| iOS      | ARM64        | ✅ |
| macOS    | ARM64, x86_64 | ✅ |
| Linux    | x86_64       | ✅ |
| Windows  | x86_64       | ✅ |

## License

This project is licensed under the MIT License.

The bundled llama.cpp library is also licensed under the MIT License.
