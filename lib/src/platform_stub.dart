import 'dart:async';
import 'package:flutter/services.dart';
import 'package:huawei_ml_text_ohos/src/models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of huawei_ml_text_ohos must implement.
///
/// This is a stub for iOS/Android platforms. The actual implementation
/// is in the ohos/ directory for HarmonyOS.
abstract class HuaweiMlTextOhosPlatform extends PlatformInterface {
  HuaweiMlTextOhosPlatform() : super(token: _token);

  static final Object _token = Object();

  static HuaweiMlTextOhosPlatform _instance = _StubPlatform();

  static HuaweiMlTextOhosPlatform get instance => _instance;

  static set instance(HuaweiMlTextOhosPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }
}

/// Stub implementation for non-ohos platforms.
///
/// All methods throw [UnsupportedError] indicating this plugin
/// only works on HarmonyOS.
class _StubPlatform extends HuaweiMlTextOhosPlatform {
  static const _message = 'huawei_ml_text_ohos only supports HarmonyOS NEXT';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> isModelAvailable() async => false;

  @override
  Future<bool> init() async {
    throw UnsupportedError(_message);
  }

  @override
  Future<TextRecognitionResult> recognizeText(String imagePath,
      {TextRecognitionConfig? config}) async {
    throw UnsupportedError(_message);
  }

  @override
  Future<bool> release() async {
    throw UnsupportedError(_message);
  }
}
