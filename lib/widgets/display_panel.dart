/// 显示面板组件
/// 赛博朋克风格的算式与结果显示面板，宽度固定
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';

class DisplayPanel extends StatelessWidget {
  final String expression;
  final String result;
  final bool hasError;
  final String? errorMessage;
  final bool isListening;

  const DisplayPanel({
    super.key,
    required this.expression,
    required this.result,
    this.hasError = false,
    this.errorMessage,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 固定宽度
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
        minWidth: double.infinity,
      ),
      height: 160,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberColors.displayBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? CyberColors.error.withValues(alpha: 0.6)
              : isListening
                  ? CyberColors.voiceActive.withValues(alpha: 0.6)
                  : CyberColors.numberGlow.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? CyberColors.error.withValues(alpha: 0.2)
                : isListening
                    ? CyberColors.voiceActive.withValues(alpha: 0.2)
                    : CyberColors.numberGlow.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 识别状态指示
          if (isListening)
            Container(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic,
                    color: CyberColors.voiceActive,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '聆听中...',
                    style: GoogleFonts.orbitron(
                      color: CyberColors.voiceActive,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

          // 错误信息
          if (hasError && errorMessage != null)
            Container(
              padding: const EdgeInsets.only(right: 16, bottom: 4),
              child: Text(
                errorMessage!,
                style: GoogleFonts.orbitron(
                  color: CyberColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: CyberColors.error.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
            ),

          // 算式显示
          if (expression.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(right: 16, bottom: 4),
              child: Text(
                expression,
                style: GoogleFonts.orbitron(
                  color: CyberColors.expressionText,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 结果显示 - 使用 FittedBox 确保不撑大
          Container(
            padding: const EdgeInsets.only(right: 16, bottom: 12),
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                result,
                style: GoogleFonts.orbitron(
                  color: hasError
                      ? CyberColors.error
                      : CyberColors.resultText,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    if (!hasError)
                      Shadow(
                        color: CyberColors.numberGlow.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    if (hasError)
                      Shadow(
                        color: CyberColors.error.withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                  ],
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}