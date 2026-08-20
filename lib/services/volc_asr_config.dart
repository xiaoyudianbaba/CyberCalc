/// 火山引擎 ASR 配置管理
/// 使用 SharedPreferences 持久化存储所有 ASR 配置项
///
/// 【模型切换标注】修改 DEFAULT_CLUSTER 可更换默认集群
/// 【接口切换标注】修改 DEFAULT_URL 可更换 ASR 接口地址
import 'package:shared_preferences/shared_preferences.dart';

class VolcAsrConfig {
  VolcAsrConfig._();

  // ========== 常量定义 ==========
  /// WebSocket ASR 接口地址（火山引擎 v2 协议）
  static const String DEFAULT_URL =
      'wss://openspeech.bytedance.com/api/v2/asr';

  /// 默认集群标识（从控制台获取，不可随意填写）
  static const String DEFAULT_CLUSTER = '';

  // ========== SharedPreferences 键名 ==========
  static const String _keyAccessToken = 'volc_asr_access_token';
  static const String _keyAppId = 'volc_asr_app_id';
  static const String _keyClusterId = 'volc_asr_cluster_id';
  static const String _keyUrl = 'volc_asr_url';

  // ========== 配置数据 ==========
  String? _accessToken;
  String _appId = '';
  String _clusterId = '';
  String _url = DEFAULT_URL;
  bool _loaded = false;

  // ========== Getters ==========
  String? get accessToken => _accessToken;
  String get appId => _appId;
  String get clusterId => _clusterId;
  String get url => _url;
  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;
  bool get hasAppId => _appId.isNotEmpty;
  bool get hasClusterId => _clusterId.isNotEmpty;
  bool get isFullyConfigured =>
      hasAccessToken && hasAppId && hasClusterId;
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
      _clusterId = prefs.getString(_keyClusterId) ?? '';
      _url = prefs.getString(_keyUrl) ?? DEFAULT_URL;
      _loaded = true;
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

  /// 保存 ClusterID
  Future<bool> setClusterId(String clusterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyClusterId, clusterId);
      _clusterId = clusterId;
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
      await prefs.remove(_keyClusterId);
      await prefs.remove(_keyUrl);
      _accessToken = null;
      _appId = '';
      _clusterId = '';
      _url = DEFAULT_URL;
      return true;
    } catch (e) {
      return false;
    }
  }
}