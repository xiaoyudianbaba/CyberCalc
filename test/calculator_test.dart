/// 计算器服务单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:cybercalc/utils/math_parser.dart';
import 'package:cybercalc/utils/chinese_number_converter.dart';
import 'package:cybercalc/utils/number_reader.dart';

void main() {
  group('MathParser - 数学表达式解析测试', () {
    test('基础加法', () {
      expect(MathParser.calculate('2+3'), '5');
    });

    test('基础减法', () {
      expect(MathParser.calculate('10-4'), '6');
    });

    test('基础乘法', () {
      expect(MathParser.calculate('6×7'), '42');
    });

    test('基础除法', () {
      expect(MathParser.calculate('15÷3'), '5');
    });

    test('带小数点的运算', () {
      expect(MathParser.calculate('3.5+2.1'), '5.6');
    });

    test('连续运算', () {
      expect(MathParser.calculate('2+3×4'), '14');
    });

    test('除零错误', () {
      expect(MathParser.calculate('5÷0'), '除以零');
    });

    test('空表达式', () {
      expect(MathParser.calculate(''), '0');
    });

    test('表达式不完整', () {
      expect(MathParser.isComplete('2+'), isFalse);
    });

    test('完整表达式', () {
      expect(MathParser.isComplete('2+3'), isTrue);
    });
  });

  group('ChineseNumberConverter - 中文数字转换测试', () {
    test('简单加法', () {
      expect(
        ChineseNumberConverter.convertToMathExpression('三加五'),
        '3+5',
      );
    });

    test('简单减法', () {
      expect(
        ChineseNumberConverter.convertToMathExpression('十减四'),
        '10-4',
      );
    });

    test('乘法运算', () {
      expect(
        ChineseNumberConverter.convertToMathExpression('六乘以七'),
        '6×7',
      );
    });

    test('除法运算', () {
      expect(
        ChineseNumberConverter.convertToMathExpression('十五除以三'),
        '15÷3',
      );
    });

    test('中文数字检测', () {
      expect(
        ChineseNumberConverter.isChineseMathExpression('三加五'),
        isTrue,
      );
      expect(
        ChineseNumberConverter.isChineseMathExpression('hello'),
        isFalse,
      );
    });
  });

  group('NumberReader - 数字朗读测试', () {
    test('单个数字', () {
      expect(NumberReader.readKey('1'), '一');
      expect(NumberReader.readKey('5'), '五');
      expect(NumberReader.readKey('0'), '零');
    });

    test('运算符', () {
      expect(NumberReader.readKey('+'), '加');
      expect(NumberReader.readKey('-'), '减');
      expect(NumberReader.readKey('×'), '乘以');
      expect(NumberReader.readKey('÷'), '除以');
    });

    test('功能键', () {
      expect(NumberReader.readKey('C'), '清除');
      expect(NumberReader.readKey('⌫'), '退格');
    });

    test('数字朗读', () {
      expect(NumberReader.readNumber('8'), '八');
      expect(NumberReader.readNumber('15'), '十五');
      expect(NumberReader.readNumber('123'), '一百二十三');
    });

    test('小数朗读', () {
      expect(NumberReader.readNumber('3.14'), '三点一四');
    });

    test('算式朗读', () {
      expect(NumberReader.readExpression('5+3'), '五加三');
    });
  });
}