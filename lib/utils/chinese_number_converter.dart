/// 中文数字转换器
/// 将中文数字/数学符号转换为标准数学表达式
class ChineseNumberConverter {
  /// 中文数字到阿拉伯数字的映射
  static const Map<String, String> chineseToDigit = {
    '零': '0',
    '一': '1',
    '二': '2',
    '两': '2',
    '三': '3',
    '四': '4',
    '五': '5',
    '六': '6',
    '七': '7',
    '八': '8',
    '九': '9',
    '十': '10',
  };

  /// 中文运算符到标准运算符的映射
  static const Map<String, String> chineseToOperator = {
    '加': '+',
    '加上': '+',
    '减': '-',
    '减去': '-',
    '乘': '×',
    '乘以': '×',
    '除': '÷',
    '除以': '÷',
    '等于': '=',
  };

  /// 其他中文词汇映射
  static const Map<String, String> chineseWordToSymbol = {
    '点': '.',
    '百分号': '%',
    '左括号': '(',
    '右括号': ')',
  };

  /// 将中文语音文本转换为数学表达式字符串
  /// 例如："三加五" → "3+5"
  static String convertToMathExpression(String spokenText) {
    String result = spokenText.trim();

    // 替换运算符
    for (final entry in chineseToOperator.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // 替换符号
    for (final entry in chineseWordToSymbol.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // 处理中文数字（需要特殊处理，因为"十二"应该是"12"而不是"10 2"）
    result = _convertChineseNumbers(result);

    // 清理多余空格
    result = result.replaceAll(' ', '');

    return result;
  }

  /// 智能转换中文数字
  /// 处理如"十二"→"12"、"一百二十三"→"123"等
  static String _convertChineseNumbers(String text) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < text.length) {
      final char = text[i];

      if (chineseToDigit.containsKey(char)) {
        // 收集连续的中文数字序列
        final numBuffer = StringBuffer();
        while (i < text.length && chineseToDigit.containsKey(text[i])) {
          numBuffer.write(text[i]);
          i++;
        }
        buffer.write(_parseChineseNumberSequence(numBuffer.toString()));
      } else {
        buffer.write(char);
        i++;
      }
    }

    return buffer.toString();
  }

  /// 解析中文数字序列
  /// "十二" → "12"，"三百五十六" → "356"
  static String _parseChineseNumberSequence(String chineseNum) {
    if (chineseNum.isEmpty) return '';

    // 简单映射：单个数字直接转换
    if (chineseNum.length == 1) {
      return chineseToDigit[chineseNum] ?? chineseNum;
    }

    // 尝试智能解析组合数字
    int result = 0;
    int current = 0;
    bool hasUnit = false;

    for (int i = 0; i < chineseNum.length; i++) {
      final char = chineseNum[i];

      if (char == '十') {
        if (current == 0) current = 1;
        current *= 10;
        result += current;
        current = 0;
        hasUnit = true;
      } else if (char == '百') {
        if (current == 0) current = 1;
        current *= 100;
        result += current;
        current = 0;
        hasUnit = true;
      } else if (char == '千') {
        if (current == 0) current = 1;
        current *= 1000;
        result += current;
        current = 0;
        hasUnit = true;
      } else if (char == '万') {
        if (current == 0) current = 1;
        current *= 10000;
        result += current;
        current = 0;
        hasUnit = true;
      } else {
        // 数字
        current = int.parse(chineseToDigit[char] ?? '0');
      }
    }

    if (current > 0) {
      result += current;
    }

    if (result == 0 && !hasUnit) {
      // 如果没有单位，可能是多个单独数字，如"三五"→"35"
      // 或者直接拼接"一二三"→"123"
      String concat = '';
      for (int i = 0; i < chineseNum.length; i++) {
        concat += chineseToDigit[chineseNum[i]] ?? chineseNum[i];
      }
      return concat;
    }

    return result.toString();
  }

  /// 判断文本是否为中文数字/数学表达式
  static bool isChineseMathExpression(String text) {
    if (text.isEmpty) return false;
    // 检查是否包含中文数字或运算符
    return chineseToDigit.keys.any((k) => text.contains(k)) ||
        chineseToOperator.keys.any((k) => text.contains(k));
  }
}