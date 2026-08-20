/// 计算服务
/// 管理计算器的核心逻辑：算式构建、运算、状态管理
import 'package:flutter/foundation.dart';
import '../utils/math_parser.dart';

class CalculatorService extends ChangeNotifier {
  String _expression = ''; // 当前显示的算式
  String _result = '0'; // 当前结果
  bool _hasError = false; // 是否有错误
  String _errorMessage = ''; // 错误信息
  String _currentInput = ''; // 当前正在输入的数字
  bool _justCalculated = false; // 是否刚刚完成计算

  // ========== Getters ==========
  String get expression => _expression;
  String get result => _hasError ? _errorMessage : _result;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get currentInput => _currentInput;
  bool get justCalculated => _justCalculated;
  bool get isEmpty => _expression.isEmpty && _currentInput.isEmpty;

  /// 获取完整的显示文本（算式 + 结果）
  String get displayText {
    if (_hasError) return _errorMessage;
    if (_expression.isEmpty && _currentInput.isEmpty) return '0';
    return _currentInput.isNotEmpty ? _currentInput : _result;
  }

  // ========== 按键操作 ==========

  /// 输入数字
  void inputDigit(String digit) {
    if (_justCalculated) {
      // 刚计算完，开始新计算
      clear();
    }

    if (_hasError) {
      clear();
    }

    // 检查最大长度
    if (_currentInput.length >= 15) return;

    // 处理小数点
    if (digit == '.') {
      if (_currentInput.contains('.')) return; // 已有点
      if (_currentInput.isEmpty) _currentInput = '0';
    }

    // 避免前导零（除非是"0."）
    if (_currentInput == '0' && digit != '.') {
      _currentInput = digit;
    } else {
      _currentInput += digit;
    }

    notifyListeners();
  }

  /// 输入运算符
  void inputOperator(String operator) {
    if (_hasError) {
      clear();
    }

    _justCalculated = false;

    // 如果有当前输入，先加入表达式
    if (_currentInput.isNotEmpty) {
      _expression += _currentInput;
      _currentInput = '';
    }

    // 如果表达式为空且不是负号开头，忽略运算符
    if (_expression.isEmpty && operator != '-') {
      return;
    }

    // 替换末尾运算符
    if (_expression.isNotEmpty && '+-×÷*/'.contains(_expression[_expression.length - 1])) {
      _expression = _expression.substring(0, _expression.length - 1);
    }

    // 如果表达式以负号结尾且添加另一个运算符，忽略
    if (_expression.isEmpty && operator == '-') {
      _expression = '-';
    } else {
      _expression += operator;
    }

    notifyListeners();
  }

  /// 执行计算
  void calculate() {
    if (_hasError) return;

    // 将当前输入加入表达式
    if (_currentInput.isNotEmpty) {
      _expression += _currentInput;
      _currentInput = '';
    }

    if (_expression.isEmpty) return;

    // 检查表达式完整性
    if (!MathParser.isComplete(_expression)) {
      _hasError = true;
      _errorMessage = '表达式不完整';
      notifyListeners();
      return;
    }

    // 计算
    String calcResult = MathParser.calculate(_expression);

    if (calcResult.startsWith('表达式错误') ||
        calcResult == '语法错误' ||
        calcResult == '计算出错' ||
        calcResult == '除以零') {
      _hasError = true;
      _errorMessage = calcResult;
      notifyListeners();
      return;
    }

    _result = calcResult;
    _justCalculated = true;
    _hasError = false;
    notifyListeners();
  }

  /// 清除所有
  void clear() {
    _expression = '';
    _result = '0';
    _currentInput = '';
    _hasError = false;
    _errorMessage = '';
    _justCalculated = false;
    notifyListeners();
  }

  /// 退格
  void backspace() {
    if (_hasError) {
      clear();
      return;
    }

    if (_justCalculated) {
      clear();
      return;
    }

    if (_currentInput.isNotEmpty) {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    } else if (_expression.isNotEmpty) {
      // 从表达式中删除最后一个字符
      _expression = _expression.substring(0, _expression.length - 1);
      // 如果删除后末尾是运算符，继续删除
    }

    notifyListeners();
  }

  /// 从历史记录恢复表达式
  void restoreFromHistory(String expression, String result) {
    clear();
    _expression = expression;
    _result = result;
    _justCalculated = true;
    notifyListeners();
  }

  /// 获取用于显示的算式文本
  String get displayExpression {
    if (_expression.isEmpty) return '';
    String display = _expression;
    if (_currentInput.isNotEmpty) {
      display += _currentInput;
    }
    return display;
  }

  /// 获取完整的算式字符串（用于历史记录保存）
  String get fullExpression {
    String exp = _expression;
    if (_currentInput.isNotEmpty) {
      exp += _currentInput;
    }
    if (_justCalculated && _result != '0') {
      exp += '=$_result';
    }
    return exp;
  }
}