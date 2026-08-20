/// 语音音色配置文件
/// 定义不同音色类型的参数
class VoiceProfile {
  final String name;
  final double pitch; // 音调偏移（半音）
  final double rate; // 语速倍率
  final String description;

  const VoiceProfile({
    required this.name,
    required this.pitch,
    required this.rate,
    required this.description,
  });

  /// 科幻电子音
  static const VoiceProfile electronic = VoiceProfile(
    name: '电子音',
    pitch: 0.0,
    rate: 1.5,
    description: '科幻电子合成音',
  );

  /// 萝莉音
  static const VoiceProfile loli = VoiceProfile(
    name: '萝莉音',
    pitch: 4.0,
    rate: 1.2,
    description: '可爱萝莉音',
  );

  /// 御姐音
  static const VoiceProfile mature = VoiceProfile(
    name: '御姐音',
    pitch: -2.0,
    rate: 1.0,
    description: '成熟御姐音',
  );

  /// 所有可用音色列表
  static const List<VoiceProfile> values = [
    electronic,
    loli,
    mature,
  ];

  /// 根据名称查找音色
  static VoiceProfile? fromName(String name) {
    try {
      return values.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }
}