/// 数学表达式解析器
/// 解析字符串形式的数学表达式并计算结果
/// 使用 math_expressions 包进行安全的表达式求值
import 'package:math_expressions/math_expressions.dart';

/// 数学表达式解析器
class MathParser {
  /// 解析并计算数学表达式
  static String calculate(String expression) {
    try {
      if (expression.isEmpty) return '0';

      String normalized = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('x', '*')
          .replaceAll('X', '*');

      while (normalized.isNotEmpty &&
          '+-*/'.contains(normalized[normalized.length - 1])) {
        normalized = normalized.substring(0, normalized.length - 1);
      }

      if (normalized.isEmpty) return '0';

      if ('*/'.contains(normalized[0])) {
        return '语法错误';
      }

      Parser parser = Parser();
      Expression exp = parser.parse(normalized);

      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      if (result.isNaN) return '计算出错';
      if (result.isInfinite) return '除以零';

      return _formatResult(result);
    } on Exception {
      return '表达式错误';
    }
  }

  /// 格式化计算结果
  /// 最多保留10位小数，去除多余的末尾零
  static String _formatResult(double value) {
    // 处理整数
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    // 处理小数：最多10位
    String formatted = value.toStringAsFixed(10);

    // 去除多余的末尾零
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');

    // 去除末尾的小数点
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');

    // 限制总长度
    if (formatted.length > 15) {
      formatted = value.toStringAsExponential(6);
    }

    return formatted;
  }

  /// 检查表达式是否完整（可以计算）
  static bool isComplete(String expression) {
    if (expression.isEmpty) return false;

    // 不能以运算符结尾
    final lastChar = expression[expression.length - 1];
    if ('+-×÷*/'.contains(lastChar)) return false;

    // 不能以小数点结尾
    if (lastChar == '.') return false;

    return true;
  }

  /// 获取表达式中的最后一个数字
  static String getLastNumber(String expression) {
    final buffer = StringBuffer();
    for (int i = expression.length - 1; i >= 0; i--) {
      final char = expression[i];
      if (RegExp(r'[0-9.]').hasMatch(char)) {
        buffer.write(char);
      } else {
        break;
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}