/// 历史列表组件
/// 显示计算历史记录列表
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/history_item.dart';
import '../theme/colors.dart';

class HistoryList extends StatelessWidget {
  final List<HistoryItem> items;
  final Function(HistoryItem) onItemTap;
  final VoidCallback onClearAll;
  final bool isEmpty;

  const HistoryList({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onClearAll,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: CyberColors.disabledText,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无计算记录',
              style: GoogleFonts.orbitron(
                color: CyberColors.disabledText,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 清空按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '历史记录',
                style: GoogleFonts.orbitron(
                  color: CyberColors.secondaryText,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: CyberColors.error,
                ),
                child: Text(
                  '清空全部',
                  style: TextStyle(
                    color: CyberColors.error,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _HistoryItemCard(
                item: item,
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const _HistoryItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: CyberColors.historyItem,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.hasError
              ? CyberColors.error.withValues(alpha: 0.3)
              : CyberColors.numberGlow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.hasError
                      ? CyberColors.error.withValues(alpha: 0.1)
                      : CyberColors.numberGlow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.hasError ? Icons.error_outline : Icons.check_circle_outline,
                  color: item.hasError ? CyberColors.error : CyberColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.expression,
                      style: GoogleFonts.orbitron(
                        color: CyberColors.primaryText,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '= ${item.result}',
                      style: GoogleFonts.orbitron(
                        color: item.hasError
                            ? CyberColors.error
                            : CyberColors.numberText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 时间
              Text(
                _formatTime(item.timestamp),
                style: GoogleFonts.orbitron(
                  color: CyberColors.disabledText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚才';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}