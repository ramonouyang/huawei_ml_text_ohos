import 'package:flutter/material.dart';
import 'package:huawei_ml_text_ohos/huawei_ml_text_ohos.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huawei ML Text Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const TextRecognitionPage(),
    );
  }
}

class TextRecognitionPage extends StatefulWidget {
  const TextRecognitionPage({super.key});

  @override
  State<TextRecognitionPage> createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends State<TextRecognitionPage> {
  final _analyzer = HuaweiMlTextAnalyzer();
  String _status = 'Not initialized';
  String _result = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _analyzer.isAvailable();
    final modelReady = await _analyzer.isModelAvailable();
    setState(() {
      _status = 'Available: $available, Model: $modelReady';
    });
  }

  Future<void> _init() async {
    try {
      final success = await _analyzer.init();
      setState(() {
        _status = success ? 'Initialized' : 'Init failed';
      });
    } on TextRecognitionException catch (e) {
      setState(() {
        _status = 'Error: ${e.code} - ${e.message}';
      });
    }
  }

  Future<void> _release() async {
    await _analyzer.release();
    setState(() {
      _status = 'Released';
      _result = '';
    });
  }

  Future<void> _getLanguages() async {
    try {
      final languages = await _analyzer.getSupportedLanguages();
      setState(() {
        _result = 'Supported languages: ${languages.join(", ")}';
      });
    } on TextRecognitionException catch (e) {
      setState(() {
        _result = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _recognizeFromPath() async {
    // This would normally use image_picker to get a real path
    // For demo purposes, we show the API usage
    setState(() {
      _isProcessing = true;
      _result = 'Processing...';
    });

    try {
      // Example: recognize with config
      final result = await _analyzer.recognizeText(
        '/path/to/image.jpg',
        config: const TextRecognitionConfig(
          language: 'zh',
          isFastMode: false,
          enableCloud: false,
        ),
      );
      _displayResult(result);
    } on TextRecognitionException catch (e) {
      setState(() {
        _result = 'Error: ${e.code}\n${e.message}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _recognizeFromUrl() async {
    setState(() {
      _isProcessing = true;
      _result = 'Processing URL...';
    });

    try {
      final result = await _analyzer.recognizeImage(
        const ImageSource.url('https://example.com/sample.jpg'),
      );
      _displayResult(result);
    } on TextRecognitionException catch (e) {
      setState(() {
        _result = 'Error: ${e.code}\n${e.message}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _recognizeWithRoi() async {
    setState(() {
      _isProcessing = true;
      _result = 'Processing with ROI...';
    });

    try {
      final result = await _analyzer.recognizeText(
        '/path/to/image.jpg',
        config: const TextRecognitionConfig(
          language: 'zh',
          roi: Rect(left: 100, top: 100, right: 500, bottom: 300),
        ),
      );
      _displayResult(result);
    } on TextRecognitionException catch (e) {
      setState(() {
        _result = 'Error: ${e.code}\n${e.message}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _batchRecognize() async {
    setState(() {
      _isProcessing = true;
      _result = 'Batch processing...';
    });

    try {
      final results = await _analyzer.recognizeTextBatch([
        '/path/to/image1.jpg',
        '/path/to/image2.jpg',
        '/path/to/image3.jpg',
      ]);

      final buffer = StringBuffer('Batch Results:\n\n');
      for (int i = 0; i < results.length; i++) {
        if (results[i] != null) {
          buffer.writeln('Image $i: ${results[i]!.text}\n');
        } else {
          buffer.writeln('Image $i: FAILED\n');
        }
      }

      setState(() {
        _result = buffer.toString();
      });
    } on TextRecognitionException catch (e) {
      setState(() {
        _result = 'Error: ${e.code}\n${e.message}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _displayResult(TextRecognitionResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Full text:\n${result.text}\n');
    buffer.writeln('--- Details ---\n');

    for (int b = 0; b < result.blocks.length; b++) {
      final block = result.blocks[b];
      buffer.writeln('Block $b: "${block.stringValue}"');
      buffer.writeln('  Language: ${block.language}');
      buffer.writeln('  Confidence: ${block.confidence?.toStringAsFixed(2)}');
      buffer.writeln('  Rect: ${block.borderRect}');
      buffer.writeln('  Vertical: ${block.isVertical}');

      for (int l = 0; l < block.lines.length; l++) {
        final line = block.lines[l];
        buffer.writeln('  Line $l: "${line.stringValue}"');
        buffer.writeln('    Confidence: ${line.confidence?.toStringAsFixed(2)}');
        buffer.writeln('    Characters: ${line.characterList?.length ?? 0}');
        buffer.writeln('    Elements: ${line.elementList?.length ?? 0}');

        for (int w = 0; w < line.words.length; w++) {
          final word = line.words[w];
          buffer.writeln('    Word $w: "${word.stringValue}" '
              'conf=${word.confidence?.toStringAsFixed(2)} '
              'rect=${word.borderRect}');
        }
      }
      buffer.writeln();
    }

    setState(() {
      _result = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huawei ML Text Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Status: $_status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _init, child: const Text('Init')),
                ElevatedButton(onPressed: _release, child: const Text('Release')),
                ElevatedButton(onPressed: _getLanguages, child: const Text('Languages')),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _recognizeFromPath,
                  child: const Text('File Path'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _recognizeFromUrl,
                  child: const Text('URL'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _recognizeWithRoi,
                  child: const Text('With ROI'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _batchRecognize,
                  child: const Text('Batch'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Result
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _result.isEmpty ? 'No results yet' : _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _analyzer.release();
    super.dispose();
  }
}
