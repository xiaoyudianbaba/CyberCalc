/// 语音状态指示器组件
/// 显示语音识别状态和声波动画
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class VoiceIndicator extends StatefulWidget {
  final bool isListening;
  final String recognizedText;

  const VoiceIndicator({
    super.key,
    required this.isListening,
    this.recognizedText = '',
  });

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isListening) {
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _waveController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening && widget.recognizedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.isListening)
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberColors.voiceActive.withValues(
                      alpha: 0.3 + _waveController.value * 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CyberColors.voiceActive.withValues(
                          alpha: _waveController.value * 0.5,
                        ),
                        blurRadius: 8 + _waveController.value * 8,
                        spreadRadius: _waveController.value * 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 14,
                  ),
                );
              },
            ),
          if (widget.isListening) const SizedBox(width: 8),
          if (widget.recognizedText.isNotEmpty)
            Expanded(
              child: Text(
                widget.recognizedText,
                style: TextStyle(
                  color: widget.isListening
                      ? CyberColors.voiceActive
                      : CyberColors.secondaryText,
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}