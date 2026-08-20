/// 霓虹灯效按钮组件
/// 赛博朋克风格的按键，支持辉光动画和按压反馈
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 按钮类型枚举
enum NeonButtonType {
  number, // 数字键
  add, // 加法
  subtract, // 减法
  multiply, // 乘法
  divide, // 除法
  equals, // 等号
  function, // 功能键
  voice, // 语音键
}

class NeonButton extends StatefulWidget {
  final String label;
  final NeonButtonType type;
  final VoidCallback onPressed;
  final bool isLarge;
  final bool enabled;

  const NeonButton({
    super.key,
    required this.label,
    required this.type,
    required this.onPressed,
    this.isLarge = false,
    this.enabled = true,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // 辉光呼吸动画
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  /// 获取按钮颜色配置
  Color get _textColor {
    switch (widget.type) {
      case NeonButtonType.number:
        return CyberColors.numberText;
      case NeonButtonType.add:
        return CyberColors.addText;
      case NeonButtonType.subtract:
        return CyberColors.subtractText;
      case NeonButtonType.multiply:
        return CyberColors.multiplyText;
      case NeonButtonType.divide:
        return CyberColors.divideText;
      case NeonButtonType.equals:
        return CyberColors.equalsText;
      case NeonButtonType.function:
        return CyberColors.functionText;
      case NeonButtonType.voice:
        return CyberColors.voiceIdle;
    }
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case NeonButtonType.number:
        return CyberColors.numberButton;
      case NeonButtonType.equals:
        return CyberColors.equalsBackground;
      case NeonButtonType.function:
        return CyberColors.functionBackground;
      case NeonButtonType.voice:
        return CyberColors.numberButton;
      default:
        return Colors.transparent;
    }
  }

  List<BoxShadow> get _shadows {
    final color = _textColor;
    final opacity = _isPressed ? 0.8 : 0.4;
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.3),
        blurRadius: _isPressed ? 16 : 8,
        spreadRadius: _isPressed ? 4 : 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.15),
        blurRadius: _isPressed ? 24 : 12,
        spreadRadius: _isPressed ? 6 : 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isLarge ? 88.0 : 72.0;

    return AnimatedScale(
      scale: _isPressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _textColor.withValues(alpha: _isPressed ? 0.8 : 0.4),
            width: 1.5,
          ),
          boxShadow: _shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? () {
              setState(() => _isPressed = true);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) setState(() => _isPressed = false);
              });
              widget.onPressed();
            } : null,
            borderRadius: BorderRadius.circular(12),
            splashColor: _textColor.withValues(alpha: 0.2),
            highlightColor: _textColor.withValues(alpha: 0.1),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: widget.type == NeonButtonType.equals
                        ? [
                            BoxShadow(
                              color: _textColor.withValues(
                                alpha: _glowAnimation.value * 0.3,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.enabled
                        ? _textColor
                        : _textColor.withValues(alpha: 0.3),
                    fontSize: widget.isLarge ? 28 : 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    fontFamily: 'Orbitron',
                    shadows: [
                      Shadow(
                        color: _textColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}