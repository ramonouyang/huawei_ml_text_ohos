import { textRecognition } from '@kit.CoreVisionKit';
import { FlutterPlugin, MethodCall, MethodResult, MethodChannel } from '@ohos/flutter_ohos/ets/plugin';

const TAG = 'HuaweiMlTextPlugin';
const CHANNEL_NAME = 'huawei.hms.flutter.ml.text';

/**
 * Flutter plugin wrapping HarmonyOS Core Vision Kit textRecognition.
 *
 * Methods:
 *   text#isAvailable         — Check HMS ML Kit service availability
 *   text#isModelAvailable    — Check offline model status
 *   text#init                — Initialize the recognition engine
 *   text#recognizeText       — Recognize text from file path
 *   text#recognizeImage      — Recognize text from URL or bytes
 *   text#recognizeTextBatch  — Batch recognize from multiple file paths
 *   text#getSupportedLanguages — List supported languages
 *   text#release             — Release the engine
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
      case 'text#isAvailable':
        this.handleIsAvailable(result);
        break;
      case 'text#isModelAvailable':
        this.handleIsModelAvailable(result);
        break;
      case 'text#init':
        this.handleInit(result);
        break;
      case 'text#recognizeText':
        this.handleRecognizeText(call, result);
        break;
      case 'text#recognizeImage':
        this.handleRecognizeImage(call, result);
        break;
      case 'text#recognizeTextBatch':
        this.handleRecognizeTextBatch(call, result);
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

  // ==========================================================================
  // Availability checks
  // ==========================================================================

  private handleIsAvailable(result: MethodResult): void {
    try {
      // Core Vision Kit is available if HMS Core is installed
      const available = textRecognition.init !== undefined;
      result.success(available);
    } catch (err) {
      console.error(TAG, `isAvailable check failed: ${err}`);
      result.success(false);
    }
  }

  private handleIsModelAvailable(result: MethodResult): void {
    try {
      // Try to init and check if model is ready
      if (this.initialized) {
        result.success(true);
        return;
      }
      // Attempt init to check model availability
      textRecognition.init();
      textRecognition.release();
      result.success(true);
    } catch (err) {
      console.warn(TAG, `isModelAvailable: model not ready: ${err}`);
      result.success(false);
    }
  }

  // ==========================================================================
  // Init / Release
  // ==========================================================================

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

  // ==========================================================================
  // Recognition methods
  // ==========================================================================

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

    const configMap = call.argument('config') as Record<string, Object> | undefined;
    const config = this.buildConfig(configMap);

    this.doRecognize({ uri: imagePath }, config, result);
  }

  private handleRecognizeImage(call: MethodCall, result: MethodResult): void {
    if (!this.initialized) {
      result.error('NOT_INITIALIZED', 'Call text#init first', null);
      return;
    }

    const imageSource = call.argument('imageSource') as Record<string, Object>;
    if (!imageSource) {
      result.error('INVALID_ARGS', 'imageSource is required', null);
      return;
    }

    const configMap = call.argument('config') as Record<string, Object> | undefined;
    const config = this.buildConfig(configMap);

    const sourceType = imageSource['type'] as string;
    let visionInfo: textRecognition.VisionInfo;

    if (sourceType === 'filePath') {
      visionInfo = { uri: imageSource['path'] as string };
    } else if (sourceType === 'url') {
      visionInfo = { url: imageSource['url'] as string };
    } else {
      result.error('INVALID_ARGS', `Unsupported image source type: ${sourceType}`, null);
      return;
    }

    this.doRecognize(visionInfo, config, result);
  }

  private handleRecognizeTextBatch(call: MethodCall, result: MethodResult): void {
    if (!this.initialized) {
      result.error('NOT_INITIALIZED', 'Call text#init first', null);
      return;
    }

    const imagePaths = call.argument('imagePaths') as string[];
    if (!imagePaths || imagePaths.length === 0) {
      result.error('INVALID_ARGS', 'imagePaths is required', null);
      return;
    }

    const configMap = call.argument('config') as Record<string, Object> | undefined;
    const config = this.buildConfig(configMap);

    // Process all images sequentially and collect results
    const results: (object | null)[] = [];
    let completed = 0;

    for (let i = 0; i < imagePaths.length; i++) {
      const visionInfo: textRecognition.VisionInfo = { uri: imagePaths[i] };
      textRecognition.recognizeText(visionInfo, config)
        .then((recognitionResult: textRecognition.TextRecognitionResult) => {
          results[i] = this.convertResult(recognitionResult);
          completed++;
          if (completed === imagePaths.length) {
            console.info(TAG, `Batch recognized ${imagePaths.length} images`);
            result.success(results);
          }
        })
        .catch((err: Error) => {
          console.error(TAG, `Batch item ${i} failed: ${err.message}`);
          results[i] = null;
          completed++;
          if (completed === imagePaths.length) {
            result.success(results);
          }
        });
    }
  }

  private doRecognize(
    visionInfo: textRecognition.VisionInfo,
    config: textRecognition.TextRecognitionConfiguration,
    result: MethodResult
  ): void {
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
  }

  // ==========================================================================
  // Config & conversion helpers
  // ==========================================================================

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
      if (configMap['enableCloud'] !== undefined) {
        config.enableCloud = configMap['enableCloud'] as boolean;
      }
    }

    return config;
  }

  private handleGetSupportedLanguages(result: MethodResult): void {
    try {
      const languages = textRecognition.getSupportedLanguages();
      result.success(languages);
    } catch (err) {
      console.error(TAG, `getSupportedLanguages failed: ${err}`);
      result.error('LANGUAGES_FAILED', `Failed to get languages: ${err}`, null);
    }
  }

  // ==========================================================================
  // Result conversion
  // ==========================================================================

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
      elementList: this.convertElements(block.elementList),
      lines: (block.lines ?? []).map((line) => ({
        stringValue: line.stringValue ?? '',
        language: line.language ?? '',
        confidence: line.confidence ?? -1,
        angle: line.angle ?? 0,
        isVertical: line.isVertical ?? false,
        vertexes: this.convertPoints(line.vertexes),
        cornerPoints: this.convertPoints(line.cornerPoints),
        borderRect: this.convertRect(line.borderRect),
        characterList: this.convertCharacters(line.characterList),
        elementList: this.convertElements(line.elementList),
        words: (line.words ?? []).map((word) => ({
          stringValue: word.stringValue ?? '',
          language: word.language ?? '',
          confidence: word.confidence ?? -1,
          vertexes: this.convertPoints(word.vertexes),
          cornerPoints: this.convertPoints(word.cornerPoints),
          borderRect: this.convertRect(word.borderRect),
          characterList: this.convertCharacters(word.characterList),
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

  private convertCharacters(chars: textRecognition.TextCharacter[] | undefined): object[] {
    if (!chars) return [];
    return chars.map((c) => ({
      stringValue: c.stringValue ?? '',
      confidence: c.confidence ?? -1,
      borderRect: this.convertRect(c.borderRect),
    }));
  }

  private convertElements(elements: textRecognition.TextElement[] | undefined): object[] {
    if (!elements) return [];
    return elements.map((e) => ({
      stringValue: e.stringValue ?? '',
      confidence: e.confidence ?? -1,
      borderRect: this.convertRect(e.borderRect),
      cornerPoints: this.convertPoints(e.cornerPoints),
    }));
  }
}
