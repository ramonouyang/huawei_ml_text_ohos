import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_ml_text_ohos/src/models.dart';

void main() {
  group('TextWord', () {
    test('fromMap with full data', () {
      final word = TextWord.fromMap({
        'stringValue': 'Hello',
        'vertexes': [
          {'x': 10, 'y': 20},
          {'x': 100, 'y': 20},
        ],
      });
      expect(word.stringValue, 'Hello');
      expect(word.vertexes, isNotNull);
      expect(word.vertexes!.length, 2);
      expect(word.toString(), 'Hello');
    });

    test('fromMap with empty map', () {
      final word = TextWord.fromMap({});
      expect(word.stringValue, '');
      expect(word.vertexes, isNull);
    });
  });

  group('TextLine', () {
    test('fromMap with words', () {
      final line = TextLine.fromMap({
        'stringValue': 'Hello World',
        'words': [
          {'stringValue': 'Hello'},
          {'stringValue': 'World'},
        ],
      });
      expect(line.stringValue, 'Hello World');
      expect(line.words.length, 2);
      expect(line.words[0].stringValue, 'Hello');
    });

    test('fromMap with empty words', () {
      final line = TextLine.fromMap({'stringValue': 'Test'});
      expect(line.stringValue, 'Test');
      expect(line.words, isEmpty);
    });
  });

  group('TextBlock', () {
    test('fromMap with lines', () {
      final block = TextBlock.fromMap({
        'stringValue': 'Block text',
        'language': 'zh',
        'lines': [
          {
            'stringValue': 'Line 1',
            'words': [{'stringValue': 'Line'}, {'stringValue': '1'}],
          },
        ],
      });
      expect(block.stringValue, 'Block text');
      expect(block.language, 'zh');
      expect(block.lines.length, 1);
    });
  });

  group('TextRecognitionResult', () {
    test('fromMap builds full text', () {
      final result = TextRecognitionResult.fromMap({
        'blocks': [
          {
            'stringValue': 'Block 1',
            'lines': [
              {'stringValue': 'Line 1', 'words': []},
            ],
          },
          {
            'stringValue': 'Block 2',
            'lines': [
              {'stringValue': 'Line 2', 'words': []},
            ],
          },
        ],
      });
      expect(result.blocks.length, 2);
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
}
