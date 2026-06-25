/// Data models for Core Vision Kit text recognition results.
///
/// Mirrors the HMS ML Kit TextBlock/TextLine/TextWord hierarchy
/// from HMS-Core/hms-flutter-plugin/flutter-hms-mltext.

/// A recognized word (smallest unit).
class TextWord {
  final String stringValue;
  final List<Offset>? vertexes;

  const TextWord({required this.stringValue, this.vertexes});

  factory TextWord.fromMap(Map<dynamic, dynamic> map) {
    return TextWord(
      stringValue: map['stringValue'] as String? ?? '',
      vertexes: (map['vertexes'] as List?)
          ?.map((v) => Offset(
                (v['x'] as num?)?.toDouble() ?? 0,
                (v['y'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
    );
  }

  @override
  String toString() => stringValue;
}

/// A recognized line of text.
class TextLine {
  final String stringValue;
  final List<TextWord> words;
  final List<Offset>? vertexes;

  const TextLine({
    required this.stringValue,
    required this.words,
    this.vertexes,
  });

  factory TextLine.fromMap(Map<dynamic, dynamic> map) {
    return TextLine(
      stringValue: map['stringValue'] as String? ?? '',
      words: (map['words'] as List?)
              ?.map((w) => TextWord.fromMap(w as Map<dynamic, dynamic>))
              .toList() ??
          [],
      vertexes: (map['vertexes'] as List?)
          ?.map((v) => Offset(
                (v['x'] as num?)?.toDouble() ?? 0,
                (v['y'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
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
  final List<Offset>? vertexes;

  const TextBlock({
    required this.stringValue,
    this.language,
    required this.lines,
    this.vertexes,
  });

  factory TextBlock.fromMap(Map<dynamic, dynamic> map) {
    return TextBlock(
      stringValue: map['stringValue'] as String? ?? '',
      language: map['language'] as String?,
      lines: (map['lines'] as List?)
              ?.map((l) => TextLine.fromMap(l as Map<dynamic, dynamic>))
              .toList() ??
          [],
      vertexes: (map['vertexes'] as List?)
          ?.map((v) => Offset(
                (v['x'] as num?)?.toDouble() ?? 0,
                (v['y'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
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
    // Build full text from all blocks
    final fullText = blocks.map((b) => b.stringValue).join('\n');
    return TextRecognitionResult(
      blocks: blocks,
      stringValue: map['stringValue'] as String? ?? fullText,
    );
  }

  /// All recognized text as a single string.
  String get text => stringValue;
}

/// Simple 2D offset for vertex points.
class Offset {
  final double x;
  final double y;

  const Offset(this.x, this.y);

  @override
  String toString() => '($x, $y)';
}
