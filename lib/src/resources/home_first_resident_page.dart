import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/base_resident_info.dart';
import 'package:do_an/src/resources/resident_info_page.dart';
import 'package:do_an/src/resources/home_resident_page.dart';
import 'package:do_an/src/resources/test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'notification_list_resident_page.dart';

class HomeFirstResidentPage extends StatelessWidget {
  const HomeFirstResidentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF088FC2),
        ),
        useMaterial3: true,
      ),
      home: const HomeFirstPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeFirstPage extends StatefulWidget {
  const HomeFirstPage({super.key});

  @override
  State<HomeFirstPage> createState() => _HomeFirstPageState();
}

class _HomeFirstPageState extends BaseResidentInfoScreen<HomeFirstPage> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  int _selectedIndex = 0;
  int _notificationCount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _getNotificationCount() {
    if (userId == null) return;

    FirebaseFirestore.instance.collection("information_residents").snapshots().listen((snapshot) {
      int count = snapshot.docs.where((doc) {
        List seenBy = doc["seenBy"] ?? [];
        return !seenBy.contains(userId);
      }).length;

      setState(() {
        _notificationCount = count;
      });
    });
  }
  /// Hàm gọi khi user đăng nhập lại hoặc refresh màn hình, để đồng bộ email Firebase Auth với Firestore
  Future<void> syncEmailWithFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final uid = user.uid;

      // Reload user để lấy email mới (sau khi user xác nhận qua email)
      await user.reload();

      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) return;

      // Lấy email hiện tại từ Firebase Auth
      final currentEmail = refreshedUser.email;

      if (currentEmail == null) return;

      // Lấy email trong Firestore
      final docSnapshot = await _firestore.collection('residents').doc(uid).get();
      if (!docSnapshot.exists) return;

      final firestoreEmail = docSnapshot.get('email');

      if (firestoreEmail != currentEmail) {
        // Email khác nhau, cập nhật Firestore
        await _firestore.collection('residents').doc(uid).update({'email': currentEmail});
        print('Đã đồng bộ email mới từ Firebase Auth lên Firestore');
        showSnackBar('Email đã được cập nhật thành công.');
      }
    } catch (e) {
      print('❌ Lỗi khi đồng bộ email: $e');
    }
  }
  
  @override
  void initState(){
    super.initState();
    _getNotificationCount();
    syncEmailWithFirestore();

  }

  /// Đánh dấu tất cả thông báo là đã đọc khi bấm vào tab Thông báo
  void _markNotificationsAsRead() async {
    if (userId == null) return;

    var notifications = await FirebaseFirestore.instance.collection("information_residents").get();
    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in notifications.docs) {
      List seenBy = doc["seenBy"] ?? [];
      if (!seenBy.contains(userId)) {
        batch.update(doc.reference, {
          "seenBy": [...seenBy, userId],
        });
      }
    }

    await batch.commit(); // Chờ cập nhật Firestore xong
    print("✅ Batch commit completed");

    // Kiểm tra ngay Firestore có cập nhật seenBy không
    var updatedNotifications = await FirebaseFirestore.instance.collection("information_residents").get();
    for (var doc in updatedNotifications.docs) {
      print("📌 Notification ID: ${doc.id}, seenBy: ${doc["seenBy"]}");
    }

    int newCount = updatedNotifications.docs.where((doc) {
      List seenBy = doc["seenBy"] ?? [];
      return !seenBy.contains(userId);
    }).length;

    print("🔄 Updated _notificationCount: $newCount");

    setState(() {
      _notificationCount = newCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (residentInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> tabs = [
      // const HomePage(),
      ResidentPage(),
      NotificationListResidentPage(),
      ResidentInfoPage(),
    ];

    return Scaffold(
      body: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          activeColor: Colors.white,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _notificationCount > 0,
                label: Text('$_notificationCount'),
                child: const Icon(Icons.notifications),
              ),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });

            if (index == 1) {
              _markNotificationsAsRead();
            }
          },
        ),
        tabBuilder: (BuildContext context, int index) {
          return tabs[index];
        },
      ),
    );
  }
}
