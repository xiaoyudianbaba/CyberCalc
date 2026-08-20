/// 按键语音反馈服务
/// 管理按键语音播报系统，支持多种语音模式和智能数字朗读
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/voice_mode.dart';
import '../models/voice_profile.dart';
import '../utils/number_reader.dart';
import '../utils/constants.dart';

class VoiceFeedbackService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  VoiceMode _voiceMode = VoiceMode.full; // 当前语音模式
  VoiceProfile _currentProfile = VoiceProfile.electronic; // 当前音色
  bool _isSpeaking = false; // 是否正在播报
  double _speed = 1.5; // 播报速度（倍率）
  // ========== Getters ==========
  VoiceMode get voiceMode => _voiceMode;
  VoiceProfile get currentProfile => _currentProfile;
  bool get isSpeaking => _isSpeaking;
  double get speed => _speed;

  /// 初始化语音引擎
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 设置语音引擎
      await _tts.setLanguage('zh-CN');
      await _tts.setVolume(1.0);

      // 应用当前音色设置（确保首次使用时音色生效）
      await _applyVoiceProfile();
      await setSpeed(_speed);

      // 监听播报状态
      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setErrorHandler((error) {
        debugPrint('TTS Error: $error');
        _isSpeaking = false;
        notifyListeners();
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
      return false;
    }
  }

  /// 设置语音模式
  Future<void> setVoiceMode(VoiceMode mode) async {
    _voiceMode = mode;
    notifyListeners();
  }

  /// 设置音色
  Future<void> setVoiceProfile(VoiceProfile profile) async {
    _currentProfile = profile;
    await _applyVoiceProfile();
    notifyListeners();
  }

  /// 设置播报速度
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    // 速度倍率映射到 flutter_tts 语速 (0.0-1.0)
    final ttsRate = (speed * 0.4).clamp(0.3, 1.0).toDouble();
    await _tts.setSpeechRate(ttsRate);
    notifyListeners();
  }

  /// 应用当前音色配置到 TTS 引擎
  Future<void> _applyVoiceProfile() async {
    // flutter_tts pitch 范围: 0.5-2.0 (Android)
    double pitch;
    if (_currentProfile == VoiceProfile.electronic) {
      pitch = 1.3; // 电子科幻音 - 较高
    } else if (_currentProfile == VoiceProfile.loli) {
      pitch = 1.6; // 萝莉音 - 高音调
    } else if (_currentProfile == VoiceProfile.mature) {
      pitch = 0.7; // 御姐音 - 低音沉稳
    } else {
      pitch = 1.0;
    }
    await _tts.setPitch(pitch);

    // 设置语速 (0.0-1.0)
    double rate;
    if (_currentProfile == VoiceProfile.electronic) {
      rate = 0.65; // 电子音 - 快速
    } else if (_currentProfile == VoiceProfile.loli) {
      rate = 0.55; // 萝莉音 - 中等偏快
    } else if (_currentProfile == VoiceProfile.mature) {
      rate = 0.42; // 御姐音 - 慢速沉稳
    } else {
      rate = 0.5;
    }
    await _tts.setSpeechRate(rate);
  }

  /// 播报按键语音
  /// 根据当前语音模式决定是否播报
  Future<void> speakKey(String key) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    // 静音模式不播报
    if (_voiceMode == VoiceMode.silent) return;

    // 获取按键的中文读音
    String speechText = NumberReader.readKey(key);

    // 智能模式：只播报运算符和功能键
    if (_voiceMode == VoiceMode.smart) {
      if (RegExp(r'^[0-9.]$').hasMatch(key)) {
        return;
      }
    }

    // 播报按键
    await _speak(speechText);
  }

  /// 播报连续数字序列（智能朗读）
  /// 例如：按1-2-3 播报"一百二十三"
  Future<void> speakNumberSequence(String sequence) async {
    if (!_isInitialized) return;
    if (_voiceMode == VoiceMode.silent) return;

    final speechText = NumberReader.readNumber(sequence);
    await _speak(speechText);
  }

  /// 播报完整算式
  Future<void> speakExpression(String expression) async {
    if (!_isInitialized) return;
    if (_voiceMode == VoiceMode.silent) return;

    final speechText = NumberReader.readExpression(expression);
    await _speak(speechText);
  }

  /// 播报计算结果
  Future<void> speakResult(String result) async {
    if (!_isInitialized) return;
    if (_voiceMode == VoiceMode.silent) return;

    // 错误信息不播报
    if (result.startsWith('表达式错误') ||
        result == '语法错误' ||
        result == '计算出错' ||
        result == '除以零') {
      return;
    }

    final speechText = '等于${NumberReader.readResult(result)}';
    await _speak(speechText);
  }

  /// 播报语音输入状态
  Future<void> speakVoiceStatus(String status) async {
    if (!_isInitialized) return;
    if (_voiceMode == VoiceMode.silent) return;

    await _speak(status);
  }

  /// 内部播报方法（带中断和优先级控制）
  Future<void> _speak(String text) async {
    try {
      // 中断当前播报，实现连续按键立即响应
      if (_isSpeaking) {
        await _tts.stop();
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// 停止当前播报
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}