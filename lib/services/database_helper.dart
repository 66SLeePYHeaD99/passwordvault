
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'vault.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE passwords(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_name TEXT,
            encrypted_password TEXT
          )
          '''
        );
      },
    );
  }

  Future<void> insertPassword(String accountName, String encryptedPassword) async {
    final db = await database;
    await db.insert('passwords', {
      'account_name': accountName,
      'encrypted_password': encryptedPassword,
    });
  }

  Future<List<Map<String, dynamic>>> getPasswords() async {
    final db = await database;
    return await db.query('passwords');
  }
}
