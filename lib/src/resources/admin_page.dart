import 'package:do_an/src/resources/resident_info_page.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');
  late Future<int> _approvedResidentCount;

  @override
  void initState() {
    super.initState();
    _approvedResidentCount = _fetchApprovedResidentCount();
  }

  // Hàm lấy số lượng cư dân được phê duyệt (isApproved = true)
  Future<int> _fetchApprovedResidentCount() async {
    try {
      final event = await _databaseRef.once();
      final data = event.snapshot.value as Map?;
      if (data != null) {
        // Lọc danh sách chỉ lấy các user có isApproved = true
        final approvedResidents = data.values.where((value) {
          return (value as Map)['isApproved'] == true;
        });
        return approvedResidents.length;
      }
      return 0;
    } catch (e) {
      print('Lỗi khi lấy số lượng cư dân: $e');
      return 0;
    }
  }

  void _refreshPage() {
    setState(() {
      _approvedResidentCount = _fetchApprovedResidentCount();
    });
  }

  void _logout() {
    // Hiển thị thông báo trước khi đăng xuất
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                // Điều hướng về LoginPage và xóa các màn hình trước đó
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false, // Xóa tất cả các route trước đó
                );
              },
              child: const Text('Đồng ý'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPage, // Gọi hàm refresh khi nhấn nút
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Trang chính'),
              onTap: () {
                Navigator.pop(context); // Đóng Drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Thông tin cư dân mới'),
              onTap: () {
                Navigator.pop(context); // Đóng Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResidentInfoPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(context); // Đóng Drawer
                _logout();
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<int>(
        future: _approvedResidentCount, // Gọi dữ liệu từ biến Future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            final approvedResidentCount = snapshot.data ?? 0;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Số cư dân đã phê duyệt:',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    approvedResidentCount.toString(),
                    style: const TextStyle(fontSize: 48, color: Colors.blue),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
