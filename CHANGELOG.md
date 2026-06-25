# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
