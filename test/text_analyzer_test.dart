import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huawei_ml_text_ohos/src/text_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('huawei.hms.flutter.ml.text');
  late HuaweiMlTextAnalyzer analyzer;

  // Track method calls
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
          return {
            'stringValue': 'Hello World',
            'blocks': [
              {
                'stringValue': 'Hello World',
                'language': 'en',
                'vertexes': [
                  {'x': 0, 'y': 0},
                  {'x': 200, 'y': 0},
                  {'x': 200, 'y': 50},
                  {'x': 0, 'y': 50},
                ],
                'lines': [
                  {
                    'stringValue': 'Hello World',
                    'vertexes': [
                      {'x': 0, 'y': 0},
                      {'x': 200, 'y': 0},
                    ],
                    'words': [
                      {
                        'stringValue': 'Hello',
                        'vertexes': [
                          {'x': 0, 'y': 0},
                          {'x': 100, 'y': 0},
                        ],
                      },
                      {
                        'stringValue': 'World',
                        'vertexes': [
                          {'x': 100, 'y': 0},
                          {'x': 200, 'y': 0},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          };
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
      await analyzer.init(); // Should not call channel again
      expect(log.length, 1); // Only one call
    });

    test('recognizeText throws if not initialized', () async {
      expect(
        () => analyzer.recognizeText('/path/to/image.jpg'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not initialized'),
        )),
      );
    });

    test('recognizeText returns structured result', () async {
      await analyzer.init();
      log.clear();

      final result = await analyzer.recognizeText('/path/to/image.jpg');

      // Verify method call
      expect(log.length, 1);
      expect(log[0].method, 'text#recognizeText');
      expect(log[0].arguments, {'imagePath': '/path/to/image.jpg'});

      // Verify result structure
      expect(result.text, 'Hello World');
      expect(result.blocks.length, 1);

      final block = result.blocks[0];
      expect(block.stringValue, 'Hello World');
      expect(block.language, 'en');
      expect(block.vertexes!.length, 4);
      expect(block.lines.length, 1);

      final line = block.lines[0];
      expect(line.stringValue, 'Hello World');
      expect(line.words.length, 2);
      expect(line.words[0].stringValue, 'Hello');
      expect(line.words[1].stringValue, 'World');
    });

    test('recognizeText throws PlatformException on null result', () async {
      // Override mock to return null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'text#init') return true;
        return null; // Simulate null result
      });

      await analyzer.init();
      expect(
        () => analyzer.recognizeText('/path/to/image.jpg'),
        throwsA(isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'NULL_RESULT',
        )),
      );
    });

    test('getSupportedLanguages returns list', () async {
      final languages = await analyzer.getSupportedLanguages();
      expect(languages, ['zh', 'en', 'ja', 'ko']);
      expect(log[0].method, 'text#getSupportedLanguages');
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
      expect(log.isEmpty, true); // No channel call
    });

    test('full lifecycle: init -> recognize -> release', () async {
      // Init
      await analyzer.init();
      expect(analyzer.isInitialized, true);

      // Recognize
      final result = await analyzer.recognizeText('/test.jpg');
      expect(result.text, isNotEmpty);

      // Release
      await analyzer.release();
      expect(analyzer.isInitialized, false);

      // Can re-init
      await analyzer.init();
      expect(analyzer.isInitialized, true);
    });
  });
}
