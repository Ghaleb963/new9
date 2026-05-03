import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/properties/models/property_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('real_estate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      // [تعديل] رُفع الإصدار من 1 إلى 2 لإضافة حقل entry_type.
      // استخدام onUpgrade بدلاً من حذف قاعدة البيانات يضمن عدم فقدان
      // أي بيانات موجودة لدى المستخدمين الحاليين (Non-destructive Migration).
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // يُستدعى مرة واحدة فقط عند إنشاء DB لأول مرة — يتضمن جميع الأعمدة كاملة
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_type TEXT NOT NULL DEFAULT 'offer',
        adType TEXT NOT NULL DEFAULT '',
        deedType TEXT NOT NULL DEFAULT '',
        propertyType TEXT NOT NULL DEFAULT '',
        province TEXT NOT NULL DEFAULT '',
        region TEXT NOT NULL DEFAULT '',
        addressDetails TEXT NOT NULL DEFAULT '',
        floor TEXT NOT NULL DEFAULT '',
        rooms INTEGER NOT NULL DEFAULT 0,
        area REAL NOT NULL DEFAULT 0,
        hasGarden INTEGER NOT NULL DEFAULT 0,
        isDuplex INTEGER NOT NULL DEFAULT 0,
        facade TEXT NOT NULL DEFAULT '',
        directions TEXT NOT NULL DEFAULT '[]',
        finishingLevel TEXT NOT NULL DEFAULT '',
        features TEXT NOT NULL DEFAULT '[]',
        ownershipType TEXT NOT NULL DEFAULT '',
        ownershipDetails TEXT NOT NULL DEFAULT '',
        sharesCount INTEGER,
        price REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT '',
        ownerName TEXT NOT NULL DEFAULT '',
        ownerWhatsapp TEXT NOT NULL DEFAULT '',
        officeName TEXT NOT NULL DEFAULT '',
        contactPhone TEXT NOT NULL DEFAULT '',
        facebookLink TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        images TEXT NOT NULL DEFAULT '[]',
        videos TEXT NOT NULL DEFAULT '[]',
        ownerStatus TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  // يُستدعى تلقائياً عند ترقية المستخدمين الحاليين من إصدار قديم.
  // كل block محمي بشرط oldVersion < X لضمان تطبيق الـ migration بالترتيب الصحيح
  // دون تكرار حتى لو قفز المستخدم من إصدار 1 مباشرةً إلى 3 في المستقبل.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة حقل entry_type للسجلات الموجودة — DEFAULT 'offer' يضمن
      // أن جميع العقارات القديمة ستُصنَّف كـ "عرض" تلقائياً وبشكل صحيح
      await db.execute(
        "ALTER TABLE properties ADD COLUMN entry_type TEXT NOT NULL DEFAULT 'offer'",
      );
    }
    // مستقبلاً: if (oldVersion < 3) { ... }
  }

  Future<int> insertProperty(PropertyModel property) async {
    final db = await instance.database;
    return await db.insert('properties', property.toMap());
  }

  Future<int> updateProperty(PropertyModel property) async {
    final db = await instance.database;
    return await db.update(
      'properties',
      property.toMap(),
      where: 'id = ?',
      whereArgs: [property.id],
    );
  }

  Future<int> deleteProperty(int id) async {
    final db = await instance.database;
    return await db.delete(
      'properties',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PropertyModel>> getAllProperties() async {
    final db = await instance.database;
    final result = await db.query('properties', orderBy: 'id DESC');
    return result.map((json) => PropertyModel.fromMap(json)).toList();
  }

  Future<int> getPropertiesCount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM properties'));
    return count ?? 0;
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'real_estate.db');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// يتحقق مما إذا كان الملف المختار هو قاعدة بيانات صالحة للمشروع.
  Future<bool> isValidDatabase(String path) async {
    Database? tempDb;
    try {
      tempDb = await openReadOnlyDatabase(path);
      // التحقق من وجود جدول properties
      final tables = await tempDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='properties'");
      if (tables.isEmpty) return false;

      // التحقق من وجود بعض الأعمدة الأساسية للتأكد من أنها قاعدة بيانات هذا التطبيق تحديداً
      final columns = await tempDb.rawQuery('PRAGMA table_info(properties)');
      final columnNames = columns.map((c) => c['name'] as String).toList();

      final requiredColumns = ['id', 'entry_type', 'adType', 'ownerName'];
      for (var col in requiredColumns) {
        if (!columnNames.contains(col)) return false;
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      await tempDb?.close();
    }
  }
}
