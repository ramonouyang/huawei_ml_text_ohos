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
        case 'text#isAvailable':
          return true;
        case 'text#isModelAvailable':
          return true;
        case 'text#init':
          return true;
        case 'text#recognizeText':
          return _mockRecognitionResult();
        case 'text#recognizeImage':
          return _mockRecognitionResult();
        case 'text#recognizeTextBatch':
          return [_mockRecognitionResult(), _mockRecognitionResult(), null];
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

  group('Availability', () {
    test('isAvailable returns true when service ready', () async {
      final result = await analyzer.isAvailable();
      expect(result, true);
      expect(log[0].method, 'text#isAvailable');
    });

    test('isAvailable returns false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => throw Exception('no HMS'));
      final result = await analyzer.isAvailable();
      expect(result, false);
    });

    test('isModelAvailable returns true when model ready', () async {
      final result = await analyzer.isModelAvailable();
      expect(result, true);
      expect(log[0].method, 'text#isModelAvailable');
    });

    test('isModelAvailable returns false on error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => throw Exception('no model'));
      final result = await analyzer.isModelAvailable();
      expect(result, false);
    });
  });

  group('Init / Release', () {
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

    test('release returns true and resets state', () async {
      await analyzer.init();
      log.clear();
      final result = await analyzer.release();
      expect(result, true);
      expect(analyzer.isInitialized, false);
      expect(log[0].method, 'text#release');
    });

    test('release is idempotent when not initialized', () async {
      final result = await analyzer.release();
      expect(result, true);
      expect(log.isEmpty, true);
    });
  });

  group('recognizeText', () {
    test('throws if not initialized', () async {
      expect(
        () => analyzer.recognizeText('/path/to/image.jpg'),
        throwsA(isA<TextRecognitionException>().having(
          (e) => e.code,
          'code',
          TextRecognitionErrorCode.notInitialized,
        )),
      );
    });

    test('returns full structured result', () async {
      await analyzer.init();
      log.clear();

      final result = await analyzer.recognizeText('/path/to/image.jpg');

      expect(log[0].method, 'text#recognizeText');
      expect(result.text, 'Hello World');
      expect(result.blocks.length, 1);

      final block = result.blocks[0];
      expect(block.confidence, 0.95);
      expect(block.borderRect, isNotNull);
      expect(block.elementList!.length, 1);

      final line = block.lines[0];
      expect(line.characterList!.length, 2);
      expect(line.elementList!.length, 1);

      final word = line.words[0];
      expect(word.characterList!.length, 1);
      expect(word.characterList![0].stringValue, 'H');
    });

    test('passes config to channel', () async {
      await analyzer.init();
      log.clear();

      await analyzer.recognizeText(
        '/path/to/image.jpg',
        config: const TextRecognitionConfig(
          language: 'zh',
          isFastMode: true,
          isDirectionSupported: true,
          enableCloud: true,
          roi: Rect(left: 10, top: 20, right: 100, bottom: 200),
        ),
      );

      final args = log[0].arguments as Map;
      expect(args['config']['language'], 'zh');
      expect(args['config']['isFastMode'], true);
      expect(args['config']['enableCloud'], true);
      expect(args['config']['roi']['left'], 10);
      expect(args['config']['roi']['right'], 100);
    });

    test('without config omits config key', () async {
      await analyzer.init();
      log.clear();
      await analyzer.recognizeText('/path/to/image.jpg');
      final args = log[0].arguments as Map;
      expect(args.containsKey('config'), false);
    });

    test('throws TextRecognitionException on null result', () async {
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
  });

  group('recognizeImage', () {
    test('from file path delegates to recognizeText', () async {
      await analyzer.init();
      log.clear();

      final result = await analyzer.recognizeImage(
        const ImageSource.filePath('/path/to/image.jpg'),
      );

      expect(log[0].method, 'text#recognizeText');
      expect(result.text, 'Hello World');
    });

    test('from URL sends recognizeImage', () async {
      await analyzer.init();
      log.clear();

      final result = await analyzer.recognizeImage(
        const ImageSource.url('https://example.com/image.jpg'),
      );

      expect(log[0].method, 'text#recognizeImage');
      final args = log[0].arguments as Map;
      expect(args['imageSource']['type'], 'url');
      expect(args['imageSource']['url'], 'https://example.com/image.jpg');
      expect(result.text, 'Hello World');
    });

    test('throws if not initialized', () async {
      expect(
        () => analyzer.recognizeImage(const ImageSource.url('https://x.com/i.jpg')),
        throwsA(isA<TextRecognitionException>()),
      );
    });
  });

  group('recognizeTextBatch', () {
    test('returns list of results with nulls for failures', () async {
      await analyzer.init();
      log.clear();

      final results = await analyzer.recognizeTextBatch([
        '/img1.jpg',
        '/img2.jpg',
        '/img3.jpg',
      ]);

      expect(results.length, 3);
      expect(results[0], isNotNull);
      expect(results[0]!.text, 'Hello World');
      expect(results[1], isNotNull);
      expect(results[2], isNull);

      expect(log[0].method, 'text#recognizeTextBatch');
      final args = log[0].arguments as Map;
      expect(args['imagePaths'].length, 3);
    });

    test('passes config to batch call', () async {
      await analyzer.init();
      log.clear();

      await analyzer.recognizeTextBatch(
        ['/img1.jpg'],
        config: const TextRecognitionConfig(language: 'zh'),
      );

      final args = log[0].arguments as Map;
      expect(args['config']['language'], 'zh');
    });

    test('throws if not initialized', () async {
      expect(
        () => analyzer.recognizeTextBatch(['/img.jpg']),
        throwsA(isA<TextRecognitionException>()),
      );
    });
  });

  group('recognizeTextAsync', () {
    test('yields result', () async {
      await analyzer.init();
      log.clear();

      final results = <TextRecognitionResult>[];
      await for (final r in analyzer.recognizeTextAsync('/path/to/image.jpg')) {
        results.add(r);
      }

      expect(results.length, 1);
      expect(results[0].text, 'Hello World');
      final args = log[0].arguments as Map;
      expect(args['async'], true);
    });

    test('throws if not initialized', () async {
      expect(
        () => analyzer.recognizeTextAsync('/path/to/image.jpg').toList(),
        throwsA(isA<TextRecognitionException>()),
      );
    });
  });

  group('getSupportedLanguages', () {
    test('returns list', () async {
      final languages = await analyzer.getSupportedLanguages();
      expect(languages, ['zh', 'en', 'ja', 'ko']);
    });

    test('returns empty on null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      final languages = await analyzer.getSupportedLanguages();
      expect(languages, isEmpty);
    });
  });

  group('Full lifecycle', () {
    test('init -> recognize -> release -> reinit', () async {
      await analyzer.init();
      expect(analyzer.isInitialized, true);

      final result = await analyzer.recognizeText('/test.jpg');
      expect(result.text, isNotEmpty);
      expect(result.blocks[0].confidence, isNotNull);

      await analyzer.release();
      expect(analyzer.isInitialized, false);

      await analyzer.init();
      expect(analyzer.isInitialized, true);
    });
  });
}

/// Mock recognition result with all fields.
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
