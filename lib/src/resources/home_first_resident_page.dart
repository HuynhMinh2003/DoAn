import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/base_resident_info.dart';
import 'package:do_an/src/resources/resident_info_page.dart';
import 'package:do_an/src/resources/resident_page_1.dart';
import 'package:do_an/src/resources/test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'notification_list_page.dart';

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

  void _getNotificationCount() {
    if (userId == null) return;

    FirebaseFirestore.instance.collection("information").snapshots().listen((snapshot) {
      int count = snapshot.docs.where((doc) {
        List seenBy = doc["seenBy"] ?? [];
        return !seenBy.contains(userId);
      }).length;

      setState(() {
        _notificationCount = count;
      });
    });
  }

  @override
  void initState(){
    super.initState();
    _getNotificationCount();
  }

  /// Đánh dấu tất cả thông báo là đã đọc khi bấm vào tab Thông báo
  void _markNotificationsAsRead() async {
    if (userId == null) return;

    var notifications = await FirebaseFirestore.instance.collection("information").get();
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
    var updatedNotifications = await FirebaseFirestore.instance.collection("information").get();
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
      NotificationListPage(),
      TestPage(),
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

            if (index == 2) {
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
