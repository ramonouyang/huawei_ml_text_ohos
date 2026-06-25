/// Data models for Core Vision Kit text recognition results.
///
/// Mirrors the HMS ML Kit TextBlock/TextLine/TextWord hierarchy
/// from HMS-Core/hms-flutter-plugin/flutter-hms-mltext.
///
/// Structure: TextRecognitionResult → TextBlock → TextLine → TextWord
/// Each level includes position (Rect), corner points, confidence, and language.

// ============================================================================
// Helper types
// ============================================================================

/// A simple 2D point.
class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  factory Point.fromMap(Map<dynamic, dynamic> map) {
    return Point(
      (map['x'] as num?)?.toDouble() ?? 0,
      (map['y'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Axis-aligned bounding rectangle.
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  factory Rect.fromMap(Map<dynamic, dynamic> map) {
    return Rect(
      left: (map['left'] as num?)?.toDouble() ?? 0,
      top: (map['top'] as num?)?.toDouble() ?? 0,
      right: (map['right'] as num?)?.toDouble() ?? 0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  String toString() => 'Rect($left, $top, $right, $bottom)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rect &&
          other.left == left &&
          other.top == top &&
          other.right == right &&
          other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

// ============================================================================
// Recognition result models
// ============================================================================

/// A recognized word (smallest unit).
class TextWord {
  final String stringValue;
  final List<Point>? vertexes;
  final Rect? borderRect;
  final List<Point>? cornerPoints;
  final double? confidence;
  final String? language;

  const TextWord({
    required this.stringValue,
    this.vertexes,
    this.borderRect,
    this.cornerPoints,
    this.confidence,
    this.language,
  });

  factory TextWord.fromMap(Map<dynamic, dynamic> map) {
    return TextWord(
      stringValue: map['stringValue'] as String? ?? '',
      vertexes: _parsePoints(map['vertexes']),
      borderRect: _parseRect(map['borderRect']),
      cornerPoints: _parsePoints(map['cornerPoints']),
      confidence: (map['confidence'] as num?)?.toDouble(),
      language: map['language'] as String?,
    );
  }

  @override
  String toString() => stringValue;
}

/// A recognized line of text.
class TextLine {
  final String stringValue;
  final List<TextWord> words;
  final List<Point>? vertexes;
  final Rect? borderRect;
  final List<Point>? cornerPoints;
  final double? confidence;
  final String? language;
  final double? angle;
  final bool? isVertical;

  const TextLine({
    required this.stringValue,
    required this.words,
    this.vertexes,
    this.borderRect,
    this.cornerPoints,
    this.confidence,
    this.language,
    this.angle,
    this.isVertical,
  });

  factory TextLine.fromMap(Map<dynamic, dynamic> map) {
    return TextLine(
      stringValue: map['stringValue'] as String? ?? '',
      words: (map['words'] as List?)
              ?.map((w) => TextWord.fromMap(w as Map<dynamic, dynamic>))
              .toList() ??
          [],
      vertexes: _parsePoints(map['vertexes']),
      borderRect: _parseRect(map['borderRect']),
      cornerPoints: _parsePoints(map['cornerPoints']),
      confidence: (map['confidence'] as num?)?.toDouble(),
      language: map['language'] as String?,
      angle: (map['angle'] as num?)?.toDouble(),
      isVertical: map['isVertical'] as bool?,
    );
  }

  @override
  String toString() => stringValue;
}

/// A recognized text block (paragraph or region).
class TextBlock {
  final String stringValue;
  final String? language;
  final List<TextLine> lines;
  final List<Point>? vertexes;
  final Rect? borderRect;
  final List<Point>? cornerPoints;
  final double? confidence;
  final double? angle;
  final bool? isVertical;

  const TextBlock({
    required this.stringValue,
    this.language,
    required this.lines,
    this.vertexes,
    this.borderRect,
    this.cornerPoints,
    this.confidence,
    this.angle,
    this.isVertical,
  });

  factory TextBlock.fromMap(Map<dynamic, dynamic> map) {
    return TextBlock(
      stringValue: map['stringValue'] as String? ?? '',
      language: map['language'] as String?,
      lines: (map['lines'] as List?)
              ?.map((l) => TextLine.fromMap(l as Map<dynamic, dynamic>))
              .toList() ??
          [],
      vertexes: _parsePoints(map['vertexes']),
      borderRect: _parseRect(map['borderRect']),
      cornerPoints: _parsePoints(map['cornerPoints']),
      confidence: (map['confidence'] as num?)?.toDouble(),
      angle: (map['angle'] as num?)?.toDouble(),
      isVertical: map['isVertical'] as bool?,
    );
  }

  @override
  String toString() => stringValue;
}

/// Full text recognition result.
class TextRecognitionResult {
  final List<TextBlock> blocks;
  final String stringValue;

  const TextRecognitionResult({
    required this.blocks,
    required this.stringValue,
  });

  factory TextRecognitionResult.fromMap(Map<dynamic, dynamic> map) {
    final blocks = (map['blocks'] as List?)
            ?.map((b) => TextBlock.fromMap(b as Map<dynamic, dynamic>))
            .toList() ??
        [];
    final fullText = blocks.map((b) => b.stringValue).join('\n');
    return TextRecognitionResult(
      blocks: blocks,
      stringValue: map['stringValue'] as String? ?? fullText,
    );
  }

  /// All recognized text as a single string.
  String get text => stringValue;
}

// ============================================================================
// Configuration
// ============================================================================

/// Text recognition configuration.
///
/// Controls language, recognition mode, and other parameters.
class TextRecognitionConfig {
  /// Single language to recognize (e.g. "zh", "en").
  /// Mutually exclusive with [languageList].
  final String? language;

  /// Multiple languages to recognize simultaneously.
  /// Mutually exclusive with [language].
  final List<String>? languageList;

  /// Recognition mode: true = fast, false/nil = standard.
  final bool? isFastMode;

  /// Whether to detect text direction (0°/90°/180°/270°).
  final bool? isDirectionSupported;

  const TextRecognitionConfig({
    this.language,
    this.languageList,
    this.isFastMode,
    this.isDirectionSupported,
  });

  Map<String, dynamic> toMap() {
    return {
      if (language != null) 'language': language,
      if (languageList != null) 'languageList': languageList,
      if (isFastMode != null) 'isFastMode': isFastMode,
      if (isDirectionSupported != null)
        'isDirectionSupported': isDirectionSupported,
    };
  }
}

// ============================================================================
// Internal parsers
// ============================================================================

List<Point>? _parsePoints(dynamic data) {
  if (data is! List) return null;
  return data
      .map((v) => Point.fromMap(v as Map<dynamic, dynamic>))
      .toList();
}

Rect? _parseRect(dynamic data) {
  if (data is! Map) return null;
  return Rect.fromMap(data as Map<dynamic, dynamic>);
}
