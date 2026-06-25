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
///
/// // Basic usage
/// final result = await analyzer.recognizeText('/path/to/image.jpg');
/// print(result.text);
///
/// // With configuration
/// final result = await analyzer.recognizeText(
///   '/path/to/image.jpg',
///   config: TextRecognitionConfig(language: 'zh', isFastMode: true),
/// );
///
/// // Access position, confidence, and characters
/// for (final block in result.blocks) {
///   print('Block: ${block.stringValue}');
///   print('  Rect: ${block.borderRect}');
///   print('  Confidence: ${block.confidence}');
///   for (final line in block.lines) {
///     print('  Line: ${line.stringValue}');
///     print('    Characters: ${line.characterList?.length ?? 0}');
///     print('    Elements: ${line.elementList?.length ?? 0}');
///     for (final word in line.words) {
///       print('    Word: ${word.stringValue} @ ${word.borderRect}');
///       for (final char in word.characterList ?? []) {
///         print('      Char: ${char.stringValue} conf=${char.confidence}');
///       }
///     }
///   }
/// }
///
/// await analyzer.release();
/// ```
class HuaweiMlTextAnalyzer {
  static const MethodChannel _channel =
      MethodChannel('huawei.hms.flutter.ml.text');

  bool _initialized = false;

  /// Initialize the text recognition engine.
  ///
  /// Must be called before [recognizeText] or [recognizeTextAsync].
  /// Returns `true` if initialization succeeded.
  /// Throws [TextRecognitionException] on failure.
  Future<bool> init() async {
    if (_initialized) return true;
    try {
      final result = await _channel.invokeMethod<bool>('text#init');
      _initialized = result ?? false;
      return _initialized;
    } catch (e) {
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Failed to initialize text recognition');
    }
  }

  /// Recognize text in the image at [imagePath] (synchronous mode).
  ///
  /// [imagePath] must be an absolute file path accessible by the app.
  /// [config] optionally controls language, speed, and direction detection.
  /// Returns the full recognition result with blocks, lines, words,
  /// characters, elements, position coordinates, confidence, and language info.
  /// Throws [TextRecognitionException] on failure.
  Future<TextRecognitionResult> recognizeText(
    String imagePath, {
    TextRecognitionConfig? config,
  }) async {
    _ensureInitialized();
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'text#recognizeText',
        _buildArgs(imagePath, config, async: false),
      );
      if (result == null) {
        throw const TextRecognitionException(
          code: TextRecognitionErrorCode.nullResult,
          message: 'textRecognition returned null',
        );
      }
      return TextRecognitionResult.fromMap(result);
    } on TextRecognitionException {
      rethrow;
    } catch (e) {
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Recognition failed');
    }
  }

  /// Recognize text asynchronously (non-blocking mode).
  ///
  /// Suitable for large images or video frame processing.
  /// Returns a [Stream] that emits partial results as they become available,
  /// with the final result having `isComplete = true`.
  ///
  /// Usage:
  /// ```dart
  /// await for (final result in analyzer.recognizeTextAsync('/path/image.jpg')) {
  ///   print('Partial: ${result.text}');
  ///   if (result.isComplete) print('Done!');
  /// }
  /// ```
  Stream<TextRecognitionResult> recognizeTextAsync(
    String imagePath, {
    TextRecognitionConfig? config,
  }) async* {
    _ensureInitialized();

    // The async method uses event channel or repeated polling.
    // For now, we implement as a single-shot that yields once.
    // The ArkTS side can be extended to support streaming later.
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'text#recognizeText',
        _buildArgs(imagePath, config, async: true),
      );
      if (result == null) {
        throw const TextRecognitionException(
          code: TextRecognitionErrorCode.nullResult,
          message: 'textRecognition returned null',
        );
      }
      yield TextRecognitionResult.fromMap(result);
    } on TextRecognitionException {
      rethrow;
    } catch (e) {
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Async recognition failed');
    }
  }

  /// Get list of supported languages.
  /// Throws [TextRecognitionException] on failure.
  Future<List<String>> getSupportedLanguages() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('text#getSupportedLanguages');
      return result?.cast<String>() ?? [];
    } catch (e) {
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Failed to get supported languages');
    }
  }

  /// Release the text recognition engine and free resources.
  ///
  /// After calling this, you must call [init] again before further use.
  Future<bool> release() async {
    if (!_initialized) return true;
    try {
      final result = await _channel.invokeMethod<bool>('text#release');
      _initialized = false;
      return result ?? true;
    } catch (e) {
      _initialized = false;
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Failed to release text recognition');
    }
  }

  /// Whether the analyzer has been initialized.
  bool get isInitialized => _initialized;

  // ==========================================================================
  // Internal helpers
  // ==========================================================================

  void _ensureInitialized() {
    if (!_initialized) {
      throw const TextRecognitionException(
        code: TextRecognitionErrorCode.notInitialized,
        message: 'HuaweiMlTextAnalyzer not initialized. Call init() first.',
      );
    }
  }

  Map<String, dynamic> _buildArgs(
    String imagePath,
    TextRecognitionConfig? config, {
    bool async = false,
  }) {
    return {
      'imagePath': imagePath,
      if (config != null) 'config': config.toMap(),
      if (async) 'async': true,
    };
  }
}
