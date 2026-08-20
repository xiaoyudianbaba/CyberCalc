/// 历史记录服务
/// 使用 SQLite 存储和读取计算历史
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/history_item.dart';
import '../utils/constants.dart';

class HistoryService extends ChangeNotifier {
  Database? _database;
  List<HistoryItem> _items = [];
  bool _isLoaded = false;

  List<HistoryItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;
  bool get isEmpty => _items.isEmpty;

  /// 打开数据库连接
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.historyTableName} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            expression TEXT NOT NULL,
            result TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            hasError INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  /// 加载历史记录
  Future<void> loadHistory() async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.historyTableName,
        orderBy: 'timestamp DESC',
        limit: 100,
      );

      _items = maps.map((map) => HistoryItem.fromMap(map)).toList();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Load history error: $e');
      _isLoaded = true;
    }
  }

  /// 添加历史记录
  Future<int> addItem(HistoryItem item) async {
    try {
      final db = await database;
      final id = await db.insert(
        AppConstants.historyTableName,
        item.toMap(),
      );

      // 更新内存中的列表
      _items.insert(0, HistoryItem(
        id: id,
        expression: item.expression,
        result: item.result,
        timestamp: item.timestamp,
        hasError: item.hasError,
      ));

      // 限制历史数量
      if (_items.length > 100) {
        final lastItem = _items.last;
        if (lastItem.id != null) {
          await db.delete(
            AppConstants.historyTableName,
            where: 'id = ?',
            whereArgs: [lastItem.id],
          );
          _items.removeLast();
        }
      }

      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Add history error: $e');
      return -1;
    }
  }

  /// 清空所有历史记录
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete(AppConstants.historyTableName);
      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Clear history error: $e');
    }
  }

  /// 删除单条历史记录
  Future<void> deleteItem(int id) async {
    try {
      final db = await database;
      await db.delete(
        AppConstants.historyTableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete history error: $e');
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}