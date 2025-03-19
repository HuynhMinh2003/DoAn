import 'package:sqflite/sqflite.dart';  // Import sqflite
import 'package:path/path.dart';        // Import path
import 'dart:typed_data';               // Import dart:typed_data

// // Khởi tạo databaseFactory trước khi mở cơ sở dữ liệu
// void initDatabase() {
//   databaseFactory = databaseFactoryFfi;  // Khởi tạo databaseFactoryFfi
// }

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Gọi initDatabase() tại đây
    // initDatabase();  // Đảm bảo gọi trước khi sử dụng openDatabase

    String path = join(await getDatabasesPath(), 'user_images.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(''' 
          CREATE TABLE images (
            userId TEXT PRIMARY KEY,
            image1 BLOB,
            image2 BLOB
          )
        ''');
      },
    );
  }

  /// Lưu ảnh vào SQLite
  Future<void> insertImages(String userId, Uint8List image1, Uint8List image2) async {
    final db = await database;
    await db.insert(
      'images',
      {
        'userId': userId,
        'image1': image1,
        'image2': image2,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy ảnh theo userId
  Future<Map<String, dynamic>?> fetchImages(String userId) async {
    final db = await database;
    final result = await db.query(
      'images',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return {
        'userId': result.first['userId'],
        'image1': result.first['image1'] as Uint8List,
        'image2': result.first['image2'] as Uint8List,
      };
    }
    return null;
  }

  /// Lấy tất cả ảnh từ SQLite
  Future<List<Map<String, dynamic>>> fetchAllImages() async {
    final db = await database;
    final result = await db.query('images');
    return result.map((row) {
      return {
        'userId': row['userId'],
        'image1': row['image1'] as Uint8List,
        'image2': row['image2'] as Uint8List,
      };
    }).toList();
  }
}
