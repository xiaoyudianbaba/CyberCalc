/// CyberCalc - 赛博朋克语音计算器
/// 主入口文件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/calculator_service.dart';
import 'services/voice_feedback_service.dart';
import 'services/audio_service.dart';
import 'services/history_service.dart';
import 'services/volc_asr_service.dart';
import 'screens/calculator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/cyber_theme.dart';
import 'theme/colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: CyberColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 强制竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CyberCalcApp());
}

/// CyberCalc 应用根组件
class CyberCalcApp extends StatelessWidget {
  const CyberCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalculatorService()),
        // 语音识别由 VolcAsrService 替代（见下方）
        ChangeNotifierProvider(create: (_) => VoiceFeedbackService()),
        ChangeNotifierProvider(create: (_) => HistoryService()),
        Provider(create: (_) => AudioService()),
        // 火山引擎 ASR 语音识别服务（替换旧的 speech_to_text）
        ChangeNotifierProvider(create: (_) => VolcAsrService()),
      ],
      child: MaterialApp(
        title: 'CyberCalc',
        theme: CyberTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const MainNavigationShell(),
      ),
    );
  }
}

/// 主导航外壳
/// 管理底部导航和页面切换
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CalculatorScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: CyberColors.navBackground,
          border: Border(
            top: BorderSide(
              color: CyberColors.numberGlow.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildNavItem(0, Icons.calculate, '计算器'),
            _buildNavItem(1, Icons.history, '历史'),
            _buildNavButton(Icons.settings, '设置', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建导航项
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? CyberColors.navActive
                    : CyberColors.navInactive,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? CyberColors.navActive
                      : CyberColors.navInactive,
                  fontSize: 10,
                  fontFamily: 'Orbitron',
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建导航按钮
  Widget _buildNavButton(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: CyberColors.navInactive,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: CyberColors.navInactive,
                  fontSize: 10,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}