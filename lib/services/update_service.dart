/// 应用升级服务
/// 通过 GitHub Release 检查最新版本并下载 APK 安装
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// GitHub Release 信息
class ReleaseInfo {
  final String tagName;
  final String name;
  final String body;
  final String? apkUrl;
  final String? apkName;

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    this.apkUrl,
    this.apkName,
  });

  /// 版本号（去掉 v 前缀），如 v1.0.3 -> 1.0.3
  String get version {
    var v = tagName;
    if (v.startsWith('v')) v = v.substring(1);
    return v;
  }

  /// 是否包含 APK 下载地址
  bool get hasApk => apkUrl != null && apkUrl!.isNotEmpty;
}

/// 升级服务
class UpdateService {
  /// GitHub API 最新 Release 地址
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/xiaoyudianbaba/CyberCalc/releases/latest';

  static const MethodChannel _channel =
      MethodChannel('cybercalc/update');

  /// 检查最新版本
  /// 返回 null 表示网络错误或无法解析
  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_latestReleaseUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return null;

      final tagName = data['tag_name'] as String? ?? '';
      final name = data['name'] as String? ?? tagName;
      final body = data['body'] as String? ?? '';
      final assets = data['assets'] as List? ?? [];

      String? apkUrl;
      String? apkName;
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final aName = asset['name'] as String? ?? '';
          if (aName.toLowerCase().endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkName = aName;
            break;
          }
        }
      }

      if (tagName.isEmpty) return null;
      return ReleaseInfo(
        tagName: tagName,
        name: name,
        body: body,
        apkUrl: apkUrl,
        apkName: apkName,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取当前安装的版本号
  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      return '0.0.0';
    }
  }

  /// 比较版本号，返回最新版本
  /// a 或 b 为 null 表示无法比较
  String? compareVersions(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);
    if (aParts == null || bParts == null) return null;
    for (var i = 0; i < 3; i++) {
      if (aParts[i] != bParts[i]) {
        return aParts[i] > bParts[i] ? a : b;
      }
    }
    return a; // 版本相同
  }

  /// 解析版本号为 [major, minor, patch]
  List<int>? _parseVersion(String v) {
    final parts = v.split('.');
    if (parts.length < 3) return null;
    final result = <int>[];
    for (final p in parts.take(3)) {
      final n = int.tryParse(p);
      if (n == null) return null;
      result.add(n);
    }
    return result;
  }

  /// 下载 APK 到应用目录，返回文件路径
  Future<String?> downloadApk(String url, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      // 清空旧文件
      if (await file.exists()) await file.delete();

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(minutes: 5),
          );
      if (response.statusCode != 200) return null;
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// 触发系统安装 APK
  /// 返回 (是否成功, 错误信息)
  Future<(bool, String)> installApk(String filePath) async {
    try {
      final result = await _channel.invokeMethod<String>('installApk', {
        'filePath': filePath,
      });
      if (result == 'ok') {
        return (true, '');
      }
      return (false, result ?? '未知错误');
    } on PlatformException catch (e) {
      return (false, e.message ?? '安装失败');
    } catch (e) {
      return (false, '安装失败: $e');
    }
  }
}