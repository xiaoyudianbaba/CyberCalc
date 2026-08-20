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
        ChangeNotifierProvider(
          create: (_) => VolcAsrService()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'CyberCalc',
        theme: CyberTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const CalculatorScreen(),
      ),
    );
  }
}