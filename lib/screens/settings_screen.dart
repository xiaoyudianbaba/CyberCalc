/// 设置屏幕
/// 管理语音模式、音色、播报速度等设置
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_feedback_service.dart';
import '../services/update_service.dart';
import '../models/voice_mode.dart';
import '../models/voice_profile.dart';
import '../widgets/asr_settings_section.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: CyberColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<VoiceFeedbackService>(
        builder: (context, voice, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 语音模式设置
              _buildSectionTitle('语音模式'),
              const SizedBox(height: 8),
              _buildVoiceModeSelector(context, voice),

              const SizedBox(height: 24),

              // 音色设置
              _buildSectionTitle('音色选择'),
              const SizedBox(height: 8),
              _buildVoiceProfileSelector(context, voice),

              const SizedBox(height: 24),

              // 播报速度
              _buildSectionTitle('播报速度'),
              const SizedBox(height: 8),
              _buildSpeedSlider(context, voice),

              const SizedBox(height: 24),

              // 按键音效
              _buildSectionTitle('按键音效'),
              const SizedBox(height: 8),
              _buildSoundEffectToggle(context),

              const SizedBox(height: 24),

              // 火山引擎 ASR 配置
              _buildSectionTitle('语音识别'),
              const SizedBox(height: 8),
              const AsrSettingsSection(),

              const SizedBox(height: 24),

              // 应用升级
              _buildSectionTitle('软件升级'),
              const SizedBox(height: 8),
              const UpdateSection(),

              const SizedBox(height: 32),

              // 关于信息
              _buildAboutSection(),
            ],
          );
        },
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: CyberColors.navActive,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        fontFamily: 'Orbitron',
        shadows: [
          Shadow(
            color: CyberColors.navActive.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  /// 构建语音模式选择器
  Widget _buildVoiceModeSelector(
      BuildContext context, VoiceFeedbackService voice) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.functionGlow,
          width: 1,
        ),
      ),
      child: Column(
        children: VoiceMode.values.map((mode) {
          final isSelected = voice.voiceMode == mode;
          final modeInfo = _getVoiceModeInfo(mode);
          return InkWell(
            onTap: () => voice.setVoiceMode(mode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: mode != VoiceMode.values.last
                      ? BorderSide(color: CyberColors.historyDivider)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? modeInfo.color
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? modeInfo.color
                            : CyberColors.disabledText,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modeInfo.title,
                          style: TextStyle(
                            color: isSelected
                                ? CyberColors.primaryText
                                : CyberColors.secondaryText,
                            fontSize: 15,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          modeInfo.description,
                          style: TextStyle(
                            color: CyberColors.disabledText,
                            fontSize: 12,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 获取语音模式信息
  _VoiceModeInfo _getVoiceModeInfo(VoiceMode mode) {
    switch (mode) {
      case VoiceMode.full:
        return _VoiceModeInfo(
          title: '全语音模式',
          description: '每个按键都播报语音，适合盲操作',
          color: CyberColors.voiceIdle,
        );
      case VoiceMode.smart:
        return _VoiceModeInfo(
          title: '智能模式',
          description: '只播报运算符和结果，数字键仅有音效',
          color: CyberColors.warning,
        );
      case VoiceMode.silent:
        return _VoiceModeInfo(
          title: '静音模式',
          description: '只有音效，无语音播报，适合安静环境',
          color: CyberColors.disabledText,
        );
    }
  }

  /// 构建音色选择器
  Widget _buildVoiceProfileSelector(
      BuildContext context, VoiceFeedbackService voice) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.functionGlow,
          width: 1,
        ),
      ),
      child: Row(
        children: VoiceProfile.values.map((profile) {
          final isSelected = voice.currentProfile.name == profile.name;
          return Expanded(
            child: InkWell(
              onTap: () => voice.setVoiceProfile(profile),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? profile == VoiceProfile.electronic
                          ? CyberColors.numberGlow.withValues(alpha: 0.15)
                          : profile == VoiceProfile.loli
                              ? CyberColors.addText.withValues(alpha: 0.15)
                              : CyberColors.divideText.withValues(alpha: 0.15)
                      : null,
                  border: Border(
                    right: profile != VoiceProfile.values.last
                        ? BorderSide(color: CyberColors.historyDivider)
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getProfileIcon(profile),
                      color: isSelected
                          ? _getProfileColor(profile)
                          : CyberColors.disabledText,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.name,
                      style: TextStyle(
                        color: isSelected
                            ? _getProfileColor(profile)
                            : CyberColors.secondaryText,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.description,
                      style: TextStyle(
                        color: CyberColors.disabledText,
                        fontSize: 10,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 获取音色对应的图标
  IconData _getProfileIcon(VoiceProfile profile) {
    if (profile == VoiceProfile.electronic) return Icons.smart_toy_outlined;
    if (profile == VoiceProfile.loli) return Icons.child_care;
    return Icons.person;
  }

  /// 获取音色对应的颜色
  Color _getProfileColor(VoiceProfile profile) {
    if (profile == VoiceProfile.electronic) return CyberColors.numberText;
    if (profile == VoiceProfile.loli) return CyberColors.addText;
    return CyberColors.divideText;
  }

  /// 构建语速滑块
  Widget _buildSpeedSlider(BuildContext context, VoiceFeedbackService voice) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.functionGlow,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '慢速',
                style: TextStyle(
                  color: CyberColors.disabledText,
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                ),
              ),
              Text(
                '${(voice.speed * 100).toInt()}%',
                style: TextStyle(
                  color: CyberColors.navActive,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '快速',
                style: TextStyle(
                  color: CyberColors.disabledText,
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: CyberColors.navActive,
              inactiveTrackColor: CyberColors.disabledText.withValues(alpha: 0.3),
              thumbColor: CyberColors.navActive,
              overlayColor: CyberColors.navActive.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: voice.speed,
              min: 0.5,
              max: 3.0,
              divisions: 10,
              onChanged: (value) => voice.setSpeed(value),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建音效开关（占位，未来扩展）
  Widget _buildSoundEffectToggle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.functionGlow,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.volume_up,
            color: CyberColors.voiceIdle,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '按键音效',
                  style: TextStyle(
                    color: CyberColors.primaryText,
                    fontSize: 15,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '按键时播放短促提示音',
                  style: TextStyle(
                    color: CyberColors.disabledText,
                    fontSize: 12,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (value) {
              // 音效开关功能预留
            },
            activeColor: CyberColors.navActive,
            activeTrackColor: CyberColors.navActive.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// 构建关于信息
  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.functionGlow,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'CYBERCALC',
            style: TextStyle(
              color: CyberColors.navActive,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontFamily: 'Orbitron',
              shadows: [
                Shadow(
                  color: CyberColors.navActive.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '赛博朋克语音计算器',
            style: TextStyle(
              color: CyberColors.secondaryText,
              fontSize: 14,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder<String>(
            future: UpdateService().getCurrentVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '1.0.0';
              return Text(
                '版本 $version',
                style: TextStyle(
                  color: CyberColors.disabledText,
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 软件升级区块
class UpdateSection extends StatefulWidget {
  const UpdateSection({super.key});

  @override
  State<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<UpdateSection> {
  final _updateService = UpdateService();

  bool _checking = false;
  bool _downloading = false;
  String _status = '';
  ReleaseInfo? _latest;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _status = '正在检查更新...';
    });

    final current = await _updateService.getCurrentVersion();
    final latest = await _updateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _checking = false;
      _latest = latest;
      if (latest == null) {
        _status = '检查更新失败，请检查网络';
      } else {
        final newest = _updateService.compareVersions(current, latest.version);
        if (newest == latest.version && latest.version != current) {
          _status = '发现新版本 v${latest.version}，点击升级';
        } else {
          _status = '已是最新版本 v$current';
        }
      }
    });
  }

  Future<void> _doUpgrade() async {
    final latest = _latest;
    if (latest == null || !latest.hasApk) {
      setState(() => _status = '未找到可下载的 APK');
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.surface,
        title: Text(
          '升级到 v${latest.version}',
          style: const TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            latest.body.isNotEmpty
                ? latest.body
                : '发现新版本，点击确定开始下载并升级。',
            style: const TextStyle(
                fontFamily: 'Orbitron', color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定',
                style: TextStyle(color: CyberColors.navActive)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _downloading = true;
      _status = '正在下载 ${latest.apkName ?? 'APK'}...';
    });

    final apkPath = await _updateService.downloadApk(
      latest.apkUrl!,
      latest.apkName ?? 'cybercalc-update.apk',
    );

    if (!mounted) return;

    if (apkPath == null) {
      setState(() {
        _downloading = false;
        _status = '下载失败，请重试';
      });
      return;
    }

    setState(() => _status = '正在安装...');

    final (ok, msg) = await _updateService.installApk(apkPath);

    if (!mounted) return;

    setState(() {
      _downloading = false;
      _status = ok ? '已启动系统安装器' : '安装失败: $msg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.functionGlow,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_alt,
                color: CyberColors.navActive,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _status.isEmpty ? '正在检查更新...' : _status,
                  style: TextStyle(
                    color: _status.startsWith('发现新版本')
                        ? CyberColors.warning
                        : _status.startsWith('已是最新')
                            ? CyberColors.success
                            : CyberColors.secondaryText,
                    fontSize: 13,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed:
                        (_checking || _downloading) ? null : _checkForUpdate,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CyberColors.secondaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: CyberColors.secondaryText.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      '检查更新',
                      style: TextStyle(
                          fontFamily: 'Orbitron', fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: (_checking || _downloading || _latest == null)
                        ? null
                        : _doUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberColors.navActive.withValues(alpha: 0.2),
                      foregroundColor: CyberColors.navActive,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: CyberColors.navActive.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: _downloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.system_update, size: 16),
                    label: Text(
                      _downloading ? '下载中' : '立即升级',
                      style: const TextStyle(
                          fontFamily: 'Orbitron', fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 语音模式信息辅助类
class _VoiceModeInfo {
  final String title;
  final String description;
  final Color color;

  const _VoiceModeInfo({
    required this.title,
    required this.description,
    required this.color,
  });
}