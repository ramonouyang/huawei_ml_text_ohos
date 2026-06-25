import 'package:flutter/services.dart';
import 'models.dart';

/// Dart wrapper for HarmonyOS Core Vision Kit text recognition.
///
/// Uses MethodChannel `huawei.hms.flutter.ml.text` to communicate
/// with the ArkTS HuaweiMlTextPlugin.
///
/// Usage:
/// ```dart
/// final analyzer = HuaweiMlTextAnalyzer();
/// await analyzer.init();
/// final result = await analyzer.recognizeText('/path/to/image.jpg');
/// print(result.text);
/// await analyzer.release();
/// ```
class HuaweiMlTextAnalyzer {
  static const MethodChannel _channel =
      MethodChannel('huawei.hms.flutter.ml.text');

  bool _initialized = false;

  /// Initialize the text recognition engine.
  ///
  /// Must be called before [recognizeText]. Loads the ML model.
  /// Returns `true` if initialization succeeded.
  Future<bool> init() async {
    if (_initialized) return true;
    final result = await _channel.invokeMethod<bool>('text#init');
    _initialized = result ?? false;
    return _initialized;
  }

  /// Recognize text in the image at [imagePath].
  ///
  /// [imagePath] must be an absolute file path accessible by the app.
  /// Returns the full recognition result with blocks, lines, and words.
  Future<TextRecognitionResult> recognizeText(String imagePath) async {
    if (!_initialized) {
      throw StateError(
          'HuaweiMlTextAnalyzer not initialized. Call init() first.');
    }
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'text#recognizeText',
      {'imagePath': imagePath},
    );
    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'textRecognition returned null',
      );
    }
    return TextRecognitionResult.fromMap(result);
  }

  /// Get list of supported languages.
  Future<List<String>> getSupportedLanguages() async {
    final result =
        await _channel.invokeMethod<List<dynamic>>('text#getSupportedLanguages');
    return result?.cast<String>() ?? [];
  }

  /// Release the text recognition engine and free resources.
  ///
  /// After calling this, you must call [init] again before further use.
  Future<bool> release() async {
    if (!_initialized) return true;
    final result = await _channel.invokeMethod<bool>('text#release');
    _initialized = false;
    return result ?? true;
  }

  /// Whether the analyzer has been initialized.
  bool get isInitialized => _initialized;
}
