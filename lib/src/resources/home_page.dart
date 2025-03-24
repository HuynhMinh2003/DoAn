import 'package:do_an/src/resources/chang_pass_page.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/personal_info_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomePage({super.key, required this.userData});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  late User _user;
  Map<String, dynamic>? userInfo;

  Uint8List? _image;
  Database? _sqliteDb;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
      await _loadImageFromDatabase(); // Chỉ tải ảnh từ cơ sở dữ liệu
    } catch (e) {
      print('Lỗi khi khởi tạo cơ sở dữ liệu: $e');
      _showSnackBar('Lỗi cơ sở dữ liệu.');
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
    _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    void _logout() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                  );
                },
                child: const Text('Đồng ý'),
              ),
            ],
          );
        },
      );
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Trang Chính"),
          centerTitle: true,
          backgroundColor: const Color(0xff3277D8),
        ),
        drawer: Container(
          width: 250,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xff3277D8)),
                  accountName: Text(userInfo?['name'] ?? "Chưa có tên"),
                  accountEmail: Text(userInfo?['email'] ?? "Chưa có email"),
                  currentAccountPicture: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    child: _image != null
                        ? ClipOval(
                      child: Image.memory(
                        _image!,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    )
                        : const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Thêm phần thông tin cá nhân vào Drawer
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Thông tin cá nhân'),
                  onTap: () {
                    // Điều hướng đến trang thông tin cá nhân
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalInfoPage(userInfo: userInfo!),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Đổi mật khẩu'),
                  onTap: () {
                    // Điều hướng đến trang thông tin cá nhân
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                // Thêm ListTile đăng xuất
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),

        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Trang giao diện chính'),
        ),
      ),
    );
  }
}

