import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/resident/base_resident_info.dart';
import 'package:do_an/src/resources/resident/resident_info_page.dart';
import 'package:do_an/src/resources/resident/resident_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../notification/notification_list_resident_page.dart';

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

class _HomeFirstPageState extends BaseResidentInfo<HomeFirstPage> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  int _selectedIndex = 0;
  int _notificationCount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState(){
    super.initState();
    _getNotificationCount();
    syncEmailWithFirestore();

  }

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

    await batch.commit();

    var updatedNotifications = await FirebaseFirestore.instance.collection("information_residents").get();

    int newCount = updatedNotifications.docs.where((doc) {
      List seenBy = doc["seenBy"] ?? [];
      return !seenBy.contains(userId);
    }).length;

    setState(() {
      _notificationCount = newCount;
    });
  }

  Future<void> syncEmailWithFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final uid = user.uid;

      await user.reload();

      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) return;

      final currentEmail = refreshedUser.email;

      if (currentEmail == null) return;

      final docSnapshot = await _firestore.collection('residents').doc(uid).get();
      if (!docSnapshot.exists) return;

      final firestoreEmail = docSnapshot.get('email');

      if (firestoreEmail != currentEmail) {
        await _firestore.collection('residents').doc(uid).update({'email': currentEmail});
        showSnackBar('Email đã được cập nhật thành công.');
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    if (residentInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> tabs = [
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
