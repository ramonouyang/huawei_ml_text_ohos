import { textRecognition } from '@kit.CoreVisionKit';
import { FlutterPlugin, MethodCall, MethodResult, MethodChannel } from '@ohos/flutter_ohos/ets/plugin';

const TAG = 'HuaweiMlTextPlugin';
const CHANNEL_NAME = 'huawei.hms.flutter.ml.text';

/**
 * Flutter plugin wrapping HarmonyOS Core Vision Kit textRecognition.
 *
 * Methods handled:
 *   text#init              — Initialize the recognition engine
 *   text#recognizeText     — Recognize text in an image file
 *   text#getSupportedLanguages — List supported languages
 *   text#release           — Release the engine
 */
export default class HuaweiMlTextPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private initialized = false;

  onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this.onMethodCall.bind(this));
    console.info(TAG, 'Plugin attached to engine');
  }

  onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    if (this.initialized) {
      this.doRelease();
    }
    console.info(TAG, 'Plugin detached from engine');
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'text#init':
        this.handleInit(result);
        break;
      case 'text#recognizeText':
        this.handleRecognizeText(call, result);
        break;
      case 'text#getSupportedLanguages':
        this.handleGetSupportedLanguages(result);
        break;
      case 'text#release':
        this.handleRelease(result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * Initialize the text recognition engine.
   * Returns true on success.
   */
  private handleInit(result: MethodResult): void {
    if (this.initialized) {
      result.success(true);
      return;
    }
    try {
      textRecognition.init();
      this.initialized = true;
      console.info(TAG, 'textRecognition.init() succeeded');
      result.success(true);
    } catch (err) {
      console.error(TAG, `textRecognition.init() failed: ${err}`);
      result.error('INIT_FAILED', `Failed to init textRecognition: ${err}`, null);
    }
  }

  /**
   * Recognize text in the image at the given path.
   * Input: { imagePath: string }
   * Output: { blocks: [...], stringValue: string }
   */
  private handleRecognizeText(call: MethodCall, result: MethodResult): void {
    if (!this.initialized) {
      result.error('NOT_INITIALIZED', 'Call text#init first', null);
      return;
    }

    const imagePath = call.argument('imagePath') as string;
    if (!imagePath) {
      result.error('INVALID_ARGS', 'imagePath is required', null);
      return;
    }

    try {
      // Build VisionInfo from the image path
      const visionInfo: textRecognition.VisionInfo = {
        uri: imagePath
      };

      const config: textRecognition.TextRecognitionConfiguration = {
        // Default: recognize all languages
      };

      textRecognition.recognizeText(visionInfo, config)
        .then((recognitionResult: textRecognition.TextRecognitionResult) => {
          const resultMap = this.convertResult(recognitionResult);
          console.info(TAG, `Recognized ${resultMap.blocks.length} blocks`);
          result.success(resultMap);
        })
        .catch((err: Error) => {
          console.error(TAG, `recognizeText failed: ${err.message}`);
          result.error('RECOGNIZE_FAILED', err.message, null);
        });
    } catch (err) {
      console.error(TAG, `recognizeText error: ${err}`);
      result.error('RECOGNIZE_FAILED', `Recognition failed: ${err}`, null);
    }
  }

  /**
   * Get list of supported languages.
   * Output: string[]
   */
  private handleGetSupportedLanguages(result: MethodResult): void {
    try {
      const languages = textRecognition.getSupportedLanguages();
      result.success(languages);
    } catch (err) {
      console.error(TAG, `getSupportedLanguages failed: ${err}`);
      result.error('LANGUAGES_FAILED', `Failed to get languages: ${err}`, null);
    }
  }

  /**
   * Release the recognition engine.
   * Returns true on success.
   */
  private handleRelease(result: MethodResult): void {
    this.doRelease();
    result.success(true);
  }

  private doRelease(): void {
    try {
      textRecognition.release();
      this.initialized = false;
      console.info(TAG, 'textRecognition.release() succeeded');
    } catch (err) {
      console.error(TAG, `textRecognition.release() failed: ${err}`);
    }
  }

  /**
   * Convert ArkTS TextRecognitionResult to a Map for Dart.
   *
   * Structure:
   * {
   *   stringValue: string,
   *   blocks: [
   *     {
   *       stringValue: string,
   *       language: string,
   *       vertexes: [{x, y}],
   *       lines: [
   *         {
   *           stringValue: string,
   *           vertexes: [{x, y}],
   *           words: [
   *             { stringValue: string, vertexes: [{x, y}] }
   *           ]
   *         }
   *       ]
   *     }
   *   ]
   * }
   */
  private convertResult(result: textRecognition.TextRecognitionResult): object {
    const blocks = (result.blocks ?? []).map((block) => ({
      stringValue: block.stringValue ?? '',
      language: block.language ?? '',
      vertexes: this.convertPoints(block.vertexes),
      lines: (block.lines ?? []).map((line) => ({
        stringValue: line.stringValue ?? '',
        vertexes: this.convertPoints(line.vertexes),
        words: (line.words ?? []).map((word) => ({
          stringValue: word.stringValue ?? '',
          vertexes: this.convertPoints(word.vertexes),
        })),
      })),
    }));

    const fullText = blocks.map((b: { stringValue: string }) => b.stringValue).join('\n');

    return {
      stringValue: result.stringValue ?? fullText,
      blocks: blocks,
    };
  }

  private convertPoints(points: textRecognition.PixelPoint[] | undefined): object[] {
    if (!points) return [];
    return points.map((p) => ({ x: p.x ?? 0, y: p.y ?? 0 }));
  }
}
