/// 音频服务
/// 管理按键音效的播放
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/constants.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  /// 初始化音效系统
  /// 在无法加载音频文件时使用系统音效作为备选
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// 播放数字键音效（短促"滴"声 - 800Hz）
  Future<void> playClickSound() async {
    await _playSystemTone(800, 100);
  }

  /// 播放运算符音效（清脆"叮"声 - 1200Hz）
  Future<void> playOperatorSound() async {
    await _playSystemTone(1200, 150);
  }

  /// 播放等号音效（电子合成上升音）
  Future<void> playEqualsSound() async {
    // 播放三个渐升的音调
    await _playSystemTone(800, 80);
    await Future.delayed(const Duration(milliseconds: 50));
    await _playSystemTone(1200, 80);
    await Future.delayed(const Duration(milliseconds: 50));
    await _playSystemTone(1600, 100);
  }

  /// 播放清除音效（倒放效果 - 下降音）
  Future<void> playClearSound() async {
    await _playSystemTone(600, 150);
    await Future.delayed(const Duration(milliseconds: 30));
    await _playSystemTone(400, 100);
  }

  /// 播放退格音效（短促"噗"声）
  Future<void> playBackspaceSound() async {
    await _playSystemTone(300, 80);
  }

  /// 播放语音启动音效（特殊提示音）
  Future<void> playVoiceStartSound() async {
    await _playSystemTone(1000, 100);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playSystemTone(1400, 150);
  }

  /// 播放语音开启提示音（短促单音，高音）
  /// 用于替代较长的中文语音提示，缩短录音前的等待
  Future<void> playVoiceStartBeep() async {
    await _playSystemTone(1320, 120);
  }

  /// 播放收音结束提示音（短促单音，低音，与开启音区分）
  Future<void> playVoiceEndBeep() async {
    await _playSystemTone(880, 120);
  }

  /// 播放系统音调
  /// 使用系统声音生成简单音效，无需音频文件
  Future<void> _playSystemTone(int frequency, int durationMs) async {
    try {
      // 尝试播放资产音频文件
      try {
        final source = AssetSource(_getSoundFileForFrequency(frequency));
        await _player.stop();
        await _player.play(source);
        await Future.delayed(Duration(milliseconds: durationMs));
      } catch (_) {
        // 如果资产文件不存在，使用系统音效作为备选
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      // 静默失败 - 音效播放不应影响主要功能
      debugPrint('Audio playback error: $e');
    }
  }

  /// 根据频率获取对应的音频文件名
  String _getSoundFileForFrequency(int frequency) {
    switch (frequency) {
      case 800:
        return AppConstants.soundClick;
      case 1200:
        return AppConstants.soundOperator;
      case 1600:
        return AppConstants.soundEquals;
      case 600:
      case 400:
        return AppConstants.soundClear;
      case 300:
        return AppConstants.soundBackspace;
      case 1000:
      case 1400:
      case 1320:
      case 880:
        return AppConstants.soundVoiceStart;
      default:
        return AppConstants.soundClick;
    }
  }

  /// 播放按键对应的音效
  Future<void> playKeySound(String key) async {
    switch (key) {
      case 'C':
        await playClearSound();
        break;
      case '⌫':
        await playBackspaceSound();
        break;
      case '=':
        await playEqualsSound();
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        await playOperatorSound();
        break;
      case '🎤':
        await playVoiceStartSound();
        break;
      default:
        await playClickSound();
        break;
    }
  }

  /// 释放资源
  void dispose() {
    _player.dispose();
  }
}