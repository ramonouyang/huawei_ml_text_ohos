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

  group('Character', () {
    test('fromMap with full data', () {
      final char = Character.fromMap({
        'stringValue': 'A',
        'borderRect': {'left': 10, 'top': 20, 'right': 30, 'bottom': 50},
        'confidence': 0.98,
      });
      expect(char.stringValue, 'A');
      expect(char.borderRect, isNotNull);
      expect(char.borderRect!.width, 20.0);
      expect(char.confidence, 0.98);
      expect(char.toString(), 'A');
    });

    test('fromMap with empty map', () {
      final char = Character.fromMap({});
      expect(char.stringValue, '');
      expect(char.borderRect, isNull);
      expect(char.confidence, isNull);
    });
  });

  group('TextElement', () {
    test('fromMap with full data', () {
      final elem = TextElement.fromMap({
        'stringValue': 'Hello',
        'borderRect': {'left': 0, 'top': 0, 'right': 100, 'bottom': 30},
        'cornerPoints': [
          {'x': 0, 'y': 0},
          {'x': 100, 'y': 0},
          {'x': 100, 'y': 30},
          {'x': 0, 'y': 30},
        ],
        'confidence': 0.95,
      });
      expect(elem.stringValue, 'Hello');
      expect(elem.borderRect, isNotNull);
      expect(elem.cornerPoints!.length, 4);
      expect(elem.confidence, 0.95);
    });

    test('fromMap with empty map', () {
      final elem = TextElement.fromMap({});
      expect(elem.stringValue, '');
      expect(elem.borderRect, isNull);
      expect(elem.cornerPoints, isNull);
    });
  });

  group('TextWord', () {
    test('fromMap with full data including characterList', () {
      final word = TextWord.fromMap({
        'stringValue': 'Hi',
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
        'characterList': [
          {
            'stringValue': 'H',
            'confidence': 0.97,
            'borderRect': {'left': 10, 'top': 20, 'right': 50, 'bottom': 50},
          },
          {
            'stringValue': 'i',
            'confidence': 0.93,
            'borderRect': {'left': 50, 'top': 20, 'right': 100, 'bottom': 50},
          },
        ],
      });
      expect(word.stringValue, 'Hi');
      expect(word.vertexes!.length, 2);
      expect(word.cornerPoints!.length, 4);
      expect(word.borderRect, isNotNull);
      expect(word.confidence, 0.95);
      expect(word.language, 'en');
      expect(word.characterList, isNotNull);
      expect(word.characterList!.length, 2);
      expect(word.characterList![0].stringValue, 'H');
      expect(word.characterList![0].confidence, 0.97);
      expect(word.characterList![1].stringValue, 'i');
    });

    test('fromMap with empty map', () {
      final word = TextWord.fromMap({});
      expect(word.stringValue, '');
      expect(word.characterList, isNull);
    });
  });

  group('TextLine', () {
    test('fromMap with characterList and elementList', () {
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
        'characterList': [
          {'stringValue': 'H', 'confidence': 0.97},
          {'stringValue': 'e', 'confidence': 0.96},
        ],
        'elementList': [
          {'stringValue': 'Hello', 'confidence': 0.92},
          {'stringValue': 'World', 'confidence': 0.88},
        ],
      });
      expect(line.stringValue, 'Hello World');
      expect(line.words.length, 2);
      expect(line.characterList, isNotNull);
      expect(line.characterList!.length, 2);
      expect(line.characterList![0].stringValue, 'H');
      expect(line.elementList, isNotNull);
      expect(line.elementList!.length, 2);
      expect(line.elementList![0].stringValue, 'Hello');
    });

    test('fromMap with empty words', () {
      final line = TextLine.fromMap({'stringValue': 'Test'});
      expect(line.stringValue, 'Test');
      expect(line.words, isEmpty);
      expect(line.characterList, isNull);
      expect(line.elementList, isNull);
    });
  });

  group('TextBlock', () {
    test('fromMap with elementList', () {
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
        'elementList': [
          {'stringValue': 'Block', 'confidence': 0.9},
          {'stringValue': 'text', 'confidence': 0.88},
        ],
        'lines': [
          {
            'stringValue': 'Line 1',
            'words': [{'stringValue': 'Line'}, {'stringValue': '1'}],
          },
        ],
      });
      expect(block.stringValue, 'Block text');
      expect(block.elementList, isNotNull);
      expect(block.elementList!.length, 2);
      expect(block.elementList![0].stringValue, 'Block');
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
              {
                'stringValue': 'Line 1',
                'words': [],
                'characterList': [
                  {'stringValue': 'L', 'confidence': 0.95},
                ],
              },
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
      expect(result.blocks[0].lines[0].characterList!.length, 1);
    });

    test('fromMap with null blocks', () {
      final result = TextRecognitionResult.fromMap({});
      expect(result.blocks, isEmpty);
      expect(result.stringValue, '');
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
    });

    test('toMap with languageList', () {
      const config = TextRecognitionConfig(
        languageList: ['zh', 'en'],
      );
      final map = config.toMap();
      expect(map['languageList'], ['zh', 'en']);
    });

    test('toMap with empty config', () {
      const config = TextRecognitionConfig();
      final map = config.toMap();
      expect(map.isEmpty, true);
    });
  });

  group('TextRecognitionException', () {
    test('fromPlatformException maps error codes', () {
      final err = TextRecognitionException.fromPlatformException(
        Exception('code: NOT_INITIALIZED, message: "Not ready"'),
        'fallback',
      );
      expect(err.code, TextRecognitionErrorCode.notInitialized);
      expect(err.message, 'Not ready');
    });

    test('fromPlatformException with unknown code', () {
      final err = TextRecognitionException.fromPlatformException(
        Exception('code: SOMETHING_ELSE, message: "Oops"'),
        'fallback',
      );
      expect(err.code, TextRecognitionErrorCode.unknown);
      expect(err.message, 'Oops');
    });

    test('fromPlatformException with non-Exception', () {
      final err = TextRecognitionException.fromPlatformException(
        'string error',
        'fallback message',
      );
      expect(err.code, TextRecognitionErrorCode.unknown);
      expect(err.message, 'fallback message');
    });

    test('toString', () {
      const err = TextRecognitionException(
        code: TextRecognitionErrorCode.initFailed,
        message: 'init failed',
      );
      expect(err.toString(), 'TextRecognitionException(TextRecognitionErrorCode.initFailed): init failed');
    });
  });
}
