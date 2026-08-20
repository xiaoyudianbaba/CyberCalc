/// 历史记录屏幕
/// 显示所有计算历史记录
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../services/calculator_service.dart';
import '../widgets/history_list.dart';
import '../theme/colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.historyBackground,
      appBar: AppBar(
        title: const Text('历史记录'),
        backgroundColor: CyberColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<HistoryService>(
        builder: (context, history, child) {
          return HistoryList(
            items: history.items,
            isEmpty: history.isEmpty,
            onItemTap: (item) {
              // 点击历史记录重新计算
              final calc = context.read<CalculatorService>();
              calc.restoreFromHistory(item.expression, item.result);
              Navigator.of(context).pop();
            },
            onClearAll: () => _confirmClearAll(context, history),
          );
        },
      ),
    );
  }

  /// 确认清空所有历史记录
  void _confirmClearAll(BuildContext context, HistoryService history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberColors.surface,
        title: Text(
          '清空历史',
          style: TextStyle(
            color: CyberColors.primaryText,
            fontFamily: 'Orbitron',
          ),
        ),
        content: Text(
          '确定要清除所有计算历史吗？\n此操作不可恢复。',
          style: TextStyle(
            color: CyberColors.secondaryText,
            fontFamily: 'Orbitron',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: CyberColors.functionText),
            ),
          ),
          TextButton(
            onPressed: () {
              history.clearAll();
              Navigator.of(ctx).pop();
            },
            child: Text(
              '确定清空',
              style: TextStyle(color: CyberColors.error),
            ),
          ),
        ],
      ),
    );
  }
}