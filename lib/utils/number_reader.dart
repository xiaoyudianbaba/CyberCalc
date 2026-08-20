/// 数字朗读器
/// 将数字转换为中文朗读文本
/// 支持连续数字智能朗读（如"123"→"一百二十三"）
class NumberReader {
  /// 单个数字到中文的映射
  static const Map<String, String> digitToChinese = {
    '0': '零',
    '1': '一',
    '2': '二',
    '3': '三',
    '4': '四',
    '5': '五',
    '6': '六',
    '7': '七',
    '8': '八',
    '9': '九',
  };

  /// 运算符到中文的映射（用于播报）
  static const Map<String, String> operatorToChinese = {
    '+': '加',
    '-': '减',
    '×': '乘以',
    '*': '乘以',
    '÷': '除以',
    '/': '除以',
    '=': '等于',
    '.': '点',
    '%': '百分之',
  };

  /// 读取单个按键的中文读音
  static String readKey(String key) {
    if (digitToChinese.containsKey(key)) {
      return digitToChinese[key]!;
    }
    if (operatorToChinese.containsKey(key)) {
      return operatorToChinese[key]!;
    }
    // 特殊按键
    switch (key) {
      case 'C':
        return '清除';
      case '⌫':
        return '退格';
      case '🎤':
        return '语音输入';
      default:
        return key;
    }
  }

  /// 智能读取数字序列
  /// "123" → "一百二十三"
  /// "3.14" → "三点一四"
  static String readNumber(String numberStr) {
    if (numberStr.isEmpty) return '';

    // 处理小数点
    if (numberStr.contains('.')) {
      final parts = numberStr.split('.');
      final intPart = _readInteger(parts[0]);
      final decPart = parts[1].split('').map((d) => digitToChinese[d] ?? d).join();
      return '$intPart点$decPart';
    }

    return _readInteger(numberStr);
  }

  /// 读取整数部分
  static String _readInteger(String numStr) {
    // 移除前导零
    numStr = numStr.replaceAll(RegExp(r'^0+'), '');
    if (numStr.isEmpty) return '零';

    final n = int.tryParse(numStr);
    if (n == null) {
      // 非纯数字，逐个读
      return numStr.split('').map((c) => digitToChinese[c] ?? c).join('');
    }

    if (n < 10) {
      return digitToChinese[numStr]!;
    }
    if (n < 100) {
      return _readTwoDigit(n);
    }
    if (n < 1000) {
      return _readThreeDigit(n);
    }
    if (n < 10000) {
      return _readFourDigit(n);
    }
    // 大于等于10000，逐位朗读
    return numStr.split('').map((c) => digitToChinese[c] ?? c).join('');
  }

  static String _readTwoDigit(int n) {
    if (n < 10) return digitToChinese[n.toString()]!;
    final ten = n ~/ 10;
    final unit = n % 10;
    if (ten == 1) {
      return unit == 0 ? '十' : '十${digitToChinese[unit.toString()]!}';
    } else {
      return unit == 0
          ? '${digitToChinese[ten.toString()]!}十'
          : '${digitToChinese[ten.toString()]!}十${digitToChinese[unit.toString()]!}';
    }
  }

  static String _readThreeDigit(int n) {
    final hundred = n ~/ 100;
    final rest = n % 100;
    if (rest == 0) {
      return '${digitToChinese[hundred.toString()]!}百';
    } else if (rest < 10) {
      return '${digitToChinese[hundred.toString()]!}百零${digitToChinese[rest.toString()]!}';
    } else {
      return '${digitToChinese[hundred.toString()]!}百${_readTwoDigit(rest)}';
    }
  }

  static String _readFourDigit(int n) {
    final thousand = n ~/ 1000;
    final rest = n % 1000;
    if (rest == 0) {
      return '${digitToChinese[thousand.toString()]!}千';
    } else if (rest < 100) {
      return '${digitToChinese[thousand.toString()]!}千零${_readTwoDigit(rest)}';
    } else {
      return '${digitToChinese[thousand.toString()]!}千${_readThreeDigit(rest)}';
    }
  }

  /// 读取完整算式
  /// "5+3" → "五加三"
  static String readExpression(String expression) {
    final buffer = StringBuffer();
    String currentNum = '';

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (RegExp(r'[0-9.]').hasMatch(char)) {
        currentNum += char;
      } else {
        // 读出已收集的数字
        if (currentNum.isNotEmpty) {
          buffer.write(readNumber(currentNum));
          currentNum = '';
        }
        // 读出运算符
        buffer.write(operatorToChinese[char] ?? char);
      }
    }

    // 读出最后剩余的数字
    if (currentNum.isNotEmpty) {
      buffer.write(readNumber(currentNum));
    }

    return buffer.toString();
  }

  /// 读取计算结果
  /// "8" → "八"
  static String readResult(String result) {
    // 处理负数
    if (result.startsWith('-')) {
      return '负${readNumber(result.substring(1))}';
    }
    // 处理错误
    if (result == '错误' || result == 'Error') {
      return '计算出错';
    }
    return readNumber(result);
  }
}