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
///
/// // Check availability
/// if (!await analyzer.isAvailable()) {
///   print('Text recognition not available on this device');
///   return;
/// }
///
/// await analyzer.init();
///
/// // Basic: file path
/// final result = await analyzer.recognizeText('/path/to/image.jpg');
///
/// // With config (language, cloud, ROI)
/// final result = await analyzer.recognizeText(
///   '/path/to/image.jpg',
///   config: TextRecognitionConfig(
///     language: 'zh',
///     enableCloud: true,
///     roi: Rect(left: 100, top: 100, right: 500, bottom: 300),
///   ),
/// );
///
/// // From URL
/// final result = await analyzer.recognizeImage(
///   ImageSource.url('https://example.com/image.jpg'),
/// );
///
/// // Batch: multiple images
/// final results = await analyzer.recognizeTextBatch([
///   '/path/to/image1.jpg',
///   '/path/to/image2.jpg',
/// ]);
///
/// // Async stream
/// await for (final r in analyzer.recognizeTextAsync('/path/to/large.jpg')) {
///   print('Partial: ${r.text}');
/// }
///
/// await analyzer.release();
/// ```
class HuaweiMlTextAnalyzer {
  static const MethodChannel _channel =
      MethodChannel('huawei.hms.flutter.ml.text');

  bool _initialized = false;

  /// Check if text recognition is available on this device.
  ///
  /// Returns true if HMS Core is installed and the ML Kit service is ready.
  /// Does NOT require [init] to be called first.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('text#isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if the offline text recognition model is downloaded and ready.
  ///
  /// Returns true if the model is available for offline use.
  /// Does NOT require [init] to be called first.
  Future<bool> isModelAvailable() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('text#isModelAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Initialize the text recognition engine.
  ///
  /// Must be called before [recognizeText], [recognizeImage],
  /// [recognizeTextBatch], or [recognizeTextAsync].
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
  /// [config] optionally controls language, speed, direction, cloud/offline, ROI.
  /// Throws [TextRecognitionException] on failure.
  Future<TextRecognitionResult> recognizeText(
    String imagePath, {
    TextRecognitionConfig? config,
  }) async {
    _ensureInitialized();
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'text#recognizeText',
        _buildArgs(imagePath, config),
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

  /// Recognize text from an [ImageSource] (file path, URL, or bytes).
  ///
  /// This is the most flexible recognition method. For simple file path
  /// usage, [recognizeText] is a convenient shorthand.
  ///
  /// ```dart
  /// // From URL
  /// final r = await analyzer.recognizeImage(ImageSource.url('https://...'));
  ///
  /// // From bytes
  /// final r = await analyzer.recognizeImage(ImageSource.bytes(imageBytes));
  /// ```
  Future<TextRecognitionResult> recognizeImage(
    ImageSource source, {
    TextRecognitionConfig? config,
  }) async {
    _ensureInitialized();

    // If it's a simple file path, delegate to recognizeText
    if (source.isFilePath) {
      return recognizeText(source.filePath!, config: config);
    }

    try {
      final args = <String, dynamic>{
        'imageSource': source.toMap(),
        if (config != null) 'config': config.toMap(),
      };
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'text#recognizeImage',
        args,
      );
      if (result == null) {
        throw const TextRecognitionException(
          code: TextRecognitionErrorCode.nullResult,
          message: 'recognizeImage returned null',
        );
      }
      return TextRecognitionResult.fromMap(result);
    } on TextRecognitionException {
      rethrow;
    } catch (e) {
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Image recognition failed');
    }
  }

  /// Recognize text from multiple images in a single batch call.
  ///
  /// Returns results in the same order as [imagePaths].
  /// Individual failures are returned as null entries (no exception thrown).
  ///
  /// ```dart
  /// final results = await analyzer.recognizeTextBatch([
  ///   '/path/1.jpg', '/path/2.jpg', '/path/3.jpg',
  /// ]);
  /// for (int i = 0; i < results.length; i++) {
  ///   if (results[i] != null) print('Image $i: ${results[i]!.text}');
  /// }
  /// ```
  Future<List<TextRecognitionResult?>> recognizeTextBatch(
    List<String> imagePaths, {
    TextRecognitionConfig? config,
  }) async {
    _ensureInitialized();
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'text#recognizeTextBatch',
        {
          'imagePaths': imagePaths,
          if (config != null) 'config': config.toMap(),
        },
      );
      if (result == null) {
        return List.filled(imagePaths.length, null);
      }
      return result.map((item) {
        if (item == null) return null;
        return TextRecognitionResult.fromMap(item as Map<dynamic, dynamic>);
      }).toList();
    } on TextRecognitionException {
      rethrow;
    } catch (e) {
      throw TextRecognitionException.fromPlatformException(
          e as Exception, 'Batch recognition failed');
    }
  }

  /// Recognize text asynchronously (non-blocking mode).
  ///
  /// Suitable for large images or video frame processing.
  /// Returns a [Stream] that emits partial results as they become available.
  Stream<TextRecognitionResult> recognizeTextAsync(
    String imagePath, {
    TextRecognitionConfig? config,
  }) async* {
    _ensureInitialized();
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
