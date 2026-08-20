/// 计算器主屏幕
/// 赛博朋克风格的计算器主界面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/calculator_service.dart';
import '../services/voice_feedback_service.dart';
import '../services/audio_service.dart';
import '../services/history_service.dart';
import '../services/volc_asr_service.dart';
import '../models/history_item.dart';
import '../models/voice_mode.dart';
import '../widgets/neon_button.dart';
import '../widgets/display_panel.dart';
import '../widgets/voice_button.dart';
import '../widgets/voice_indicator.dart';
import '../utils/chinese_number_converter.dart';
import '../screens/settings_screen.dart';
import '../theme/colors.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    // 注册火山 ASR 结果回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 加载历史记录（供输入框上方的历史列表展示）
      context.read<HistoryService>().loadHistory();
      final asr = context.read<VolcAsrService>();
      asr.onResult = () => _handleAsrResult(asr);
      asr.onListeningStarted = () => _onAsrListeningStarted();
      asr.onListeningStopped = () => _onAsrListeningStopped();
      asr.onError = (msg) => _onAsrError(msg);
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  /// ASR 识别结果回调
  void _handleAsrResult(VolcAsrService asr) {
    final text = asr.partialText;
    if (text.isEmpty) return;

    // 过滤 ASR 原始文本：只保留数字和运算符号，剔除全部中文/语气词/标点等
    final filtered = ChineseNumberConverter.filterToMathExpression(text);
    if (filtered.isEmpty) {
      // 过滤后为空说明不是算式语音，丢弃本次结果（容错）
      debugPrint('ASR: 过滤后无有效算式，忽略: $text');
      return;
    }
    _handleVoiceResult(filtered);
  }

  /// ASR 开始聆听
  void _onAsrListeningStarted() {
    // 更新UI，显示聆听状态
  }

  /// ASR 停止聆听
  void _onAsrListeningStopped() {
    // 更新UI，隐藏聆听状态
  }

  /// ASR 错误处理
  void _onAsrError(String msg) {
    // 弹窗提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontFamily: 'Orbitron'),
          ),
          backgroundColor: CyberColors.error.withValues(alpha: 0.8),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 处理按键点击
  void _handleKeyPress(String key) {
    final calc = context.read<CalculatorService>();
    final voice = context.read<VoiceFeedbackService>();

    // 播放音效
    _audioService.playKeySound(key);

    // 处理按键语音反馈
    final isDigit = RegExp(r'^[0-9.]$').hasMatch(key);

    if (isDigit) {
      // 智能模式：数字键不播报
      if (voice.voiceMode != VoiceMode.smart) {
        voice.speakKey(key);
      }
    } else {
      // 非数字键，播报按键
      voice.speakKey(key);
    }

    // 处理计算逻辑
    switch (key) {
      case 'C':
        calc.clear();
        break;
      case '⌫':
        calc.backspace();
        break;
      case '=':
        calc.calculate();
        // 播报结果
        if (!calc.hasError) {
          voice.speakResult(calc.result);
          // 保存历史记录
          _saveHistory(calc);
        }
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        calc.inputOperator(key);
        break;
      default:
        calc.inputDigit(key);
        break;
    }
  }

  /// 保存计算历史
  void _saveHistory(CalculatorService calc) {
    final history = context.read<HistoryService>();
    final expression = calc.expression;
    final result = calc.result;

    if (expression.isNotEmpty && result.isNotEmpty) {
      history.addItem(HistoryItem(
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
        hasError: calc.hasError,
      ));
    }
  }

  /// 处理语音识别结果
  void _handleVoiceResult(String convertedExpression) {
    if (convertedExpression.isEmpty) return;

    final calc = context.read<CalculatorService>();
    final voice = context.read<VoiceFeedbackService>();
    calc.clear();

    // 逐个输入识别到的字符
    for (int i = 0; i < convertedExpression.length; i++) {
      final char = convertedExpression[i];
      if (RegExp(r'^[0-9.]$').hasMatch(char)) {
        calc.inputDigit(char);
      } else if ('+-×÷'.contains(char)) {
        calc.inputOperator(char);
      } else if (char == '=') {
        calc.calculate();
      }
    }

    // 如果表达式完整，自动计算
    if (convertedExpression.isNotEmpty &&
        !'+-×÷'.contains(convertedExpression[convertedExpression.length - 1])) {
      calc.calculate();
    }

    // ========== 语音输入结果播报（仅播报结果，不播报算式/过程） ==========
    if (calc.hasError) {
      // 计算报错/表达式非法时，做异常提示
      voice.speakVoiceStatus('算式错误');
    } else {
      // 只播报最终结果："等于 XX"
      voice.speakResult(calc.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 标题栏（右上角含设置按钮）
            _buildTitleBar(),

            // 历史记录区域（位于输入框上方，支持垂直滚动）
            _buildHistorySection(),

            // 显示面板（输入框）
            Consumer<CalculatorService>(
              builder: (context, calc, child) {
                return DisplayPanel(
                  expression: calc.displayExpression,
                  result: calc.displayText,
                  hasError: calc.hasError,
                  errorMessage: calc.errorMessage,
                  isListening: context.watch<VolcAsrService>().isListening,
                );
              },
            ),

            // 语音识别指示器
            Consumer<VolcAsrService>(
              builder: (context, speech, child) {
                return VoiceIndicator(
                  isListening: speech.isListening,
                  recognizedText: speech.partialText,
                );
              },
            ),

            // 按键区域
            Expanded(
              child: _buildKeypad(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建历史记录区域
  /// 布局要求：标题栏 → 历史记录 → 输入框 → 按键区域
  /// 列表支持垂直滚动，条目增多可上下滑动查看
  Widget _buildHistorySection() {
    return Consumer<HistoryService>(
      builder: (context, history, child) {
        final items = history.items;
        if (items.isEmpty) {
          // 无历史记录时不占额外空间
          return const SizedBox.shrink();
        }

        return Container(
          // 固定高度区域，内部列表可滚动，避免挤压下方按键区域
          height: 140,
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          decoration: BoxDecoration(
            color: CyberColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CyberColors.numberGlow.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // 历史记录标题 + 清空按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '历史记录',
                      style: TextStyle(
                        color: CyberColors.secondaryText,
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _confirmClearHistory(history),
                      style: TextButton.styleFrom(
                        foregroundColor: CyberColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text(
                        '清空全部',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 可滚动历史列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _HistoryTile(
                      item: item,
                      onTap: () {
                        // 点击历史条目恢复算式与结果
                        final calc = context.read<CalculatorService>();
                        calc.restoreFromHistory(item.expression, item.result);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 确认清空历史记录
  void _confirmClearHistory(HistoryService history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.surface,
        title: const Text(
          '清空历史',
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        content: const Text(
          '确定要清除所有计算历史吗？\n此操作不可恢复。',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              history.clearAll();
              Navigator.of(ctx).pop();
            },
            child: const Text('确定清空', style: TextStyle(color: CyberColors.error)),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildTitleBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CyberColors.numberGlow.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'CYBERCALC',
            style: TextStyle(
              color: CyberColors.navActive,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontFamily: 'Orbitron',
              shadows: [
                Shadow(
                  color: CyberColors.navActive.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          Text(
            ' v1.0',
            style: TextStyle(
              color: CyberColors.disabledText,
              fontSize: 10,
              fontFamily: 'Orbitron',
            ),
          ),
          const Spacer(),
          // 语音模式指示器
          Consumer<VoiceFeedbackService>(
            builder: (context, voice, child) {
              final modeText = switch (voice.voiceMode) {
                VoiceMode.full => '语音',
                VoiceMode.smart => '智能',
                VoiceMode.silent => '静音',
              };
              final modeColor = switch (voice.voiceMode) {
                VoiceMode.full => CyberColors.voiceIdle,
                VoiceMode.smart => CyberColors.warning,
                VoiceMode.silent => CyberColors.disabledText,
              };
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: modeColor,
                      boxShadow: [
                        BoxShadow(
                          color: modeColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    modeText,
                    style: TextStyle(
                      color: modeColor,
                      fontSize: 12,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
          // 设置按钮（标题栏右上角）
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(
              Icons.settings,
              color: CyberColors.navActive,
              size: 20,
            ),
            tooltip: '设置',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 构建按键面板
  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 功能键行
          _buildFunctionRow(),
          const SizedBox(height: 8),
          // 数字和运算符键（4行×4列）
          Expanded(child: _buildNumberPad()),
        ],
      ),
    );
  }

  /// 构建功能键行
  Widget _buildFunctionRow() {
    return Row(
      children: [
        // 语音键
        Consumer<VolcAsrService>(
          builder: (context, speech, child) {
            return Expanded(
              child: VoiceButton(
                isListening: speech.isListening,
                enabled: !speech.isListening || true,
                onPressed: () => _toggleVoiceInput(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // C 键
        Expanded(
          child: NeonButton(
            label: 'C',
            type: NeonButtonType.function,
            onPressed: () => _handleKeyPress('C'),
          ),
        ),
        const SizedBox(width: 8),
        // ⌫ 键
        Expanded(
          child: NeonButton(
            label: '⌫',
            type: NeonButtonType.function,
            onPressed: () => _handleKeyPress('⌫'),
          ),
        ),
        const SizedBox(width: 8),
        // ÷ 键
        Expanded(
          child: NeonButton(
            label: '÷',
            type: NeonButtonType.divide,
            onPressed: () => _handleKeyPress('÷'),
          ),
        ),
      ],
    );
  }

  /// 构建数字按键面板（4行×4列）
  Widget _buildNumberPad() {
    return Column(
      children: [
        // 第1行：7 8 9 ×
        _buildNumberRow(['7', '8', '9', '×']),
        // 第2行：4 5 6 -
        _buildNumberRow(['4', '5', '6', '-']),
        // 第3行：1 2 3 +
        _buildNumberRow(['1', '2', '3', '+']),
        // 第4行：0 . =（0占两格）
        _buildLastRow(),
      ],
    );
  }

  /// 构建数字行
  Widget _buildNumberRow(List<String> keys) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: keys.map((key) {
            final isOperator = '+-×÷'.contains(key);
            NeonButtonType type;
            if (isOperator) {
              if (key == '+') type = NeonButtonType.add;
              else if (key == '-') type = NeonButtonType.subtract;
              else if (key == '×') type = NeonButtonType.multiply;
              else type = NeonButtonType.divide;
            } else {
              type = NeonButtonType.number;
            }
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: NeonButton(
                  label: key,
                  type: type,
                  onPressed: () => _handleKeyPress(key),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建最后一行（0 . =）
  Widget _buildLastRow() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // 0 键占两格
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: NeonButton(
                  label: '0',
                  type: NeonButtonType.number,
                  onPressed: () => _handleKeyPress('0'),
                ),
              ),
            ),
            // . 键
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: NeonButton(
                  label: '.',
                  type: NeonButtonType.number,
                  onPressed: () => _handleKeyPress('.'),
                ),
              ),
            ),
            // = 键
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: NeonButton(
                  label: '=',
                  type: NeonButtonType.equals,
                  onPressed: () => _handleKeyPress('='),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 切换语音输入状态
  Future<void> _toggleVoiceInput() async {
    final asr = context.read<VolcAsrService>();
    final voice = context.read<VoiceFeedbackService>();

    if (asr.isListening) {
      // 停止录音 → 自动发送到火山 ASR → 结果通过 onResult 回调处理
      await asr.stopListening();
      voice.speakVoiceStatus('语音输入结束');
    } else {
      // 检查是否已配置 API Key
      if (!asr.config.hasAccessToken) {
        _showAsrConfigRequired();
        return;
      }

      // 先播报提示音并等待播报完成，再加静音缓冲延时，
      // 确保提示音不被 ASR 录音录入
      final prompt = '语音输入已开启，请说出算式';
      await voice.speakVoiceStatusAndWait(prompt);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));

      // 提示音播放完毕后再开始录音
      final started = await asr.startListening();
      if (started) {
        // 录音已开始，不再重复播报（避免提示音被录入）
        debugPrint('ASR: 录音已开始');
      } else {
        // 启动失败（无权限、无API Key等），播报错误
        final error = asr.lastError;
        if (error.isNotEmpty) {
          voice.speakVoiceStatus(error);
          _onAsrError(error);
        }
      }
    }
  }

  /// 显示需要配置 ASR 的提示
  void _showAsrConfigRequired() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.surface,
        title: const Text(
          '需要配置语音识别',
          style: TextStyle(fontFamily: 'Orbitron', color: Colors.white),
        ),
        content: const Text(
          '请先在「设置」页面中配置火山引擎 ASR 的 API Key，\n然后即可使用语音输入功能。',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 跳转到设置页面
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Text('去设置', style: TextStyle(color: Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }
}

/// 历史记录条目组件
/// 用于输入框上方的历史列表展示
class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: CyberColors.historyItem,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.hasError
              ? CyberColors.error.withValues(alpha: 0.3)
              : CyberColors.numberGlow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              // 状态图标
              Icon(
                item.hasError ? Icons.error_outline : Icons.check_circle_outline,
                color: item.hasError ? CyberColors.error : CyberColors.success,
                size: 16,
              ),
              const SizedBox(width: 8),
              // 算式 + 结果
              Expanded(
                child: Text(
                  '${item.expression} = ${item.result}',
                  style: TextStyle(
                    color: item.hasError
                        ? CyberColors.error
                        : CyberColors.primaryText,
                    fontSize: 13,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}