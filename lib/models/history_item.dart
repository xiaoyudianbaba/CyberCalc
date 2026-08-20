/// 历史记录条目模型
/// 用于在历史列表中显示
class HistoryItem {
  final int? id;
  final String expression;
  final String result;
  final DateTime timestamp;
  final bool hasError;

  HistoryItem({
    this.id,
    required this.expression,
    required this.result,
    required this.timestamp,
    this.hasError = false,
  });

  /// 从数据库 Map 创建
  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as int?,
      expression: map['expression'] as String,
      result: map['result'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      hasError: (map['hasError'] as int) == 1,
    );
  }

  /// 转为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'expression': expression,
      'result': result,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'hasError': hasError ? 1 : 0,
    };
  }
}