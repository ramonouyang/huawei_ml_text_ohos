import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_ml_text_ohos/src/models.dart';

void main() {
  group('Point', () {
    test('fromMap with coordinates', () {
      final point = Point.fromMap({'x': 10, 'y': 20});
      expect(point.x, 10.0);
      expect(point.y, 20.0);
      expect(point.toString(), '(10.0, 20.0)');
    });

    test('fromMap with empty map defaults to zero', () {
      final point = Point.fromMap({});
      expect(point.x, 0.0);
      expect(point.y, 0.0);
    });

    test('equality', () {
      expect(const Point(1, 2), const Point(1, 2));
      expect(const Point(1, 2) == const Point(3, 4), false);
    });
  });

  group('Rect', () {
    test('fromMap with full data', () {
      final rect = Rect.fromMap({'left': 10, 'top': 20, 'right': 100, 'bottom': 200});
      expect(rect.left, 10.0);
      expect(rect.top, 20.0);
      expect(rect.right, 100.0);
      expect(rect.bottom, 200.0);
      expect(rect.width, 90.0);
      expect(rect.height, 180.0);
    });

    test('fromMap with empty map defaults to zero', () {
      final rect = Rect.fromMap({});
      expect(rect.left, 0.0);
      expect(rect.width, 0.0);
    });

    test('equality', () {
      const r1 = Rect(left: 0, top: 0, right: 10, bottom: 10);
      const r2 = Rect(left: 0, top: 0, right: 10, bottom: 10);
      expect(r1, r2);
    });
  });

  group('TextWord', () {
    test('fromMap with full data', () {
      final word = TextWord.fromMap({
        'stringValue': 'Hello',
        'vertexes': [
          {'x': 10, 'y': 20},
          {'x': 100, 'y': 20},
        ],
        'cornerPoints': [
          {'x': 10, 'y': 20},
          {'x': 100, 'y': 20},
          {'x': 100, 'y': 50},
          {'x': 10, 'y': 50},
        ],
        'borderRect': {'left': 10, 'top': 20, 'right': 100, 'bottom': 50},
        'confidence': 0.95,
        'language': 'en',
      });
      expect(word.stringValue, 'Hello');
      expect(word.vertexes!.length, 2);
      expect(word.cornerPoints!.length, 4);
      expect(word.borderRect, isNotNull);
      expect(word.borderRect!.width, 90.0);
      expect(word.confidence, 0.95);
      expect(word.language, 'en');
    });

    test('fromMap with empty map', () {
      final word = TextWord.fromMap({});
      expect(word.stringValue, '');
      expect(word.vertexes, isNull);
      expect(word.cornerPoints, isNull);
      expect(word.borderRect, isNull);
      expect(word.confidence, isNull);
      expect(word.language, isNull);
    });

    test('toString returns stringValue', () {
      final word = TextWord.fromMap({'stringValue': 'Test'});
      expect(word.toString(), 'Test');
    });
  });

  group('TextLine', () {
    test('fromMap with words and position', () {
      final line = TextLine.fromMap({
        'stringValue': 'Hello World',
        'words': [
          {'stringValue': 'Hello', 'confidence': 0.9},
          {'stringValue': 'World', 'confidence': 0.85},
        ],
        'borderRect': {'left': 0, 'top': 0, 'right': 200, 'bottom': 30},
        'confidence': 0.88,
        'language': 'en',
        'angle': 0.5,
        'isVertical': false,
      });
      expect(line.stringValue, 'Hello World');
      expect(line.words.length, 2);
      expect(line.words[0].confidence, 0.9);
      expect(line.borderRect, isNotNull);
      expect(line.confidence, 0.88);
      expect(line.language, 'en');
      expect(line.angle, 0.5);
      expect(line.isVertical, false);
    });

    test('fromMap with empty words', () {
      final line = TextLine.fromMap({'stringValue': 'Test'});
      expect(line.stringValue, 'Test');
      expect(line.words, isEmpty);
      expect(line.borderRect, isNull);
    });
  });

  group('TextBlock', () {
    test('fromMap with lines and position', () {
      final block = TextBlock.fromMap({
        'stringValue': 'Block text',
        'language': 'zh',
        'confidence': 0.92,
        'angle': 1.5,
        'isVertical': true,
        'borderRect': {'left': 10, 'top': 20, 'right': 300, 'bottom': 100},
        'cornerPoints': [
          {'x': 10, 'y': 20},
          {'x': 300, 'y': 20},
          {'x': 300, 'y': 100},
          {'x': 10, 'y': 100},
        ],
        'lines': [
          {
            'stringValue': 'Line 1',
            'words': [{'stringValue': 'Line'}, {'stringValue': '1'}],
          },
        ],
      });
      expect(block.stringValue, 'Block text');
      expect(block.language, 'zh');
      expect(block.confidence, 0.92);
      expect(block.angle, 1.5);
      expect(block.isVertical, true);
      expect(block.borderRect, isNotNull);
      expect(block.borderRect!.width, 290.0);
      expect(block.cornerPoints!.length, 4);
      expect(block.lines.length, 1);
    });

    test('fromMap with minimal data', () {
      final block = TextBlock.fromMap({'stringValue': 'Minimal'});
      expect(block.stringValue, 'Minimal');
      expect(block.language, isNull);
      expect(block.confidence, isNull);
      expect(block.borderRect, isNull);
    });
  });

  group('TextRecognitionResult', () {
    test('fromMap builds full text', () {
      final result = TextRecognitionResult.fromMap({
        'blocks': [
          {
            'stringValue': 'Block 1',
            'confidence': 0.9,
            'lines': [
              {'stringValue': 'Line 1', 'words': []},
            ],
          },
          {
            'stringValue': 'Block 2',
            'confidence': 0.8,
            'lines': [
              {'stringValue': 'Line 2', 'words': []},
            ],
          },
        ],
      });
      expect(result.blocks.length, 2);
      expect(result.blocks[0].confidence, 0.9);
      expect(result.blocks[1].confidence, 0.8);
      expect(result.text, contains('Block 1'));
      expect(result.text, contains('Block 2'));
    });

    test('fromMap with null blocks', () {
      final result = TextRecognitionResult.fromMap({});
      expect(result.blocks, isEmpty);
      expect(result.stringValue, '');
    });

    test('explicit stringValue overrides joined text', () {
      final result = TextRecognitionResult.fromMap({
        'stringValue': 'Custom text',
        'blocks': [
          {'stringValue': 'A', 'lines': []},
          {'stringValue': 'B', 'lines': []},
        ],
      });
      expect(result.text, 'Custom text');
    });
  });

  group('TextRecognitionConfig', () {
    test('toMap with all fields', () {
      const config = TextRecognitionConfig(
        language: 'zh',
        isFastMode: true,
        isDirectionSupported: true,
      );
      final map = config.toMap();
      expect(map['language'], 'zh');
      expect(map['isFastMode'], true);
      expect(map['isDirectionSupported'], true);
      expect(map.containsKey('languageList'), false);
    });

    test('toMap with languageList', () {
      const config = TextRecognitionConfig(
        languageList: ['zh', 'en'],
      );
      final map = config.toMap();
      expect(map['languageList'], ['zh', 'en']);
      expect(map.containsKey('language'), false);
    });

    test('toMap with empty config', () {
      const config = TextRecognitionConfig();
      final map = config.toMap();
      expect(map.isEmpty, true);
    });
  });
}
