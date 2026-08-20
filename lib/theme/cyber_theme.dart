/// 赛博朋克主题配置
/// 定义全局主题样式、输入装饰和动画配置
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class CyberTheme {
  CyberTheme._();

  /// 获取赛博朋克主题的 ThemeData
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CyberColors.background,
      primaryColor: CyberColors.navActive,
      colorScheme: const ColorScheme.dark(
        primary: CyberColors.navActive,
        secondary: CyberColors.addText,
        surface: CyberColors.surface,
        error: CyberColors.error,
        onPrimary: CyberColors.primaryText,
        onSecondary: CyberColors.primaryText,
        onSurface: CyberColors.primaryText,
        onError: CyberColors.primaryText,
      ),

      // 字体配置
      textTheme: GoogleFonts.getTextTheme(
        'Orbitron',
        const TextTheme(
          displayLarge: TextStyle(
            color: CyberColors.resultText,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          displayMedium: TextStyle(
            color: CyberColors.resultText,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          headlineMedium: TextStyle(
            color: CyberColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          titleLarge: TextStyle(
            color: CyberColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          titleMedium: TextStyle(
            color: CyberColors.expressionText,
            fontSize: 18,
            letterSpacing: 1,
          ),
          bodyLarge: TextStyle(
            color: CyberColors.primaryText,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: CyberColors.secondaryText,
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            color: CyberColors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ).apply(
        displayColor: CyberColors.primaryText,
        bodyColor: CyberColors.primaryText,
      ),

      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: CyberColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          color: CyberColors.navActive,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(
          color: CyberColors.navActive,
        ),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CyberColors.navBackground,
        selectedItemColor: CyberColors.navActive,
        unselectedItemColor: CyberColors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),

      // 对话框主题
      dialogTheme: const DialogThemeData(
        backgroundColor: CyberColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: CyberColors.historyDivider,
        thickness: 1,
      ),

      // 卡片主题
      cardTheme: const CardThemeData(
        color: CyberColors.historyItem,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  /// 创建霓虹灯辉光效果
  static List<BoxShadow> neonGlow(Color color, {double opacity = 0.5}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.3),
        blurRadius: 8,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.5),
        blurRadius: 16,
        spreadRadius: 4,
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.2),
        blurRadius: 24,
        spreadRadius: 6,
      ),
    ];
  }

  /// 霓虹灯文字样式（带辉光效果）
  static TextStyle neonText({
    required Color color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 2,
  }) {
    return GoogleFonts.orbitron(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.8),
          blurRadius: 8,
        ),
        Shadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 16,
        ),
      ],
    );
  }

  /// 按钮霓虹灯边框
  static BoxDecoration neonBorder({
    required Color borderColor,
    Color? backgroundColor,
    double borderRadius = 12,
    double borderWidth = 1.5,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor.withValues(alpha: 0.6),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: borderColor.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: borderColor.withValues(alpha: 0.1),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    );
  }
}