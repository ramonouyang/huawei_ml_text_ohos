/// HarmonyOS Core Vision Kit text recognition plugin for Flutter.
///
/// Wraps `@kit.CoreVisionKit` textRecognition API via MethodChannel.
///
/// ## Features
///
/// - Initialize/release text recognition engine
/// - Recognize text from image files (JPEG, PNG)
/// - Recognize from file path, URL, or raw bytes
/// - Batch recognition for multiple images
/// - Async streaming recognition
/// - Supports: Chinese (simplified), English, Japanese, Korean, Chinese (traditional)
/// - Returns structured results: blocks → lines → words → characters
/// - Position coordinates (Rect, cornerPoints) at all levels
/// - Confidence scores (0.0 ~ 1.0) at all levels
/// - Language detection per block/line/word
/// - Text direction and vertical text detection
/// - Cloud/offline model switching
/// - Region of Interest (ROI) crop
///
/// ## Quick Start
///
/// ```dart
/// import 'package:huawei_ml_text_ohos/huawei_ml_text_ohos.dart';
///
/// final analyzer = HuaweiMlTextAnalyzer();
/// await analyzer.init();
///
/// final result = await analyzer.recognizeText('/path/to/image.jpg');
/// print(result.text);
///
/// for (final block in result.blocks) {
///   print('Block: ${block.stringValue} (conf: ${block.confidence})');
///   for (final line in block.lines) {
///     print('  Line: ${line.stringValue}');
///   }
/// }
///
/// await analyzer.release();
/// ```
library huawei_ml_text_ohos;

export 'src/text_analyzer.dart';
export 'src/models.dart';
export 'src/platform_stub.dart';
