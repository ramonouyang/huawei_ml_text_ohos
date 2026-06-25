import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_ml_text_ohos/src/models.dart';
import 'package:huawei_ml_text_ohos/src/text_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('huawei.hms.flutter.ml.text');
  late HuaweiMlTextAnalyzer analyzer;

  final log = <MethodCall>[];

  setUp(() {
    analyzer = HuaweiMlTextAnalyzer();
    log.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'text#init':
          return true;
        case 'text#recognizeText':
          return _mockRecognitionResult();
        case 'text#getSupportedLanguages':
          return ['zh', 'en', 'ja', 'ko'];
        case 'text#release':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('HuaweiMlTextAnalyzer', () {
    test('init returns true on success', () async {
      final result = await analyzer.init();
      expect(result, true);
      expect(analyzer.isInitialized, true);
      expect(log.length, 1);
      expect(log[0].method, 'text#init');
    });

    test('init is idempotent', () async {
      await analyzer.init();
      await analyzer.init();
      expect(log.length, 1);
    });

    test('recognizeText throws TextRecognitionException if not initialized', () async {
      expect(
        () => analyzer.recognizeText('/path/to/image.jpg'),
        throwsA(isA<TextRecognitionException>().having(
          (e) => e.code,
          'code',
          TextRecognitionErrorCode.notInitialized,
        )),
      );
    });

    test('recognizeText returns full structured result', () async {
      await analyzer.init();
      log.clear();

      final result = await analyzer.recognizeText('/path/to/image.jpg');

      // Verify method call
      expect(log.length, 1);
      expect(log[0].method, 'text#recognizeText');
      expect(log[0].arguments, {'imagePath': '/path/to/image.jpg'});

      // Verify top-level
      expect(result.text, 'Hello World');
      expect(result.blocks.length, 1);

      // Verify block
      final block = result.blocks[0];
      expect(block.stringValue, 'Hello World');
      expect(block.language, 'en');
      expect(block.confidence, 0.95);
      expect(block.angle, 0.5);
      expect(block.isVertical, false);
      expect(block.vertexes!.length, 4);
      expect(block.cornerPoints!.length, 4);
      expect(block.borderRect, isNotNull);
      expect(block.borderRect!.width, 200);
      expect(block.elementList, isNotNull);
      expect(block.elementList!.length, 1);
      expect(block.elementList![0].stringValue, 'Hello');

      // Verify line
      final line = block.lines[0];
      expect(line.stringValue, 'Hello World');
      expect(line.language, 'en');
      expect(line.confidence, 0.93);
      expect(line.borderRect, isNotNull);
      expect(line.characterList, isNotNull);
      expect(line.characterList!.length, 2);
      expect(line.characterList![0].stringValue, 'H');
      expect(line.elementList, isNotNull);
      expect(line.elementList!.length, 1);

      // Verify words
      expect(line.words.length, 2);
      expect(line.words[0].stringValue, 'Hello');
      expect(line.words[0].confidence, 0.97);
      expect(line.words[0].language, 'en');
      expect(line.words[0].borderRect, isNotNull);
      expect(line.words[0].characterList, isNotNull);
      expect(line.words[0].characterList!.length, 1);
      expect(line.words[0].characterList![0].stringValue, 'H');
      expect(line.words[0].characterList![0].confidence, 0.98);

      expect(line.words[1].stringValue, 'World');
      expect(line.words[1].confidence, 0.91);
      expect(line.words[1].characterList!.length, 1);
      expect(line.words[1].characterList![0].stringValue, 'W');
    });

    test('recognizeText passes config to channel', () async {
      await analyzer.init();
      log.clear();

      await analyzer.recognizeText(
        '/path/to/image.jpg',
        config: const TextRecognitionConfig(
          language: 'zh',
          isFastMode: true,
          isDirectionSupported: true,
        ),
      );

      expect(log.length, 1);
      final args = log[0].arguments as Map;
      expect(args['config']['language'], 'zh');
      expect(args['config']['isFastMode'], true);
      expect(args['config']['isDirectionSupported'], true);
    });

    test('recognizeText without config omits config key', () async {
      await analyzer.init();
      log.clear();

      await analyzer.recognizeText('/path/to/image.jpg');

      final args = log[0].arguments as Map;
      expect(args.containsKey('config'), false);
    });

    test('recognizeText throws TextRecognitionException on null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'text#init') return true;
        return null;
      });

      await analyzer.init();
      expect(
        () => analyzer.recognizeText('/path/to/image.jpg'),
        throwsA(isA<TextRecognitionException>().having(
          (e) => e.code,
          'code',
          TextRecognitionErrorCode.nullResult,
        )),
      );
    });

    test('recognizeTextAsync yields result', () async {
      await analyzer.init();
      log.clear();

      final results = <TextRecognitionResult>[];
      await for (final r in analyzer.recognizeTextAsync('/path/to/image.jpg')) {
        results.add(r);
      }

      expect(results.length, 1);
      expect(results[0].text, 'Hello World');

      // Verify async flag passed
      final args = log[0].arguments as Map;
      expect(args['async'], true);
    });

    test('recognizeTextAsync throws if not initialized', () async {
      expect(
        () => analyzer.recognizeTextAsync('/path/to/image.jpg').toList(),
        throwsA(isA<TextRecognitionException>().having(
          (e) => e.code,
          'code',
          TextRecognitionErrorCode.notInitialized,
        )),
      );
    });

    test('getSupportedLanguages returns list', () async {
      final languages = await analyzer.getSupportedLanguages();
      expect(languages, ['zh', 'en', 'ja', 'ko']);
    });

    test('getSupportedLanguages returns empty on null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null;
      });

      final languages = await analyzer.getSupportedLanguages();
      expect(languages, isEmpty);
    });

    test('release returns true and resets state', () async {
      await analyzer.init();
      expect(analyzer.isInitialized, true);
      log.clear();

      final result = await analyzer.release();
      expect(result, true);
      expect(analyzer.isInitialized, false);
      expect(log.length, 1);
      expect(log[0].method, 'text#release');
    });

    test('release is idempotent when not initialized', () async {
      final result = await analyzer.release();
      expect(result, true);
      expect(log.isEmpty, true);
    });

    test('full lifecycle: init -> recognize -> release', () async {
      await analyzer.init();
      expect(analyzer.isInitialized, true);

      final result = await analyzer.recognizeText('/test.jpg');
      expect(result.text, isNotEmpty);
      expect(result.blocks[0].confidence, isNotNull);
      expect(result.blocks[0].lines[0].characterList, isNotNull);

      await analyzer.release();
      expect(analyzer.isInitialized, false);

      await analyzer.init();
      expect(analyzer.isInitialized, true);
    });
  });
}

/// Mock recognition result with all fields including Character and Element.
Map<String, dynamic> _mockRecognitionResult() {
  return {
    'stringValue': 'Hello World',
    'blocks': [
      {
        'stringValue': 'Hello World',
        'language': 'en',
        'confidence': 0.95,
        'angle': 0.5,
        'isVertical': false,
        'vertexes': [
          {'x': 0, 'y': 0},
          {'x': 200, 'y': 0},
          {'x': 200, 'y': 50},
          {'x': 0, 'y': 50},
        ],
        'cornerPoints': [
          {'x': 0, 'y': 0},
          {'x': 200, 'y': 0},
          {'x': 200, 'y': 50},
          {'x': 0, 'y': 50},
        ],
        'borderRect': {'left': 0, 'top': 0, 'right': 200, 'bottom': 50},
        'elementList': [
          {
            'stringValue': 'Hello',
            'confidence': 0.94,
            'borderRect': {'left': 0, 'top': 0, 'right': 100, 'bottom': 30},
          },
        ],
        'lines': [
          {
            'stringValue': 'Hello World',
            'language': 'en',
            'confidence': 0.93,
            'angle': 0.5,
            'isVertical': false,
            'vertexes': [
              {'x': 0, 'y': 0},
              {'x': 200, 'y': 0},
            ],
            'cornerPoints': [
              {'x': 0, 'y': 0},
              {'x': 200, 'y': 0},
              {'x': 200, 'y': 30},
              {'x': 0, 'y': 30},
            ],
            'borderRect': {'left': 0, 'top': 0, 'right': 200, 'bottom': 30},
            'characterList': [
              {
                'stringValue': 'H',
                'confidence': 0.98,
                'borderRect': {'left': 0, 'top': 0, 'right': 20, 'bottom': 30},
              },
              {
                'stringValue': 'e',
                'confidence': 0.96,
                'borderRect': {'left': 20, 'top': 0, 'right': 40, 'bottom': 30},
              },
            ],
            'elementList': [
              {
                'stringValue': 'Hello World',
                'confidence': 0.92,
                'borderRect': {'left': 0, 'top': 0, 'right': 200, 'bottom': 30},
              },
            ],
            'words': [
              {
                'stringValue': 'Hello',
                'language': 'en',
                'confidence': 0.97,
                'vertexes': [
                  {'x': 0, 'y': 0},
                  {'x': 100, 'y': 0},
                ],
                'cornerPoints': [
                  {'x': 0, 'y': 0},
                  {'x': 100, 'y': 0},
                  {'x': 100, 'y': 30},
                  {'x': 0, 'y': 30},
                ],
                'borderRect': {'left': 0, 'top': 0, 'right': 100, 'bottom': 30},
                'characterList': [
                  {
                    'stringValue': 'H',
                    'confidence': 0.98,
                    'borderRect': {'left': 0, 'top': 0, 'right': 20, 'bottom': 30},
                  },
                ],
              },
              {
                'stringValue': 'World',
                'language': 'en',
                'confidence': 0.91,
                'vertexes': [
                  {'x': 100, 'y': 0},
                  {'x': 200, 'y': 0},
                ],
                'cornerPoints': [
                  {'x': 100, 'y': 0},
                  {'x': 200, 'y': 0},
                  {'x': 200, 'y': 30},
                  {'x': 100, 'y': 30},
                ],
                'borderRect': {'left': 100, 'top': 0, 'right': 200, 'bottom': 30},
                'characterList': [
                  {
                    'stringValue': 'W',
                    'confidence': 0.95,
                    'borderRect': {'left': 100, 'top': 0, 'right': 120, 'bottom': 30},
                  },
                ],
              },
            ],
          },
        ],
      },
    ],
  };
}
