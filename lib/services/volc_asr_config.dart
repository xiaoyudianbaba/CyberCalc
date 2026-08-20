/// 火山引擎 ASR 配置管理
/// 使用 SharedPreferences 持久化存储所有 ASR 配置项
///
/// 【模型切换标注】修改 DEFAULT_RESOURCE_ID 可更换默认资源
/// 【接口切换标注】修改 DEFAULT_URL 可更换 ASR 接口地址
import 'package:shared_preferences/shared_preferences.dart';

class VolcAsrConfig {
  VolcAsrConfig._();

  // ========== 常量定义 ==========
  /// WebSocket ASR 接口地址（火山引擎 v3 协议，双向流式优化版，推荐）
  static const String DEFAULT_URL =
      'wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async';

  /// 默认资源 ID（从控制台获取，Seed-ASR 2.0 小时版）
  static const String DEFAULT_RESOURCE_ID = 'volc.seedasr.sauc.duration';

  /// 默认 App ID（从控制台获取）
  static const String DEFAULT_APP_ID = '4261051259';

  /// 默认 Access Token（从控制台获取）
  static const String DEFAULT_ACCESS_TOKEN = 'jA6AnlD0kDzKXO0t-gpFMZ2lz9x566TJ';

  // ========== SharedPreferences 键名 ==========
  static const String _keyAccessToken = 'volc_asr_access_token';
  static const String _keyAppId = 'volc_asr_app_id';
  static const String _keyResourceId = 'volc_asr_resource_id';
  static const String _keyUrl = 'volc_asr_url';

  // 废弃键（旧版 v2 配置，加载时自动清理）
  static const String _legacyKeyClusterId = 'volc_asr_cluster_id';

  // ========== 配置数据 ==========
  String? _accessToken;
  String _appId = '';
  String _resourceId = '';
  String _url = DEFAULT_URL;
  bool _loaded = false;

  // ========== Getters ==========
  /// 返回 Access Token，未设置时返回默认值
  String? get accessToken =>
      (_accessToken == null || _accessToken!.isEmpty)
          ? DEFAULT_ACCESS_TOKEN
          : _accessToken;
  /// 返回 App ID，未设置时返回默认值
  String get appId => _appId.isEmpty ? DEFAULT_APP_ID : _appId;
  /// 返回 Resource ID，未设置时返回默认值
  String get resourceId =>
      _resourceId.isEmpty ? DEFAULT_RESOURCE_ID : _resourceId;
  String get url => _url;
  bool get hasAccessToken => accessToken != null && accessToken!.isNotEmpty;
  bool get hasAppId => appId.isNotEmpty;
  bool get hasResourceId => resourceId.isNotEmpty;
  bool get isFullyConfigured => hasAccessToken && hasAppId && hasResourceId;
  bool get isLoaded => _loaded;

  /// 单例
  static final VolcAsrConfig _instance = VolcAsrConfig._();
  factory VolcAsrConfig() => _instance;

  /// 从 SharedPreferences 加载配置
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyAccessToken);
      _appId = prefs.getString(_keyAppId) ?? '';
      _resourceId = prefs.getString(_keyResourceId) ?? '';
      _url = prefs.getString(_keyUrl) ?? DEFAULT_URL;
      _loaded = true;

      // === 旧版 v2 配置自动迁移 ===
      // 1. 若保存的接口地址是 v2 地址，切换为 v3 默认地址
      if (_url.contains('/api/v2/')) {
        _url = DEFAULT_URL;
        await prefs.setString(_keyUrl, _url);
      }
      // 2. 清理废弃的 Cluster ID 键
      if (prefs.containsKey(_legacyKeyClusterId)) {
        await prefs.remove(_legacyKeyClusterId);
      }
    } catch (e) {
      _loaded = true;
    }
  }

  /// 保存 Access Token
  Future<bool> setAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, token);
      _accessToken = token;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存 AppID
  Future<bool> setAppId(String appId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAppId, appId);
      _appId = appId;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存 Resource ID
  Future<bool> setResourceId(String resourceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyResourceId, resourceId);
      _resourceId = resourceId;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存接口地址
  Future<bool> setUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUrl, url);
      _url = url;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除所有 ASR 配置
  Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyAppId);
      await prefs.remove(_keyResourceId);
      await prefs.remove(_keyUrl);
      _accessToken = null;
      _appId = '';
      _resourceId = '';
      _url = DEFAULT_URL;
      return true;
    } catch (e) {
      return false;
    }
  }
}