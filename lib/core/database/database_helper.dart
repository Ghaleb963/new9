import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/properties/models/property_model.dart';

class DatabaseHelper {
  // ═══════════════════════════════════════════════════════════
  //  Constants
  // ═══════════════════════════════════════════════════════════
  static const String _dbFilename = 'real_estate.db';
  static const String tableProperties = 'properties';
  static const int _dbVersion = 4;

  /// الأعمدة المتوقعة — مرجع واحد يُستخدم للتحقق من صحة الـ Backup
  static const Set<String> expectedColumns = {
    'id',
    'entry_type',
    'adType',
    'deedType',
    'propertyType',
    'province',
    'region',
    'addressDetails',
    'floor',
    'rooms',
    'area',
    'hasGarden',
    'isDuplex',
    'facade',
    'directions',
    'finishingLevel',
    'features',
    'ownershipType',
    'ownershipDetails',
    'sharesCount',
    'price',
    'currency',
    'status',
    'ownerName',
    'ownerWhatsapp',
    'officeName',
    'contactPhone',
    'facebookLink',
    'notes',
    'images',
    'videos',
    'ownerStatus',
    'created_at',
    'updated_at',
  };

  /// الأعمدة الخفيفة المطلوبة لعرض البطاقات فقط
  /// تقلل استهلاك الذاكرة بنسبة ~40% مقارنة بجلب كل الأعمدة
  static const List<String> _liteColumns = [
    'id',
    'entry_type',
    'propertyType',
    'adType',
    'province',
    'region',
    'rooms',
    'area',
    'price',
    'currency',
    'status',
    'images',
  ];

  // ═══════════════════════════════════════════════════════════
  //  Singleton
  // ═══════════════════════════════════════════════════════════
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDB();
    _database = await _initFuture;
    return _database!;
  }

  // ═══════════════════════════════════════════════════════════
  //  Initialization
  // ═══════════════════════════════════════════════════════════

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbFilename);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    await db.rawQuery('PRAGMA journal_mode=WAL');
    await db.rawQuery('PRAGMA foreign_keys=ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableProperties (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_type      TEXT NOT NULL DEFAULT 'offer',
        adType          TEXT NOT NULL DEFAULT '',
        deedType        TEXT NOT NULL DEFAULT '',
        propertyType    TEXT NOT NULL DEFAULT '',
        province        TEXT NOT NULL DEFAULT '',
        region          TEXT NOT NULL DEFAULT '',
        addressDetails  TEXT NOT NULL DEFAULT '',
        floor           TEXT NOT NULL DEFAULT '',
        rooms           INTEGER NOT NULL DEFAULT 0,
        area            REAL NOT NULL DEFAULT 0,
        hasGarden       INTEGER NOT NULL DEFAULT 0,
        isDuplex        INTEGER NOT NULL DEFAULT 0,
        facade          TEXT NOT NULL DEFAULT '',
        directions      TEXT NOT NULL DEFAULT '[]',
        finishingLevel  TEXT NOT NULL DEFAULT '',
        features        TEXT NOT NULL DEFAULT '[]',
        ownershipType   TEXT NOT NULL DEFAULT '',
        ownershipDetails TEXT NOT NULL DEFAULT '',
        sharesCount     INTEGER,
        price           REAL NOT NULL DEFAULT 0,
        currency        TEXT NOT NULL DEFAULT '',
        status          TEXT NOT NULL DEFAULT '',
        ownerName       TEXT NOT NULL DEFAULT '',
        ownerWhatsapp   TEXT NOT NULL DEFAULT '',
        officeName      TEXT NOT NULL DEFAULT '',
        contactPhone    TEXT NOT NULL DEFAULT '',
        facebookLink    TEXT NOT NULL DEFAULT '',
        notes           TEXT NOT NULL DEFAULT '',
        images          TEXT NOT NULL DEFAULT '[]',
        videos          TEXT NOT NULL DEFAULT '[]',
        ownerStatus     TEXT NOT NULL DEFAULT '',
        created_at      TEXT,
        updated_at      TEXT
      )
    ''');

    // ════════════════════════════════════════════════════════
    //  Indexes — eliminate full-table scans on filtered queries
    // ════════════════════════════════════════════════════════
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entry_type ON $tableProperties(entry_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_province ON $tableProperties(province)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_property_type ON $tableProperties(propertyType)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_status ON $tableProperties(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ad_type ON $tableProperties(adType)',
    );
    // Composite index for the most common filter combo
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entry_province_type ON $tableProperties(entry_type, province, propertyType)',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  Migrations
  // ═══════════════════════════════════════════════════════════

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _migrateV1toV2(db);
    if (oldVersion < 3) await _migrateV2toV3(db);
    if (oldVersion < 4) await _migrateV3toV4(db);
  }

  Future<void> _migrateV1toV2(Database db) async {
    await db.transaction((txn) async {
      await txn.execute(
        "ALTER TABLE $tableProperties ADD COLUMN entry_type TEXT NOT NULL DEFAULT 'offer'",
      );
    });
  }

  Future<void> _migrateV2toV3(Database db) async {
    await db.transaction((txn) async {
      await txn.execute(
        'ALTER TABLE $tableProperties ADD COLUMN created_at TEXT',
      );
      await txn.execute(
        'ALTER TABLE $tableProperties ADD COLUMN updated_at TEXT',
      );
      final now = DateTime.now().toIso8601String();
      await txn.update(
        tableProperties,
        {'created_at': now, 'updated_at': now},
      );
    });
  }

  /// v3 → v4 : Add performance indexes
  Future<void> _migrateV3toV4(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entry_type ON $tableProperties(entry_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_province ON $tableProperties(province)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_property_type ON $tableProperties(propertyType)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_status ON $tableProperties(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ad_type ON $tableProperties(adType)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entry_province_type ON $tableProperties(entry_type, province, propertyType)',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CRUD
  // ═══════════════════════════════════════════════════════════

  Future<int> insertProperty(PropertyModel property) async {
    final db = await instance.database;
    final map = property.toMap();
    final now = DateTime.now().toIso8601String();
    map['created_at'] = now;
    map['updated_at'] = now;
    try {
      return await db.transaction((txn) => txn.insert(tableProperties, map));
    } catch (e) {
      throw Exception('فشل إضافة العقار: $e');
    }
  }

  Future<int> updateProperty(PropertyModel property) async {
    final db = await instance.database;
    final map = property.toMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    map.remove('created_at');
    try {
      return await db.transaction((txn) => txn.update(
            tableProperties,
            map,
            where: 'id = ?',
            whereArgs: [property.id],
          ));
    } catch (e) {
      throw Exception('فشل تحديث العقار: $e');
    }
  }

  Future<int> deleteProperty(int id) async {
    final db = await instance.database;
    try {
      return await db.transaction((txn) => txn.delete(
            tableProperties,
            where: 'id = ?',
            whereArgs: [id],
          ));
    } catch (e) {
      throw Exception('فشل حذف العقار: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Optimized Queries — SQL-level filtering + pagination
  // ═══════════════════════════════════════════════════════════

  /// جلب كل العقارات (للتحميل الأولي)
  Future<List<PropertyModel>> getAllProperties() async {
    final db = await instance.database;
    try {
      final result = await db.query(tableProperties, orderBy: 'id DESC');
      return result.map((json) => PropertyModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('فشل تحميل العقارات: $e');
    }
  }

  /// جلب خفيف — أعمدة البطاقة فقط (~40% أقل ذاكرة)
  Future<List<PropertyModel>> getPropertiesLite({
    int? limit,
    int? offset,
  }) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        tableProperties,
        columns: _liteColumns,
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );
      return result.map((json) => PropertyModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('فشل تحميل العقارات: $e');
    }
  }

  /// جلب مع فلترة على مستوى SQL — يحل مشكلة O(n × 19) في Dart
  /// يبني جملة WHERE ديناميكياً بناءً على المعايير المطلوبة فقط
  Future<List<PropertyModel>> getPropertiesFiltered({
    String? entryType,
    String? query,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
    String? province,
    String? adType,
    String? status,
    String? finishingLevel,
    String? facade,
    String? deedType,
    int? minRooms,
    int? maxRooms,
    double? minArea,
    double? maxArea,
    String? floor,
    bool? hasGarden,
    bool? isDuplex,
    String? currency,
    String? ownershipType,
    String? ownerStatus,
    int? limit,
    int? offset,
  }) async {
    final db = await instance.database;
    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (entryType != null) {
        whereClauses.add('entry_type = ?');
        whereArgs.add(entryType);
      }
      if (propertyType != null && propertyType.isNotEmpty) {
        whereClauses.add('propertyType = ?');
        whereArgs.add(propertyType);
      }
      if (province != null && province.isNotEmpty) {
        whereClauses.add('province = ?');
        whereArgs.add(province);
      }
      if (adType != null && adType.isNotEmpty) {
        whereClauses.add('adType = ?');
        whereArgs.add(adType);
      }
      if (status != null && status.isNotEmpty) {
        whereClauses.add('status = ?');
        whereArgs.add(status);
      }
      if (minPrice != null) {
        whereClauses.add('price >= ?');
        whereArgs.add(minPrice);
      }
      if (maxPrice != null) {
        whereClauses.add('price <= ?');
        whereArgs.add(maxPrice);
      }
      if (minRooms != null) {
        whereClauses.add('rooms >= ?');
        whereArgs.add(minRooms);
      }
      if (maxRooms != null) {
        whereClauses.add('rooms <= ?');
        whereArgs.add(maxRooms);
      }
      if (minArea != null) {
        whereClauses.add('area >= ?');
        whereArgs.add(minArea);
      }
      if (maxArea != null) {
        whereClauses.add('area <= ?');
        whereArgs.add(maxArea);
      }
      if (hasGarden != null) {
        whereClauses.add('hasGarden = ?');
        whereArgs.add(hasGarden ? 1 : 0);
      }
      if (isDuplex != null) {
        whereClauses.add('isDuplex = ?');
        whereArgs.add(isDuplex ? 1 : 0);
      }
      if (currency != null && currency.isNotEmpty) {
        whereClauses.add('currency = ?');
        whereArgs.add(currency);
      }
      if (ownershipType != null && ownershipType.isNotEmpty) {
        whereClauses.add('ownershipType = ?');
        whereArgs.add(ownershipType);
      }
      if (finishingLevel != null && finishingLevel.isNotEmpty) {
        whereClauses.add('finishingLevel = ?');
        whereArgs.add(finishingLevel);
      }
      if (facade != null && facade.isNotEmpty) {
        whereClauses.add('facade = ?');
        whereArgs.add(facade);
      }
      if (deedType != null && deedType.isNotEmpty) {
        whereClauses.add('deedType = ?');
        whereArgs.add(deedType);
      }
      if (floor != null && floor.isNotEmpty) {
        whereClauses.add('LOWER(floor) LIKE ?');
        whereArgs.add('%${floor.toLowerCase()}%');
      }
      if (ownerStatus != null && ownerStatus.isNotEmpty) {
        whereClauses.add('ownerStatus = ?');
        whereArgs.add(ownerStatus);
      }

      // البحث النص — يعمل على عدة أعمدة
      if (query != null && query.isNotEmpty) {
        final likePattern = '%${query.toLowerCase()}%';
        whereClauses.add(
          '(LOWER(region) LIKE ? OR LOWER(propertyType) LIKE ? '
          'OR LOWER(province) LIKE ? OR LOWER(addressDetails) LIKE ? '
          'OR LOWER(ownerName) LIKE ? OR LOWER(officeName) LIKE ?)',
        );
        whereArgs.addAll([
          likePattern,
          likePattern,
          likePattern,
          likePattern,
          likePattern,
          likePattern,
        ]);
      }

      final whereClause =
          whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

      final result = await db.query(
        tableProperties,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );

      return result.map((json) => PropertyModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('فشل تحميل العقارات: $e');
    }
  }

  /// عدد العقارات مع فلترة SQL — للـ pagination
  Future<int> getFilteredCount({
    String? entryType,
    String? query,
    double? minPrice,
    double? maxPrice,
    String? propertyType,
    String? province,
    String? adType,
    String? status,
    String? finishingLevel,
    String? facade,
    String? deedType,
    int? minRooms,
    int? maxRooms,
    double? minArea,
    double? maxArea,
    String? floor,
    bool? hasGarden,
    bool? isDuplex,
    String? currency,
    String? ownershipType,
    String? ownerStatus,
  }) async {
    final db = await instance.database;
    try {
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (entryType != null) {
        whereClauses.add('entry_type = ?');
        whereArgs.add(entryType);
      }
      if (propertyType != null && propertyType.isNotEmpty) {
        whereClauses.add('propertyType = ?');
        whereArgs.add(propertyType);
      }
      if (province != null && province.isNotEmpty) {
        whereClauses.add('province = ?');
        whereArgs.add(province);
      }
      if (adType != null && adType.isNotEmpty) {
        whereClauses.add('adType = ?');
        whereArgs.add(adType);
      }
      if (status != null && status.isNotEmpty) {
        whereClauses.add('status = ?');
        whereArgs.add(status);
      }
      if (minPrice != null) {
        whereClauses.add('price >= ?');
        whereArgs.add(minPrice);
      }
      if (maxPrice != null) {
        whereClauses.add('price <= ?');
        whereArgs.add(maxPrice);
      }
      if (minRooms != null) {
        whereClauses.add('rooms >= ?');
        whereArgs.add(minRooms);
      }
      if (maxRooms != null) {
        whereClauses.add('rooms <= ?');
        whereArgs.add(maxRooms);
      }
      if (minArea != null) {
        whereClauses.add('area >= ?');
        whereArgs.add(minArea);
      }
      if (maxArea != null) {
        whereClauses.add('area <= ?');
        whereArgs.add(maxArea);
      }
      if (hasGarden != null) {
        whereClauses.add('hasGarden = ?');
        whereArgs.add(hasGarden ? 1 : 0);
      }
      if (isDuplex != null) {
        whereClauses.add('isDuplex = ?');
        whereArgs.add(isDuplex ? 1 : 0);
      }
      if (currency != null && currency.isNotEmpty) {
        whereClauses.add('currency = ?');
        whereArgs.add(currency);
      }
      if (ownershipType != null && ownershipType.isNotEmpty) {
        whereClauses.add('ownershipType = ?');
        whereArgs.add(ownershipType);
      }
      if (finishingLevel != null && finishingLevel.isNotEmpty) {
        whereClauses.add('finishingLevel = ?');
        whereArgs.add(finishingLevel);
      }
      if (facade != null && facade.isNotEmpty) {
        whereClauses.add('facade = ?');
        whereArgs.add(facade);
      }
      if (deedType != null && deedType.isNotEmpty) {
        whereClauses.add('deedType = ?');
        whereArgs.add(deedType);
      }
      if (floor != null && floor.isNotEmpty) {
        whereClauses.add('LOWER(floor) LIKE ?');
        whereArgs.add('%${floor.toLowerCase()}%');
      }
      if (ownerStatus != null && ownerStatus.isNotEmpty) {
        whereClauses.add('ownerStatus = ?');
        whereArgs.add(ownerStatus);
      }
      if (query != null && query.isNotEmpty) {
        final likePattern = '%${query.toLowerCase()}%';
        whereClauses.add(
          '(LOWER(region) LIKE ? OR LOWER(propertyType) LIKE ? '
          'OR LOWER(province) LIKE ? OR LOWER(addressDetails) LIKE ? '
          'OR LOWER(ownerName) LIKE ? OR LOWER(officeName) LIKE ?)',
        );
        whereArgs.addAll([
          likePattern,
          likePattern,
          likePattern,
          likePattern,
          likePattern,
          likePattern,
        ]);
      }

      final whereClause =
          whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $tableProperties'
          '${whereClause != null ? ' WHERE $whereClause' : ''}',
          whereArgs.isNotEmpty ? whereArgs : null,
        ),
      );
      return count ?? 0;
    } catch (e) {
      throw Exception('فشل حساب عدد العقارات: $e');
    }
  }

  Future<int> getPropertiesCount() async {
    final db = await instance.database;
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableProperties'),
      );
      return count ?? 0;
    } catch (e) {
      throw Exception('فشل حساب عدد العقارات: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Utilities
  // ═══════════════════════════════════════════════════════════

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbFilename);
  }

  Future<void> closeDatabase() async {
    _initFuture = null;
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<bool> isValidDatabase(String path) async {
    Database? tempDb;
    try {
      tempDb = await openReadOnlyDatabase(path);

      final tables = await tempDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableProperties'",
      );
      if (tables.isEmpty) return false;

      final columns =
          await tempDb.rawQuery('PRAGMA table_info($tableProperties)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      for (final col in expectedColumns) {
        if (!columnNames.contains(col)) return false;
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      await tempDb?.close();
    }
  }
}
