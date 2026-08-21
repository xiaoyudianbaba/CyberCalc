/// 数学表达式解析器
/// 解析字符串形式的数学表达式并计算结果
/// 仅支持加(+)、减(-)、乘(×)、除(÷)和括号()，全部本地解析，不使用大模型
/// 使用 math_expressions 包进行安全的表达式求值
import 'package:math_expressions/math_expressions.dart';

/// 数学表达式解析器
class MathParser {
  /// 允许出现在算式中的字符：数字、小数点、四则运算符、括号
  static final RegExp _allowedChars = RegExp(r'^[0-9.+\-*/()]+$');

  /// 解析并计算数学表达式
  static String calculate(String expression) {
    try {
      if (expression.isEmpty) return '0';

      String normalized = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('x', '*')
          .replaceAll('X', '*');

      // 去除末尾的运算符/小数点（例如 "3+5+" → "3+5"）
      while (normalized.isNotEmpty &&
          '+-*/'.contains(normalized[normalized.length - 1])) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      while (normalized.isNotEmpty && normalized.endsWith('.')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }

      if (normalized.isEmpty) return '0';

      // === 拦截非法表达式（只支持四则运算与括号）===
      final interception = _intercept(normalized);
      if (interception != null) return interception;

      Parser parser = Parser();
      Expression exp = parser.parse(normalized);

      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      if (result.isNaN) return '计算结果无效';
      if (result.isInfinite) return '除数不能为零';

      return _formatResult(result);
    } on Exception {
      return '算式格式有误';
    }
  }

  /// 拦截非法表达式，返回友好错误提示；合法则返回 null
  static String? _intercept(String expr) {
    // 1. 只允许数字、小数点、四则运算符和括号
    if (!_allowedChars.hasMatch(expr)) {
      return '算式含不支持的符号';
    }

    // 2. 括号必须成对匹配
    int depth = 0;
    bool expectOperand = true; // 期望数字或 '(' 或 '-'/'+' 一元
    for (int i = 0; i < expr.length; i++) {
      final c = expr[i];
      if (c == '(') {
        depth++;
        expectOperand = true;
      } else if (c == ')') {
        depth--;
        if (depth < 0) return '括号不匹配';
        expectOperand = false;
      } else if ('+-*/'.contains(c)) {
        if (expectOperand && c != '-' && c != '+') {
          // 运算符出现在不应出现的位置（连续运算符除一元 -/+）
          // 允许前导负号/正号以及括号内的负号/正号
          return '运算符位置错误';
        }
        expectOperand = true; // 运算符之后期望操作数
      } else {
        // 数字或小数点
        expectOperand = false;
      }
    }
    if (depth != 0) return '括号不匹配';

    // 3. 不能以二元运算符开头（允许前导负号/正号）
    if ('*/'.contains(expr[0])) {
      return '算式格式有误';
    }

    return null;
  }

  /// 格式化计算结果
  /// 修复浮点数精度问题（如 0.1+0.2≠0.30000000000000004）
  static String _formatResult(double value) {
    // 先四舍五入到 10 位小数，消除浮点误差尾部
    final rounded = double.parse(value.toStringAsFixed(10));

    // 处理整数（含浮点误差导致的近似整数，如 0.999999999）
    final asInt = rounded.round();
    if ((rounded - asInt).abs() < 1e-9) {
      return asInt.toString();
    }

    // 处理小数：去除多余的末尾零与小数点
    String formatted = rounded.toString();
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }

    // 限制总长度，过长使用科学计数法
    if (formatted.length > 15) {
      formatted = rounded.toStringAsExponential(6);
    }

    return formatted;
  }

  /// 判断计算结果是否为错误提示（而非数值）
  static bool isError(String result) {
    // 成功结果均为纯数值（可能含负号或科学计数法 e）
    if (RegExp(r'^-?[0-9.eE]+$').hasMatch(result)) return false;
    return true;
  }

  /// 检查表达式是否完整（可以计算）
  static bool isComplete(String expression) {
    if (expression.isEmpty) return false;

    // 不能以运算符结尾
    final lastChar = expression[expression.length - 1];
    if ('+-×÷*/'.contains(lastChar)) return false;

    // 不能以小数点结尾
    if (lastChar == '.') return false;

    // 括号必须成对
    int depth = 0;
    for (final c in expression.runes) {
      if (c == '('.codeUnitAt(0)) depth++;
      if (c == ')'.codeUnitAt(0)) depth--;
    }
    if (depth != 0) return false;

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