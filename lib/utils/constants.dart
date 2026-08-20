/// 应用常量定义
/// 包含所有全局常量、尺寸和配置值
class AppConstants {
  AppConstants._();

  // ========== 应用信息 ==========
  static const String appName = 'CyberCalc';
  static const String appVersion = '1.0.0';
  static const String appDescription = '赛博朋克语音计算器';

  // ========== 数据库 ==========
  static const String databaseName = 'cybercalc.db';
  static const int databaseVersion = 1;
  static const String historyTableName = 'calculation_history';

  // ========== 语音识别 ==========
  static const int voiceTimeoutSeconds = 10; // 语音超时时间
  static const String voiceLocale = 'zh_CN'; // 中文语音识别

  // ========== 语音播报 ==========
  static const double defaultSpeechRate = 0.5; // 默认语速 (0.0-1.0)
  static const double fastSpeechRate = 0.6; // 快速模式语速
  static const double robotPitch = 1.2; // 电子音音调
  static const double loliPitch = 1.5; // 萝莉音音调
  static const double maturePitch = 0.8; // 御姐音音调
  static const double keyPressVolume = 1.0; // 按键音效音量

  // ========== 动画 ==========
  static const Duration buttonPressDuration = Duration(milliseconds: 100);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 150);
  static const Duration glowAnimationDuration = Duration(milliseconds: 2000);
  static const Duration gridAnimationDuration = Duration(milliseconds: 3000);

  // ========== 布局 ==========
  static const double buttonSize = 72.0;
  static const double buttonSpacing = 8.0;
  static const double displayHeight = 160.0;
  static const double titleBarHeight = 48.0;
  static const double bottomNavHeight = 56.0;
  static const double borderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;

  // ========== 精度 ==========
  static const int maxDecimalPlaces = 10; // 最多10位小数
  static const int maxDisplayLength = 20; // 最大显示长度

  // ========== 音效 ==========
  static const String soundClick = 'sounds/click.mp3';
  static const String soundOperator = 'sounds/operator.mp3';
  static const String soundEquals = 'sounds/equals.mp3';
  static const String soundClear = 'sounds/clear.mp3';
  static const String soundBackspace = 'sounds/backspace.mp3';
  static const String soundVoiceStart = 'sounds/voice_start.mp3';
}