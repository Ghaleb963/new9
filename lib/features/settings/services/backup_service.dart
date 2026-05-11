import 'dart:io';
import '../../../core/database/database_helper.dart';

class BackupService {
  static Future<void> exportTo(String destinationPath) async {
    final dbPath = await DatabaseHelper.instance.getDatabasePath();
    final sourceFile = File(dbPath);
    if (!await sourceFile.exists()) {
      throw Exception('ملف قاعدة البيانات غير موجود');
    }
    await sourceFile.copy(destinationPath);
  }

  static Future<bool> isValidBackup(String filePath) {
    return DatabaseHelper.instance.isValidDatabase(filePath);
  }

  static Future<void> restoreFrom(String sourcePath) async {
    final db = DatabaseHelper.instance;
    await db.closeDatabase();
    final dbPath = await db.getDatabasePath();
    await File(sourcePath).copy(dbPath);
    await db.database;
  }
}
