import textRecognition from '@hms.ai.ocr.textRecognition';
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodResult,
  MethodChannel,
  MethodCallHandler,
} from '@ohos/flutter_ohos';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import hilog from '@ohos.hilog';

const TAG = 'HuaweiMlTextPlugin';
const CHANNEL_NAME = 'huawei.hms.flutter.ml.text';
const LOG_DOMAIN = 0x0001;

// ── Result interfaces (match the Dart model) ──────────────────────────────

interface PointResult {
  x: number;
  y: number;
}

interface CharacterResult {
  stringValue: string;
  confidence: number;
  borderRect: RectResult | null;
}

interface WordResult {
  stringValue: string;
  language: string;
  confidence: number;
  vertexes: PointResult[];
  cornerPoints: PointResult[];
  borderRect: RectResult | null;
  characterList: CharacterResult[];
}

interface LineResult {
  stringValue: string;
  language: string;
  confidence: number;
  angle: number;
  isVertical: boolean;
  vertexes: PointResult[];
  cornerPoints: PointResult[];
  borderRect: RectResult | null;
  characterList: CharacterResult[];
  elementList: ElementResult[];
  words: WordResult[];
}

interface BlockResult {
  stringValue: string;
  language: string;
  confidence: number;
  angle: number;
  isVertical: boolean;
  vertexes: PointResult[];
  cornerPoints: PointResult[];
  borderRect: RectResult | null;
  elementList: ElementResult[];
  lines: LineResult[];
}

interface TextRecognitionResultMap {
  stringValue: string;
  blocks: BlockResult[];
}

interface RectResult {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

interface ElementResult {
  stringValue: string;
  confidence: number;
  borderRect: RectResult | null;
  cornerPoints: PointResult[];
}

// ── Plugin ────────────────────────────────────────────────────────────────

export default class HuaweiMlTextPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private initialized: boolean = false;

  getUniqueClassName(): string {
    return 'HuaweiMlTextPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    hilog.info(LOG_DOMAIN, TAG, 'Plugin attached to engine');
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    if (this.initialized) {
      this.doRelease();
    }
    hilog.info(LOG_DOMAIN, TAG, 'Plugin detached from engine');
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    hilog.info(LOG_DOMAIN, TAG, `onMethodCall: ${call.method}`);
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
      const available: boolean = typeof textRecognition.init === 'function';
      result.success(available);
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, `isAvailable check failed: ${err}`);
      result.success(false);
    }
  }

  private handleIsModelAvailable(result: MethodResult): void {
    try {
      if (this.initialized) {
        result.success(true);
        return;
      }
      textRecognition.init().then(() => {
        textRecognition.release();
        result.success(true);
      }).catch(() => {
        result.success(false);
      });
    } catch (err) {
      hilog.warn(LOG_DOMAIN, TAG, `isModelAvailable: model not ready: ${err}`);
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
    textRecognition.init().then(() => {
      this.initialized = true;
      hilog.info(LOG_DOMAIN, TAG, 'textRecognition.init() succeeded');
      result.success(true);
    }).catch((err: Error) => {
      hilog.error(LOG_DOMAIN, TAG, `textRecognition.init() failed: ${err.message}`);
      result.error('INIT_FAILED', `Failed to init textRecognition: ${err.message}`, null);
    });
  }

  private handleRelease(result: MethodResult): void {
    this.doRelease();
    result.success(true);
  }

  private doRelease(): void {
    try {
      textRecognition.release();
      this.initialized = false;
      hilog.info(LOG_DOMAIN, TAG, 'textRecognition.release() succeeded');
    } catch (err) {
      hilog.error(LOG_DOMAIN, TAG, `textRecognition.release() failed: ${err}`);
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

    const args: Record<string, Object> = call.args as Record<string, Object>;
    const imagePath: string = args['imagePath'] as string;
    if (!imagePath) {
      result.error('INVALID_ARGS', 'imagePath is required', null);
      return;
    }

    const configMap: Record<string, Object> | undefined = args['config'] as Record<string, Object> | undefined;
    const config: textRecognition.TextRecognitionConfiguration = this.buildConfig(configMap);

    this.recognizeFromFile(imagePath, config, result);
  }

  private handleRecognizeImage(call: MethodCall, result: MethodResult): void {
    if (!this.initialized) {
      result.error('NOT_INITIALIZED', 'Call text#init first', null);
      return;
    }

    const args: Record<string, Object> = call.args as Record<string, Object>;
    const imageSource: Record<string, Object> = args['imageSource'] as Record<string, Object>;
    if (!imageSource) {
      result.error('INVALID_ARGS', 'imageSource is required', null);
      return;
    }

    const configMap: Record<string, Object> | undefined = args['config'] as Record<string, Object> | undefined;
    const config: textRecognition.TextRecognitionConfiguration = this.buildConfig(configMap);

    const sourceType: string = imageSource['type'] as string;
    if (sourceType === 'filePath') {
      const path: string = imageSource['path'] as string;
      this.recognizeFromFile(path, config, result);
    } else {
      result.error('INVALID_ARGS', `Unsupported image source type: ${sourceType}. Only filePath is supported.`, null);
    }
  }

  private handleRecognizeTextBatch(call: MethodCall, result: MethodResult): void {
    if (!this.initialized) {
      result.error('NOT_INITIALIZED', 'Call text#init first', null);
      return;
    }

    const args: Record<string, Object> = call.args as Record<string, Object>;
    const imagePaths: string[] = args['imagePaths'] as string[];
    if (!imagePaths || imagePaths.length === 0) {
      result.error('INVALID_ARGS', 'imagePaths is required', null);
      return;
    }

    const configMap: Record<string, Object> | undefined = args['config'] as Record<string, Object> | undefined;
    const config: textRecognition.TextRecognitionConfiguration = this.buildConfig(configMap);

    const results: Array<TextRecognitionResultMap | null> = [];
    let completed: number = 0;

    for (let i = 0; i < imagePaths.length; i++) {
      this.loadPixelMap(imagePaths[i])
        .then((pixelMap: image.PixelMap) => {
          const visionInfo: textRecognition.VisionInfo = { pixelMap: pixelMap };
          return textRecognition.recognizeText(visionInfo, config);
        })
        .then((recognitionResult: textRecognition.TextRecognitionResult) => {
          results[i] = this.convertResult(recognitionResult);
          completed++;
          if (completed === imagePaths.length) {
            hilog.info(LOG_DOMAIN, TAG, `Batch recognized ${imagePaths.length} images`);
            result.success(results);
          }
        })
        .catch((err: Error) => {
          hilog.error(LOG_DOMAIN, TAG, `Batch item ${i} failed: ${err.message}`);
          results[i] = null;
          completed++;
          if (completed === imagePaths.length) {
            result.success(results);
          }
        });
    }
  }

  private recognizeFromFile(
    filePath: string,
    config: textRecognition.TextRecognitionConfiguration,
    result: MethodResult
  ): void {
    this.loadPixelMap(filePath)
      .then((pixelMap: image.PixelMap) => {
        const visionInfo: textRecognition.VisionInfo = { pixelMap: pixelMap };
        return textRecognition.recognizeText(visionInfo, config);
      })
      .then((recognitionResult: textRecognition.TextRecognitionResult) => {
        const resultMap: TextRecognitionResultMap = this.convertResult(recognitionResult);
        hilog.info(LOG_DOMAIN, TAG, `Recognized ${resultMap.blocks.length} blocks`);
        result.success(resultMap);
      })
      .catch((err: Error) => {
        hilog.error(LOG_DOMAIN, TAG, `recognizeText failed: ${err.message}`);
        result.error('RECOGNIZE_FAILED', err.message, null);
      });
  }

  // ==========================================================================
  // Image loading
  // ==========================================================================

  private async loadPixelMap(filePath: string): Promise<image.PixelMap> {
    const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
    try {
      const stat: fs.Stat = fs.statSync(file.fd);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);

      const imageSource: image.ImageSource = image.createImageSource(buffer);
      const pixelMap: image.PixelMap = await imageSource.createPixelMap();
      return pixelMap;
    } finally {
      fs.closeSync(file);
    }
  }

  // ==========================================================================
  // Config & conversion helpers
  // ==========================================================================

  private buildConfig(configMap: Record<string, Object> | undefined): textRecognition.TextRecognitionConfiguration {
    const config: textRecognition.TextRecognitionConfiguration = {};

    if (configMap) {
      if (configMap['isDirectionSupported'] !== undefined) {
        config.isDirectionDetectionSupported = configMap['isDirectionSupported'] as boolean;
      }
    }

    return config;
  }

  private handleGetSupportedLanguages(result: MethodResult): void {
    textRecognition.getSupportedLanguages()
      .then((languages: string[]) => {
        result.success(languages);
      })
      .catch((err: Error) => {
        hilog.error(LOG_DOMAIN, TAG, `getSupportedLanguages failed: ${err.message}`);
        result.error('LANGUAGES_FAILED', `Failed to get languages: ${err.message}`, null);
      });
  }

  // ==========================================================================
  // Result conversion
  // ==========================================================================

  private convertResult(recognitionResult: textRecognition.TextRecognitionResult): TextRecognitionResultMap {
    const blocks: BlockResult[] = (recognitionResult.blocks ?? []).map(
      (block: textRecognition.TextBlock) => this.convertBlock(block)
    );

    const fullText: string = blocks.map((b: BlockResult) => b.stringValue).join('\n');

    const result: TextRecognitionResultMap = {
      stringValue: recognitionResult.value ?? fullText,
      blocks: blocks,
    };
    return result;
  }

  private convertBlock(block: textRecognition.TextBlock): BlockResult {
    const lines: LineResult[] = (block.lines ?? []).map(
      (line: textRecognition.TextLine) => this.convertLine(line)
    );

    const blockResult: BlockResult = {
      stringValue: block.value ?? '',
      language: '',
      confidence: -1,
      angle: 0,
      isVertical: false,
      vertexes: [],
      cornerPoints: [],
      borderRect: null,
      elementList: [],
      lines: lines,
    };
    return blockResult;
  }

  private convertLine(line: textRecognition.TextLine): LineResult {
    const words: WordResult[] = (line.words ?? []).map(
      (word: textRecognition.TextWord) => this.convertWord(word)
    );

    const lineResult: LineResult = {
      stringValue: line.value ?? '',
      language: '',
      confidence: -1,
      angle: 0,
      isVertical: false,
      vertexes: [],
      cornerPoints: this.convertPoints(line.cornerPoints),
      borderRect: null,
      characterList: [],
      elementList: [],
      words: words,
    };
    return lineResult;
  }

  private convertWord(word: textRecognition.TextWord): WordResult {
    const wordResult: WordResult = {
      stringValue: word.value ?? '',
      language: '',
      confidence: -1,
      vertexes: [],
      cornerPoints: this.convertPoints(word.cornerPoints),
      borderRect: null,
      characterList: [],
    };
    return wordResult;
  }

  private convertPoints(points: textRecognition.PixelPoint[] | undefined): PointResult[] {
    if (!points) {
      return [];
    }
    const result: PointResult[] = [];
    for (const p of points) {
      const point: PointResult = { x: p.x ?? 0, y: p.y ?? 0 };
      result.push(point);
    }
    return result;
  }
}
