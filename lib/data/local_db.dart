import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Simple local SQLite database for storing the service provider profile
/// and current orders. Not used for customer onboarding for now.
class LocalDb {
  LocalDb._internal();

  static final LocalDb instance = LocalDb._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'local_sure.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE service_provider_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            mobile TEXT NOT NULL,
            service_category TEXT NOT NULL,
            years_experience INTEGER NOT NULL,
            photo TEXT,
            location TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE customer_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            location TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  // --- Service Provider Profile ---

  Future<Map<String, Object?>?> getServiceProviderProfile() async {
    final db = await database;
    final result = await db.query(
      'service_provider_profile',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> upsertServiceProviderProfile({
    required String fullName,
    required String mobile,
    required String serviceCategory,
    required int yearsExperience,
    String? photo,
    String? location,
  }) async {
    final db = await database;

    final existing = await getServiceProviderProfile();

    if (existing == null) {
      await db.insert('service_provider_profile', {
        'full_name': fullName,
        'mobile': mobile,
        'service_category': serviceCategory,
        'years_experience': yearsExperience,
        'photo': photo,
        'location': location,
      });
    } else {
      await db.update(
        'service_provider_profile',
        {
          'full_name': fullName,
          'mobile': mobile,
          'service_category': serviceCategory,
          'years_experience': yearsExperience,
          'photo': photo,
          'location': location,
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    }
  }

  // --- Customer Profile (for future use, not in onboarding flow) ---

  Future<Map<String, Object?>?> getCustomerProfile() async {
    final db = await database;
    final result = await db.query(
      'customer_profile',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<void> upsertCustomerProfile({
    required String name,
    required String email,
    required String phone,
    String? location,
  }) async {
    final db = await database;

    final existing = await getCustomerProfile();

    if (existing == null) {
      await db.insert('customer_profile', {
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
      });
    } else {
      await db.update(
        'customer_profile',
        {
          'name': name,
          'email': email,
          'phone': phone,
          'location': location,
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    }
  }

  Future<void> clearCustomerProfile() async {
    final db = await database;
    await db.delete('customer_profile');
  }

  // --- Orders ---

  Future<List<Map<String, Object?>>> getCurrentOrders() async {
    final db = await database;
    final result = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );
    return result;
  }
}


