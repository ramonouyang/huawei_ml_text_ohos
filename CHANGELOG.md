# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-06-26

### Added

- **Character** model — per-character recognition with position and confidence
- **TextElement** model — semantic text units within a line (word, number, punctuation)
- `characterList` on TextWord and TextLine for character-level data
- `elementList` on TextBlock and TextLine for element-level data
- **recognizeTextAsync()** — non-blocking async recognition via Stream
- **TextRecognitionException** — structured exception with error code enum
- **TextRecognitionErrorCode** enum — notInitialized, initFailed, recognizeFailed, invalidArgs, nullResult, languagesFailed, unknown
- `_parseList<T>` generic helper for parsing nullable list fields
- 38 unit tests (up from 32)

### Changed

- All public methods now throw TextRecognitionException instead of raw PlatformException/StateError
- init() catches and wraps errors as TextRecognitionException

## [0.2.0] - 2026-06-26

### Added

- Position coordinates: borderRect, cornerPoints, vertexes at all levels
- Confidence (0.0~1.0) at all levels
- Language detection at TextLine and TextWord level
- Angle and isVertical for text rotation and vertical text detection
- TextRecognitionConfig: language, languageList, isFastMode, isDirectionSupported
- Point and Rect helper types with equality, fromMap, and toString

## [0.1.0] - 2026-06-26

### Added

- Initial release
- HuaweiMlTextAnalyzer Dart API with MethodChannel bridge
- ArkTS plugin wrapping @kit.CoreVisionKit textRecognition
- Structured results: TextRecognitionResult → TextBlock → TextLine → TextWord
- Supported languages: Chinese, English, Japanese, Korean
