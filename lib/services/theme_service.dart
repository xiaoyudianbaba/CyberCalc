/// 主题服务
/// 管理主题状态和切换
import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';

class ThemeService extends ChangeNotifier {
  ThemeData _currentTheme = CyberTheme.theme;

  ThemeData get currentTheme => _currentTheme;

  /// 获取当前主题（不可变）
  ThemeData get theme => _currentTheme;

  /// 重置为默认赛博朋克主题
  void resetToDefault() {
    _currentTheme = CyberTheme.theme;
    notifyListeners();
  }
}