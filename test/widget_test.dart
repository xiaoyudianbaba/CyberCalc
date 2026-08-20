/// CyberCalc 组件测试

import 'package:flutter_test/flutter_test.dart';

import 'package:cybercalc/main.dart';

void main() {
  testWidgets('CyberCalc 应用启动测试', (WidgetTester tester) async {
    await tester.pumpWidget(const CyberCalcApp());

    // 验证标题存在
    expect(find.text('CYBERCALC'), findsOneWidget);

    // 验证数字按键存在
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // 验证运算符存在
    expect(find.text('+'), findsOneWidget);
    expect(find.text('='), findsOneWidget);

    // 验证功能键存在
    expect(find.text('C'), findsOneWidget);
    expect(find.text('⌫'), findsWidgets);
  });

  testWidgets('CyberCalc 导航测试', (WidgetTester tester) async {
    await tester.pumpWidget(const CyberCalcApp());

    // 点击历史按钮
    await tester.tap(find.text('历史'));
    await tester.pumpAndSettle();

    // 验证历史页面标题
    expect(find.text('历史记录'), findsOneWidget);

    // 点击计算器按钮
    await tester.tap(find.text('计算器'));
    await tester.pumpAndSettle();

    // 验证回到计算器
    expect(find.text('CYBERCALC'), findsOneWidget);
  });
}