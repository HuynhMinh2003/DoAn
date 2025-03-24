import 'dart:typed_data';

import 'package:do_an/src/resources/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart'; // Thêm thư viện intl để định dạng ngày

class PersonalInfoPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const PersonalInfoPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  late User _user;
  Map<String, dynamic>? userInfo;

  Uint8List? _image;
  final picker = ImagePicker();
  Database? _sqliteDb;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isLoading = false; // Trạng thái loading

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'user_images.db');

      _sqliteDb = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS user_images (id TEXT PRIMARY KEY, image BLOB)',
          );
        },
      );
      await _checkTableExists(); // Tùy chọn kiểm tra bảng tồn tại
      await _loadImageFromDatabase();
    } catch (e) {
      print('Lỗi khi khởi tạo cơ sở dữ liệu: $e');
      _showSnackBar('Lỗi cơ sở dữ liệu.');
    }
  }

  Future<void> _checkTableExists() async {
    try {
      final tables = await _sqliteDb!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='user_images'",
      );

      if (tables.isNotEmpty) {
        print('Bảng user_images đã tồn tại.');
      } else {
        print('Bảng user_images không tồn tại. Tạo bảng mới...');
        await _sqliteDb!.execute(
          'CREATE TABLE IF NOT EXISTS user_images (id TEXT PRIMARY KEY, image BLOB)',
        );
      }
    } catch (e) {
      print('Lỗi khi kiểm tra hoặc tạo bảng: $e');
    }
  }

  Future<void> _getUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });
      _user = _auth.currentUser!;
      DatabaseReference ref = _database.ref('users/${_user.uid}');
      DatabaseEvent event = await ref.once();

      if (event.snapshot.exists) {
        setState(() {
          userInfo = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      } else {
        print('Không có dữ liệu người dùng.');
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
      _showSnackBar('Không thể tải thông tin người dùng.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _image = bytes;
        });

        await _saveImageToDatabase();
      }
    } catch (e) {
      print('Lỗi khi chọn ảnh: $e');
      _showSnackBar('Lỗi khi chọn ảnh.');
    }
  }

  Future<void> _saveImageToDatabase() async {
    if (_image == null || _sqliteDb == null) return;

    try {
      await _sqliteDb!.insert(
        'user_images',
        {'id': _user.uid, 'image': _image},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _showSnackBar('Lưu ảnh thành công.');
    } catch (e) {
      print('Lỗi khi lưu ảnh vào SQLite: $e');
      _showSnackBar('Lỗi khi lưu ảnh.');
    }
  }

  Future<void> _loadImageFromDatabase() async {
    try {
      final result = await _sqliteDb!.query(
        'user_images',
        where: 'id = ?',
        whereArgs: [_user.uid],
      );

      if (result.isNotEmpty) {
        setState(() {
          _image = result.first['image'] as Uint8List;
        });
      }
    } catch (e) {
      print('Lỗi khi tải ảnh từ SQLite: $e');
    }
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi ngày sinh từ Firebase (chuỗi) thành DateTime
    String formattedBirthDate = _formatDate(userInfo?['birthDate']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: const Color(0xff3277D8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[200],
                    child: _image != null
                        ? ClipOval(
                      child: Image.memory(
                        _image!,
                        fit: BoxFit.cover,
                        width: 160,
                        height: 160,
                      ),
                    )
                        : const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _image == null ? 'Thêm ảnh' : 'Thay đổi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_image != null)
                    Positioned(
                      top: 10,
                      right: 110,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _image = null; // Xóa ảnh
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildInfoRow('Tên:', userInfo?['name']),
            _buildInfoRow('Số CCCD:', userInfo?['cccd']),
            _buildInfoRow('Ngày sinh:', formattedBirthDate),
            _buildInfoRow('Email:', userInfo?['email']),
            _buildInfoRow('Số điện thoại:', userInfo?['phone']),
            _buildInfoRow('Tên căn hộ:', userInfo?['nameHouse']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? 'Không có dữ liệu'),
        ],
      ),
    );
  }

  // Hàm chuyển đổi ngày sinh thành định dạng chuẩn
  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        DateTime parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsedDate);  // Định dạng ngày
      } catch (e) {
        return 'Không có dữ liệu';
      }
    }
    return 'Không có dữ liệu';
  }
}
