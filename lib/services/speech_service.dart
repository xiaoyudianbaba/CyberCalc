/// 语音识别服务
/// 封装 speech_to_text 包，提供中文语音识别功能
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../utils/constants.dart';
import '../utils/chinese_number_converter.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _lastError = '';

  // 回调函数
  VoidCallback? onResult;
  VoidCallback? onListeningStarted;
  VoidCallback? onListeningStopped;
  Function(String)? onError;

  // ========== Getters ==========
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  String get lastError => _lastError;

  /// 初始化语音识别引擎
  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          _lastError = error.errorMsg;
          _isListening = false;
          onError?.call(error.errorMsg);
          notifyListeners();
        },
      );
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      _lastError = '语音识别初始化失败: $e';
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// 开始语音识别
  Future<bool> startListening({VoidCallback? onResultCallback}) async {
    if (_isListening) {
      debugPrint('Already listening');
      return true;
    }

    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('语音识别不可用');
        return false;
      }
    }

    if (onResultCallback != null) {
      onResult = onResultCallback;
    }

    try {
      _recognizedText = '';

      final result = await _speech.listen(
        onResult: (result) {
          _handleSpeechResult(result);
        },
        localeId: AppConstants.voiceLocale,
        listenFor: const Duration(seconds: AppConstants.voiceTimeoutSeconds),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      if (result) {
        _isListening = true;
        onListeningStarted?.call();
        notifyListeners();
      }

      return result;
    } catch (e) {
      _lastError = '语音识别启动失败: $e';
      _isListening = false;
      onError?.call(_lastError);
      notifyListeners();
      return false;
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _speech.stop();
      _isListening = false;
      onListeningStopped?.call();
      notifyListeners();
    } catch (e) {
      debugPrint('Stop listening error: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// 处理语音识别结果
  void _handleSpeechResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;

    // 如果最终结果，自动停止并处理
    if (result.finalResult) {
      _isListening = false;
      onListeningStopped?.call();

      // 回调通知上层
      if (_recognizedText.isNotEmpty) {
        onResult?.call();
      }
    }

    notifyListeners();
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    if (!_isListening) return;
    try {
      await _speech.cancel();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Cancel listening error: $e');
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}