/// 语音按钮组件
/// 带脉冲动画的语音输入按钮
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class VoiceButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final bool enabled;

  const VoiceButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 72.0;
    final isActive = widget.isListening;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isActive
                ? CyberColors.voiceActive
                : CyberColors.numberButton,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? CyberColors.voiceActive
                  : CyberColors.voiceIdle.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: CyberColors.voiceGlow.withValues(
                    alpha: 0.3 + pulseValue * 0.5,
                  ),
                  blurRadius: 8 + pulseValue * 16,
                  spreadRadius: 2 + pulseValue * 8,
                )
              else
                BoxShadow(
                  color: CyberColors.voiceIdle.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Icon(
                  isActive ? Icons.mic : Icons.mic_none,
                  color: isActive
                      ? Colors.white
                      : CyberColors.voiceIdle,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}