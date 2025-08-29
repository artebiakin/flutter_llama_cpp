library llama_flutter;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'llama_flutter_bindings_generated.dart';

export 'llama_flutter_bindings_generated.dart';

/// A Dart wrapper for the llama.cpp library
class LlamaFlutter {
  static LlamaFlutterBindings? _bindings;
  static bool _initialized = false;

  /// Get the native bindings for llama.cpp
  static LlamaFlutterBindings get bindings {
    if (_bindings == null) {
      _bindings = LlamaFlutterBindings(_dylib);
    }
    return _bindings!;
  }

  /// Initialize the llama.cpp library
  static LlamaResult<void> initialize() {
    if (_initialized) {
      return LlamaResult.success(null);
    }

    final result = bindings.lf_init();
    if (result == lf_error_t.LF_OK) {
      _initialized = true;
      return LlamaResult.success(null);
    } else {
      final error = _getLastError();
      return LlamaResult.error(error);
    }
  }

  /// Get library information
  static LlamaResult<String> getInfo() {
    final buffer = calloc<Char>(1024);
    try {
      final result = bindings.lf_info(buffer, 1024);
      if (result == lf_error_t.LF_OK) {
        return LlamaResult.success(buffer.cast<Utf8>().toDartString());
      } else {
        final error = _getLastError();
        return LlamaResult.error(error);
      }
    } finally {
      calloc.free(buffer);
    }
  }

  static String _getLastError() {
    final buffer = calloc<Char>(1024);
    try {
      bindings.lf_last_error(buffer, 1024);
      return buffer.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buffer);
    }
  }
}

/// A high-level wrapper for a llama.cpp model
class LlamaModel {
  final Pointer<lf_model> _handle;
  bool _disposed = false;

  LlamaModel._(this._handle);

  /// Load a model from a GGUF file
  static LlamaResult<LlamaModel> load(String modelPath) {
    final pathPtr = modelPath.toNativeUtf8();
    final modelPtr = calloc<Pointer<lf_model>>();

    try {
      final result = LlamaFlutter.bindings.lf_model_load(
        pathPtr.cast<Char>(),
        modelPtr,
      );

      if (result == lf_error_t.LF_OK) {
        final model = LlamaModel._(modelPtr.value);
        return LlamaResult.success(model);
      } else {
        final error = LlamaFlutter._getLastError();
        return LlamaResult.error(error);
      }
    } finally {
      calloc.free(pathPtr);
      calloc.free(modelPtr);
    }
  }

  /// Get model information
  LlamaResult<ModelInfo> getInfo() {
    if (_disposed) {
      return LlamaResult.error('Model has been disposed');
    }

    final infoPtr = calloc<lf_model_info_t>();
    try {
      final result = LlamaFlutter.bindings.lf_model_info(_handle, infoPtr);
      if (result == lf_error_t.LF_OK) {
        final info = ModelInfo._fromNative(infoPtr.ref);
        return LlamaResult.success(info);
      } else {
        final error = LlamaFlutter._getLastError();
        return LlamaResult.error(error);
      }
    } finally {
      calloc.free(infoPtr);
    }
  }

  /// Create a context for inference
  LlamaResult<LlamaContext> createContext([int? contextSize]) {
    if (_disposed) {
      return LlamaResult.error('Model has been disposed');
    }

    final contextPtr = calloc<Pointer<lf_context>>();
    try {
      final result = LlamaFlutter.bindings.lf_context_create(
        _handle,
        contextSize ?? 0,
        contextPtr,
      );

      if (result == lf_error_t.LF_OK) {
        final context = LlamaContext._(contextPtr.value);
        return LlamaResult.success(context);
      } else {
        final error = LlamaFlutter._getLastError();
        return LlamaResult.error(error);
      }
    } finally {
      calloc.free(contextPtr);
    }
  }

  /// Dispose the model and free native resources
  void dispose() {
    if (!_disposed) {
      LlamaFlutter.bindings.lf_model_free(_handle);
      _disposed = true;
    }
  }
}

/// A high-level wrapper for a llama.cpp context
class LlamaContext {
  final Pointer<lf_context> _handle;
  bool _disposed = false;

  LlamaContext._(this._handle);

  /// Evaluate a prompt and prepare for generation
  LlamaResult<void> evaluatePrompt(String prompt) {
    if (_disposed) {
      return LlamaResult.error('Context has been disposed');
    }

    final promptPtr = prompt.toNativeUtf8();
    try {
      final result = LlamaFlutter.bindings.lf_eval_prompt(
        _handle,
        promptPtr.cast<Char>(),
      );

      if (result == lf_error_t.LF_OK) {
        return LlamaResult.success(null);
      } else {
        final error = LlamaFlutter._getLastError();
        return LlamaResult.error(error);
      }
    } finally {
      calloc.free(promptPtr);
    }
  }

  /// Generate the next token
  LlamaResult<GenerationResult> generateNext([GenerationParams? params]) {
    if (_disposed) {
      return LlamaResult.error('Context has been disposed');
    }

    final paramsPtr = calloc<lf_generation_params_t>();
    final tokenBuffer = calloc<Char>(256);
    final isEosPtr = calloc<Bool>();

    try {
      if (params != null) {
        params._toNative(paramsPtr.ref);
      } else {
        LlamaFlutter.bindings.lf_generation_params_default(paramsPtr);
      }

      final result = LlamaFlutter.bindings.lf_generate_next(
        _handle,
        paramsPtr,
        tokenBuffer,
        256,
        isEosPtr,
      );

      if (result == lf_error_t.LF_OK) {
        final token = tokenBuffer.cast<Utf8>().toDartString();
        final isEos = isEosPtr.value;
        return LlamaResult.success(GenerationResult(token, isEos));
      } else {
        final error = LlamaFlutter._getLastError();
        return LlamaResult.error(error);
      }
    } finally {
      calloc.free(paramsPtr);
      calloc.free(tokenBuffer);
      calloc.free(isEosPtr);
    }
  }

  /// Cancel ongoing generation
  LlamaResult<void> cancel() {
    if (_disposed) {
      return LlamaResult.error('Context has been disposed');
    }

    final result = LlamaFlutter.bindings.lf_cancel(_handle);
    if (result == lf_error_t.LF_OK) {
      return LlamaResult.success(null);
    } else {
      final error = LlamaFlutter._getLastError();
      return LlamaResult.error(error);
    }
  }

  /// Reset context state
  LlamaResult<void> reset() {
    if (_disposed) {
      return LlamaResult.error('Context has been disposed');
    }

    final result = LlamaFlutter.bindings.lf_reset(_handle);
    if (result == lf_error_t.LF_OK) {
      return LlamaResult.success(null);
    } else {
      final error = LlamaFlutter._getLastError();
      return LlamaResult.error(error);
    }
  }

  /// Dispose the context and free native resources
  void dispose() {
    if (!_disposed) {
      LlamaFlutter.bindings.lf_context_free(_handle);
      _disposed = true;
    }
  }
}

/// Model information
class ModelInfo {
  final String name;
  final String architecture;
  final int vocabSize;
  final int contextSizeMax;
  final int embeddingSize;
  final int parameterCount;
  final int sizeBytes;

  ModelInfo._({
    required this.name,
    required this.architecture,
    required this.vocabSize,
    required this.contextSizeMax,
    required this.embeddingSize,
    required this.parameterCount,
    required this.sizeBytes,
  });

  factory ModelInfo._fromNative(lf_model_info_t info) {
    return ModelInfo._(
      name: _arrayToString(info.name),
      architecture: _arrayToString(info.architecture),
      vocabSize: info.vocab_size,
      contextSizeMax: info.n_ctx_max,
      embeddingSize: info.n_embd,
      parameterCount: info.n_params,
      sizeBytes: info.size_bytes,
    );
  }

  @override
  String toString() {
    return 'ModelInfo(name: $name, architecture: $architecture, '
        'vocabSize: $vocabSize, contextSizeMax: $contextSizeMax, '
        'embeddingSize: $embeddingSize, parameterCount: $parameterCount, '
        'sizeBytes: $sizeBytes)';
  }
}

/// Generation parameters
class GenerationParams {
  final int nPredict;
  final int topK;
  final double topP;
  final double temperature;
  final double repeatPenalty;
  final bool penalizeNewlines;
  final int seed;

  GenerationParams({
    this.nPredict = -1,
    this.topK = 40,
    this.topP = 0.9,
    this.temperature = 0.8,
    this.repeatPenalty = 1.1,
    this.penalizeNewlines = false,
    this.seed = -1,
  });

  void _toNative(lf_generation_params_t params) {
    params.n_predict = nPredict;
    params.top_k = topK;
    params.top_p = topP;
    params.temp = temperature;
    params.repeat_penalty = repeatPenalty;
    params.penalize_nl = penalizeNewlines;
    params.seed = seed;
  }
}

/// Result of generating a single token
class GenerationResult {
  final String token;
  final bool isEndOfSequence;

  GenerationResult(this.token, this.isEndOfSequence);

  @override
  String toString() {
    return 'GenerationResult(token: "$token", isEndOfSequence: $isEndOfSequence)';
  }
}

/// A result type that can represent either success or failure
class LlamaResult<T> {
  final T? _value;
  final String? _error;
  final bool _isSuccess;

  LlamaResult.success(this._value) : _error = null, _isSuccess = true;
  LlamaResult.error(this._error) : _value = null, _isSuccess = false;

  bool get isSuccess => _isSuccess;
  bool get isError => !_isSuccess;

  T get value {
    if (!_isSuccess) {
      throw StateError('Attempted to get value from error result: $_error');
    }
    return _value as T;
  }

  String get error {
    if (_isSuccess) {
      throw StateError('Attempted to get error from success result');
    }
    return _error!;
  }

  /// Transform the value if this is a success result
  LlamaResult<U> map<U>(U Function(T) transform) {
    if (_isSuccess) {
      return LlamaResult.success(transform(_value as T));
    } else {
      return LlamaResult.error(_error!);
    }
  }

  /// Handle both success and error cases
  U fold<U>(U Function(T) onSuccess, U Function(String) onError) {
    if (_isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onError(_error!);
    }
  }
}

/// The dynamic library that contains the llama.cpp implementation
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    // For native assets on Apple platforms, try framework first
    try {
      return DynamicLibrary.open('llama_flutter.framework/llama_flutter');
    } catch (e) {
      // Fallback to process lookup
      return DynamicLibrary.process();
    }
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libllama_flutter.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('llama_flutter.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// Helper function to convert Array<Char> to String
String _arrayToString(Array<Char> array) {
  final List<int> chars = [];
  for (int i = 0; i < 256; i++) { // Maximum array size
    final char = array[i];
    if (char == 0) break; // Null terminator
    chars.add(char);
  }
  return String.fromCharCodes(chars);
}
