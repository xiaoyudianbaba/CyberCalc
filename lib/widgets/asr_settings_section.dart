/// 火山引擎 ASR 配置设置区块
/// 包含 Access Token、App ID、Resource ID 的输入与持久化保存
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/volc_asr_service.dart';
import '../services/volc_asr_config.dart';
import '../theme/colors.dart';

class AsrSettingsSection extends StatefulWidget {
  const AsrSettingsSection({super.key});

  @override
  State<AsrSettingsSection> createState() => _AsrSettingsSectionState();
}

class _AsrSettingsSectionState extends State<AsrSettingsSection> {
  late TextEditingController _tokenController;
  late TextEditingController _appIdController;
  late TextEditingController _resourceController;
  late TextEditingController _urlController;
  bool _saving = false;
  String _saveStatus = '';

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _appIdController = TextEditingController();
    _resourceController = TextEditingController();
    _urlController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfig());
  }

  void _loadConfig() {
    final config = context.read<VolcAsrService>().config;
    _tokenController.text = config.accessToken ?? '';
    _appIdController.text = config.appId;
    _resourceController.text = config.resourceId;
    _urlController.text = config.url;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _appIdController.dispose();
    _resourceController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    setState(() {
      _saving = true;
      _saveStatus = '';
    });

    final config = context.read<VolcAsrService>().config;
    final token = _tokenController.text.trim();
    final appId = _appIdController.text.trim();
    final resource = _resourceController.text.trim();
    final url = _urlController.text.trim();

    bool success = true;
    success &= await config.setAccessToken(token);
    success &= await config.setAppId(appId);
    success &= await config.setResourceId(resource);
    success &= await config.setUrl(
        url.isNotEmpty ? url : VolcAsrConfig.DEFAULT_URL);

    setState(() {
      _saving = false;
      _saveStatus = success ? '✓ 配置已保存' : '✗ 保存失败，请重试';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saveStatus = '');
    });
  }

  Future<void> _resetConfig() async {
    setState(() {
      _saving = true;
      _saveStatus = '';
    });

    final config = context.read<VolcAsrService>().config;
    final ok = await config.clear();

    if (mounted) {
      setState(() {
        _saving = false;
        _saveStatus = ok ? '✓ 已恢复默认配置' : '✗ 重置失败，请重试';
        _loadConfig();
      });
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saveStatus = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CyberColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.settings_voice, color: CyberColors.info, size: 18),
              const SizedBox(width: 8),
              const Text(
                '火山引擎 ASR 配置',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '所有参数从火山引擎语音技术控制台获取',
            style: TextStyle(
              color: CyberColors.disabledText,
              fontSize: 11,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),

          // Access Token
          _buildLabel('Access Token', true),
          const SizedBox(height: 4),
          _buildTextField(
            controller: _tokenController,
            hint: '输入火山引擎控制台的 Access Token',
          ),
          const SizedBox(height: 12),

          // App ID
          _buildLabel('App ID', true),
          const SizedBox(height: 4),
          _buildTextField(
            controller: _appIdController,
            hint: '语音技术控制台 → 应用详情 → App ID',
          ),
          const SizedBox(height: 12),

          // Resource ID
          _buildLabel('Resource ID (资源标识)', true),
          const SizedBox(height: 4),
          _buildTextField(
            controller: _resourceController,
            hint: '控制台开通流式 ASR 后显示的 Resource ID',
          ),
          const SizedBox(height: 12),

          // 接口地址（高级）
          _buildLabel('接口地址', false),
          const SizedBox(height: 4),
          _buildTextField(
            controller: _urlController,
            hint: '默认为火山引擎 v3 ASR 地址',
          ),
          const SizedBox(height: 16),

          // 保存按钮
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberColors.info.withValues(alpha: 0.2),
                      foregroundColor: CyberColors.info,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: CyberColors.info.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '保存配置',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _resetConfig,
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
                    child: const Text(
                      '恢复默认',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              if (_saveStatus.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  _saveStatus,
                  style: TextStyle(
                    color: _saveStatus.startsWith('✓')
                        ? CyberColors.success
                        : CyberColors.error,
                    fontSize: 12,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool required) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: required ? CyberColors.info : CyberColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Orbitron',
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              color: CyberColors.error,
              fontSize: 12,
              fontFamily: 'Orbitron',
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontFamily: 'Orbitron',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: CyberColors.disabledText,
          fontSize: 12,
          fontFamily: 'Orbitron',
        ),
        filled: true,
        fillColor: CyberColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: CyberColors.info.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}