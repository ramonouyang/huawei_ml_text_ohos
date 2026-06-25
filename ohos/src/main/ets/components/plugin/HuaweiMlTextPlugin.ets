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
   * Input: { imagePath: string, config?: { language?, languageList?, isFastMode?, isDirectionSupported? } }
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
      const visionInfo: textRecognition.VisionInfo = {
        uri: imagePath
      };

      // Build configuration from optional config parameter
      const configMap = call.argument('config') as Record<string, Object> | undefined;
      const config = this.buildConfig(configMap);

      textRecognition.recognizeText(visionInfo, config)
        .then((recognitionResult: textRecognition.TextRecognitionResult) => {
          const resultMap = this.convertResult(recognitionResult);
          console.info(TAG, `Recognized ${(resultMap as { blocks: object[] }).blocks.length} blocks`);
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
   * Build TextRecognitionConfiguration from Dart config map.
   */
  private buildConfig(configMap: Record<string, Object> | undefined): textRecognition.TextRecognitionConfiguration {
    const config: textRecognition.TextRecognitionConfiguration = {};

    if (configMap) {
      if (configMap['language'] !== undefined) {
        config.language = configMap['language'] as string;
      }
      if (configMap['languageList'] !== undefined) {
        config.languageList = configMap['languageList'] as string[];
      }
      if (configMap['isFastMode'] !== undefined) {
        config.textType = (configMap['isFastMode'] as boolean)
          ? textRecognition.TextType.TEXT_TYPE_FAST
          : textRecognition.TextType.TEXT_TYPE_LOOSE;
      }
      if (configMap['isDirectionSupported'] !== undefined) {
        config.isDirectionSupported = configMap['isDirectionSupported'] as boolean;
      }
    }

    return config;
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
   *       confidence: number,
   *       angle: number,
   *       isVertical: boolean,
   *       vertexes: [{x, y}],
   *       cornerPoints: [{x, y}],
   *       borderRect: {left, top, right, bottom},
   *       lines: [
   *         {
   *           stringValue: string,
   *           language: string,
   *           confidence: number,
   *           angle: number,
   *           isVertical: boolean,
   *           vertexes: [{x, y}],
   *           cornerPoints: [{x, y}],
   *           borderRect: {left, top, right, bottom},
   *           words: [
   *             {
   *               stringValue: string,
   *               language: string,
   *               confidence: number,
   *               vertexes: [{x, y}],
   *               cornerPoints: [{x, y}],
   *               borderRect: {left, top, right, bottom}
   *             }
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
      confidence: block.confidence ?? -1,
      angle: block.angle ?? 0,
      isVertical: block.isVertical ?? false,
      vertexes: this.convertPoints(block.vertexes),
      cornerPoints: this.convertPoints(block.cornerPoints),
      borderRect: this.convertRect(block.borderRect),
      lines: (block.lines ?? []).map((line) => ({
        stringValue: line.stringValue ?? '',
        language: line.language ?? '',
        confidence: line.confidence ?? -1,
        angle: line.angle ?? 0,
        isVertical: line.isVertical ?? false,
        vertexes: this.convertPoints(line.vertexes),
        cornerPoints: this.convertPoints(line.cornerPoints),
        borderRect: this.convertRect(line.borderRect),
        words: (line.words ?? []).map((word) => ({
          stringValue: word.stringValue ?? '',
          language: word.language ?? '',
          confidence: word.confidence ?? -1,
          vertexes: this.convertPoints(word.vertexes),
          cornerPoints: this.convertPoints(word.cornerPoints),
          borderRect: this.convertRect(word.borderRect),
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

  private convertRect(rect: textRecognition.Rect | undefined): object | null {
    if (!rect) return null;
    return {
      left: rect.left ?? 0,
      top: rect.top ?? 0,
      right: rect.right ?? 0,
      bottom: rect.bottom ?? 0,
    };
  }
}
