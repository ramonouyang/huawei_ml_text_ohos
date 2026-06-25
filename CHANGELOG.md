# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-06-26

### Added

- **Position coordinates**: `borderRect` (bounding box), `cornerPoints` (4 corners), `vertexes` at all levels (Block/Line/Word)
- **`confidence`** field (0.0~1.0) at all levels for recognition quality assessment
- **`language`** detection at TextLine and TextWord level (previously only TextBlock)
- **`angle`** and **`isVertical`** for text rotation and vertical text detection on Block/Line
- **`TextRecognitionConfig`** class for controlling recognition:
  - `language` — single language hint (e.g. "zh", "en")
  - `languageList` — multi-language recognition
  - `isFastMode` — speed vs accuracy tradeoff
  - `isDirectionSupported` — text direction detection (0°/90°/180°/270°)
- **`Point`** and **`Rect`** helper types with equality, fromMap, and toString
- ArkTS plugin now maps `borderRect`, `cornerPoints`, `confidence`, `angle`, `isVertical`, `language` at all levels
- ArkTS plugin now accepts `config` parameter and maps to `TextRecognitionConfiguration`
- 32 unit tests (up from 18)

### Changed

- `Offset` class replaced by `Point` with proper equality and fromMap factory
- `vertexes` type changed from `List<Offset>` to `List<Point>`

## [0.1.0] - 2026-06-26

### Added

- Initial release
- `HuaweiMlTextAnalyzer` Dart API with MethodChannel bridge
- ArkTS plugin wrapping `@kit.CoreVisionKit` textRecognition
- Support for text recognition from image files (JPEG, PNG)
- Structured results: TextRecognitionResult → TextBlock → TextLine → TextWord
- Bounding box coordinates (vertexes) at each level
- Language detection per text block
- Supported languages: Chinese (simplified), English, Japanese, Korean, Chinese (traditional)
- Unit tests for data models (6 test cases)
- Unit tests for text analyzer with mocked MethodChannel (10 test cases)
- README with usage examples and MediPulse integration guide
