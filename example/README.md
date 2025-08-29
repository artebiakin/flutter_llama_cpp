# flutter_llama_cpp_example

Demonstrates how to use the flutter_llama_cpp plugin for running llama.cpp models in Flutter.

## Getting Started

This example shows how to:
- Initialize the llama.cpp library
- Get library information
- Load and use language models (when available)
- Handle errors and results using the type-safe API

## Running the Example

1. Make sure you have Flutter installed
2. Run the example:
   ```bash
   flutter run
   ```

## Key Features Demonstrated

- **Library Initialization**: Shows how to initialize the llama.cpp library
- **Error Handling**: Demonstrates proper error handling with `LlamaResult<T>`
- **Model Management**: Shows how to load and manage language models
- **Text Generation**: Examples of generating text with different parameters

## API Usage

```dart
import 'package:flutter_llama_cpp/flutter_llama_cpp.dart';

// Initialize the library
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

For more detailed usage examples, see the main library documentation.
