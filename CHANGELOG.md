# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-26

### Added

- **isAvailable()** — check HMS ML Kit service availability
- **isModelAvailable()** — check offline model download status
- **recognizeImage(ImageSource)** — recognize from file path, URL, or bytes
- **ImageSource** class with `filePath`, `url`, `bytes` constructors
- **recognizeTextBatch()** — batch recognize multiple images in one call
- **enableCloud** config option — switch between offline/online recognition
- **roi** config option — Region of Interest crop before recognition
- 51 unit tests (up from 38)

### Changed

- Version bumped to 1.0.0 — all priority features complete

## [0.3.0] - 2026-06-26

### Added

- Character model — per-character recognition with position and confidence
- TextElement model — semantic text units within a line
- characterList on TextWord and TextLine
- elementList on TextBlock and TextLine
- recognizeTextAsync() — non-blocking Stream-based API
- TextRecognitionException + TextRecognitionErrorCode enum
- All methods throw structured errors instead of raw exceptions

## [0.2.0] - 2026-06-26

### Added

- Position coordinates: borderRect, cornerPoints, vertexes at all levels
- Confidence (0.0~1.0) at all levels
- Language detection at TextLine and TextWord level
- Angle and isVertical for text rotation and vertical text detection
- TextRecognitionConfig: language, languageList, isFastMode, isDirectionSupported
- Point and Rect helper types

## [0.1.0] - 2026-06-26

### Added

- Initial release
- HuaweiMlTextAnalyzer Dart API with MethodChannel bridge
- ArkTS plugin wrapping @kit.CoreVisionKit textRecognition
- Supported languages: Chinese, English, Japanese, Korean
