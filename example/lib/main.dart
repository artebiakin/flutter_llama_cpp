import 'package:flutter/material.dart';
import 'package:flutter_llama_cpp/flutter_llama_cpp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Not initialized';
  String _modelInfo = '';
  String _generatedText = '';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeLlama();
  }

  Future<void> _initializeLlama() async {
    setState(() {
      _status = 'Initializing...';
    });

    final initResult = LlamaFlutter.initialize();
    if (initResult.isError) {
      setState(() {
        _status = 'Initialization failed: ${initResult.error}';
      });
      return;
    }

    final infoResult = LlamaFlutter.getInfo();
    if (infoResult.isSuccess) {
      setState(() {
        _status = 'Initialized successfully';
        _modelInfo = infoResult.value;
      });
    } else {
      setState(() {
        _status = 'Initialized, but could not get info: ${infoResult.error}';
      });
    }
  }

  Future<void> _loadAndTestModel() async {
    setState(() {
      _status = 'Loading model...';
      _isGenerating = true;
    });

    // Note: You need to provide a path to an actual GGUF model file
    const modelPath = '/path/to/your/model.gguf';
    
    final modelResult = LlamaModel.load(modelPath);
    if (modelResult.isError) {
      setState(() {
        _status = 'Model loading failed: ${modelResult.error}';
        _isGenerating = false;
      });
      return;
    }

    final model = modelResult.value;
    
    // Get model info
    final infoResult = model.getInfo();
    if (infoResult.isSuccess) {
      final info = infoResult.value;
      setState(() {
        _modelInfo = 'Model: ${info.name}\n'
            'Architecture: ${info.architecture}\n'
            'Vocab Size: ${info.vocabSize}\n'
            'Context Size: ${info.contextSizeMax}\n'
            'Parameters: ${info.parameterCount}\n'
            'Size: ${(info.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
      });
    }

    // Create context
    final contextResult = model.createContext();
    if (contextResult.isError) {
      setState(() {
        _status = 'Context creation failed: ${contextResult.error}';
        _isGenerating = false;
      });
      model.dispose();
      return;
    }

    final context = contextResult.value;

    // Evaluate prompt
    final prompt = "Hello, my name is";
    final evalResult = context.evaluatePrompt(prompt);
    if (evalResult.isError) {
      setState(() {
        _status = 'Prompt evaluation failed: ${evalResult.error}';
        _isGenerating = false;
      });
      context.dispose();
      model.dispose();
      return;
    }

    setState(() {
      _status = 'Generating...';
      _generatedText = prompt;
    });

    // Generate tokens
    final params = GenerationParams(
      nPredict: 50,
      temperature: 0.8,
      topK: 40,
      topP: 0.9,
    );

    for (int i = 0; i < 50; i++) {
      final genResult = context.generateNext(params);
      if (genResult.isError) {
        setState(() {
          _status = 'Generation failed: ${genResult.error}';
          _isGenerating = false;
        });
        break;
      }

      final result = genResult.value;
      if (result.isEndOfSequence) {
        setState(() {
          _status = 'Generation completed (EOS)';
          _isGenerating = false;
        });
        break;
      }

      setState(() {
        _generatedText += result.token;
      });

      // Small delay to show progress
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_isGenerating) {
      setState(() {
        _status = 'Generation completed';
        _isGenerating = false;
      });
    }

    context.dispose();
    model.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16);
    const spacerSmall = SizedBox(height: 10);
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Llama.cpp Example'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Library Status:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                spacerSmall,
                Text(_status, style: textStyle),
                spacerSmall,
                spacerSmall,
                
                if (_modelInfo.isNotEmpty) ...[
                  const Text(
                    'Library Info:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  spacerSmall,
                  Text(_modelInfo, style: textStyle),
                  spacerSmall,
                  spacerSmall,
                ],
                
                ElevatedButton(
                  onPressed: _isGenerating ? null : _loadAndTestModel,
                  child: const Text('Load Model & Generate Text'),
                ),
                spacerSmall,
                spacerSmall,
                
                if (_generatedText.isNotEmpty) ...[
                  const Text(
                    'Generated Text:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  spacerSmall,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _generatedText,
                      style: textStyle.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
                
                spacerSmall,
                spacerSmall,
                const Text(
                  'Note: To test text generation, you need to provide a path to a GGUF model file in the _loadAndTestModel method.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
