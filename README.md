# huawei_ml_text_ohos

[![pub package](https://img.shields.io/pub/v/huawei_ml_text_ohos.svg)](https://pub.dev/packages/huawei_ml_text_ohos)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

HarmonyOS NEXT Flutter plugin for text recognition using **Core Vision Kit**.

Wraps `@kit.CoreVisionKit` `textRecognition` API via MethodChannel.

## Features

- ✅ Initialize/release text recognition engine
- ✅ Recognize text from image files (JPEG, PNG)
- ✅ Multiple input sources: file path, URL, raw bytes
- ✅ Batch recognition for multiple images
- ✅ Async streaming recognition
- ✅ Supports: Chinese (simplified), English, Japanese, Korean, Chinese (traditional)
- ✅ Structured results: **TextBlock → TextLine → TextWord → Character**
- ✅ Position coordinates: `borderRect`, `cornerPoints`, `vertexes` at all levels
- ✅ Confidence scores (0.0 ~ 1.0) at all levels
- ✅ Language detection per block/line/word
- ✅ Text direction and vertical text detection
- ✅ Cloud/offline model switching
- ✅ Region of Interest (ROI) crop
- ✅ Device availability checks
- ✅ Structured error handling with error codes

## Platform Support

| Platform | Support |
|----------|---------|
| HarmonyOS NEXT (ohos) | ✅ Full support |
| iOS | ❌ Stub only |
| Android | ❌ Stub only |

## Installation

```yaml
dependencies:
  huawei_ml_text_ohos:
    git:
      url: https://github.com/ramonouyang/huawei_ml_text_ohos.git
      ref: main
```

## Quick Start

```dart
import 'package:huawei_ml_text_ohos/huawei_ml_text_ohos.dart';

final analyzer = HuaweiMlTextAnalyzer();

// Check availability
if (!await analyzer.isAvailable()) {
  print('Text recognition not available');
  return;
}

// Initialize
await analyzer.init();

// Recognize from file path
final result = await analyzer.recognizeText('/path/to/image.jpg');
print(result.text);

// Access structured results
for (final block in result.blocks) {
  print('Block: ${block.stringValue}');
  print('  Language: ${block.language}');
  print('  Confidence: ${block.confidence}');
  print('  Rect: ${block.borderRect}');

  for (final line in block.lines) {
    print('  Line: ${line.stringValue}');
    print('    Characters: ${line.characterList?.length}');

    for (final word in line.words) {
      print('    Word: ${word.stringValue} @ ${word.borderRect}');
    }
  }
}

// Release
await analyzer.release();
```

## API Reference

### Device Checks

```dart
// Check if HMS ML Kit service is available
bool available = await analyzer.isAvailable();

// Check if offline model is downloaded
bool modelReady = await analyzer.isModelAvailable();
```

### Recognition Methods

```dart
// From file path
final result = await analyzer.recognizeText('/path/to/image.jpg');

// From URL
final result = await analyzer.recognizeImage(
  ImageSource.url('https://example.com/image.jpg'),
);

// From bytes
final result = await analyzer.recognizeImage(
  ImageSource.bytes(imageBytes),
);

// Batch: multiple images
final results = await analyzer.recognizeTextBatch([
  '/path/1.jpg',
  '/path/2.jpg',
  '/path/3.jpg',
]);
// results[i] is null if that image failed

// Async stream (for large images)
await for (final result in analyzer.recognizeTextAsync('/path/to/large.jpg')) {
  print('Partial: ${result.text}');
}
```

### Configuration

```dart
final result = await analyzer.recognizeText(
  '/path/to/image.jpg',
  config: TextRecognitionConfig(
    language: 'zh',                    // Single language hint
    // languageList: ['zh', 'en'],     // Or multiple languages
    isFastMode: true,                  // Speed vs accuracy
    isDirectionSupported: true,        // Detect text direction
    enableCloud: false,                // Cloud or offline
    roi: Rect(                         // Region of Interest
      left: 100, top: 100,
      right: 500, bottom: 300,
    ),
  ),
);
```

### Error Handling

```dart
try {
  final result = await analyzer.recognizeText('/path/to/image.jpg');
} on TextRecognitionException catch (e) {
  print('Error code: ${e.code}');
  print('Message: ${e.message}');

  switch (e.code) {
    case TextRecognitionErrorCode.notInitialized:
      // Call init() first
      break;
    case TextRecognitionErrorCode.initFailed:
      // HMS Core issue
      break;
    case TextRecognitionErrorCode.recognizeFailed:
      // Recognition error
      break;
    default:
      break;
  }
}
```

## Data Model

```
TextRecognitionResult
├── text / stringValue
└── blocks: List<TextBlock>
    ├── stringValue, language, confidence
    ├── angle, isVertical
    ├── borderRect, cornerPoints, vertexes
    ├── elementList: List<TextElement>
    └── lines: List<TextLine>
        ├── stringValue, language, confidence
        ├── angle, isVertical
        ├── borderRect, cornerPoints, vertexes
        ├── characterList: List<Character>
        ├── elementList: List<TextElement>
        └── words: List<TextWord>
            ├── stringValue, language, confidence
            ├── borderRect, cornerPoints, vertexes
            └── characterList: List<Character>
```

## Architecture

```
Dart (MethodChannel) ←→ ArkTS (HuaweiMlTextPlugin) ←→ @kit.CoreVisionKit
```

- **Dart**: `HuaweiMlTextAnalyzer` sends method calls
- **ArkTS**: `HuaweiMlTextPlugin` handles calls, invokes HarmonyOS API
- **Result**: Structured `TextRecognitionResult` with full metadata

## Integration with MediPulse

```dart
// lib/platform/ocr_huawei_impl.dart
class HuaweiOcrAdapter implements OcrAdapter {
  final _analyzer = HuaweiMlTextAnalyzer();

  @override
  Future<OcrResult> recognizeFromImage(String imagePath) async {
    await _analyzer.init();
    try {
      final result = await _analyzer.recognizeText(
        imagePath,
        config: const TextRecognitionConfig(language: 'zh'),
      );

      return OcrResult(
        text: result.text,
        blocks: result.blocks.map((b) => OcrBlock(
          text: b.stringValue,
          confidence: b.confidence ?? 0,
          rect: b.borderRect != null
            ? OcrRect(
                left: b.borderRect!.left,
                top: b.borderRect!.top,
                right: b.borderRect!.right,
                bottom: b.borderRect!.bottom,
              )
            : null,
        )).toList(),
      );
    } finally {
      await _analyzer.release();
    }
  }
}
```

## Testing

```bash
flutter test
# 51 tests, all passing
```

## References

- [Core Vision Kit API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/core-vision-text-recognition-api-V5)
- [HMS ML Kit Flutter Plugin](https://github.com/HMS-Core/hms-flutter-plugin/tree/master/flutter-hms-mltext)

## License

MIT License - see [LICENSE](LICENSE) for details.
