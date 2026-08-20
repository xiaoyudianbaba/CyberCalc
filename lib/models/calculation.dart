/// 计算结果模型
/// 存储一次计算的所有相关信息
class Calculation {
  final String expression; // 原始算式
  final String result; // 计算结果
  final DateTime timestamp; // 计算时间
  final bool hasError; // 是否有错误
  final String? errorMessage; // 错误信息

  Calculation({
    required this.expression,
    required this.result,
    required this.timestamp,
    this.hasError = false,
    this.errorMessage,
  });

  /// 从数据库 Map 创建
  factory Calculation.fromMap(Map<String, dynamic> map) {
    return Calculation(
      expression: map['expression'] as String,
      result: map['result'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      hasError: (map['hasError'] as int) == 1,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  /// 转为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'expression': expression,
      'result': result,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'hasError': hasError ? 1 : 0,
      'errorMessage': errorMessage,
    };
  }
}