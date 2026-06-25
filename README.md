# huawei_ml_text_ohos

HarmonyOS NEXT Flutter plugin for text recognition using Core Vision Kit.

Wraps `@kit.CoreVisionKit` `textRecognition` API via MethodChannel.

## Features

- Initialize/release text recognition engine
- Recognize text from image files (JPEG, PNG)
- Supports: Chinese (simplified), English, Japanese, Korean, Chinese (traditional)
- Returns structured results: blocks → lines → words with coordinates

## Usage

```dart
import 'package:huawei_ml_text_ohos/huawei_ml_text_ohos.dart';

final analyzer = HuaweiMlTextAnalyzer();
await analyzer.init();

final result = await analyzer.recognizeText('/path/to/image.jpg');
print(result.text); // Full recognized text

for (final block in result.blocks) {
  print('Block: ${block.stringValue}');
  for (final line in block.lines) {
    print('  Line: ${line.stringValue}');
  }
}

await analyzer.release();
```

## Architecture

```
Dart (MethodChannel) ←→ ArkTS (HuaweiMlTextPlugin) ←→ @kit.CoreVisionKit
```

- **Dart**: `HuaweiMlTextAnalyzer` sends method calls
- **ArkTS**: `HuaweiMlTextPlugin` handles calls, invokes HarmonyOS API
- **Result**: Structured `TextRecognitionResult` with blocks/lines/words

## Integration with MediPulse

```dart
// lib/platform/ocr_huawei_impl.dart
class HuaweiOcrAdapter implements OcrAdapter {
  final _analyzer = HuaweiMlTextAnalyzer();
  
  @override
  Future<String> recognizeFromImage(String imagePath) async {
    await _analyzer.init();
    final result = await _analyzer.recognizeText(imagePath);
    return result.text;
  }
}
```

## References

- [Core Vision Kit API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/core-vision-text-recognition-api-V5)
- [HMS ML Kit Flutter Plugin](https://github.com/HMS-Core/hms-flutter-plugin/tree/master/flutter-hms-mltext)
