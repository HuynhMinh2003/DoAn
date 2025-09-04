import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/staff/base_staff_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../notification/notification_list_csn_page.dart';
import 'csn_info_page.dart';
import 'csn_page.dart';

class HomeFirstCSNPage extends StatelessWidget {
  const HomeFirstCSNPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.teal,
          onPrimary: Colors.white,
          secondary: Colors.grey,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          background: Colors.white,
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
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

class _HomeFirstPageState extends BaseStaffInfoScreen<HomeFirstPage> with WidgetsBindingObserver{
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  int _selectedIndex = 0;
  int _notificationCount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getNotificationCount();
    syncEmailWithFirestore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  void minimizeApp() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.HOME',
      );
      intent.launch();
    }
  }

  void _getNotificationCount() {
    if (userId == null) return;

    FirebaseFirestore.instance.collection("information_staffs").snapshots().listen((snapshot) {
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

    var notifications = await FirebaseFirestore.instance.collection("information_staffs").get();
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

    var updatedNotifications = await FirebaseFirestore.instance.collection("information_staffs").get();

    int newCount = updatedNotifications.docs.where((doc) {
      List seenBy = doc["seenBy"] ?? [];
      return !seenBy.contains(userId);
    }).length;

    setState(() {
      _notificationCount = newCount;
    });
  }

  Future<void> syncEmailWithFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await user.reload();

    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) return;

    final currentEmail = refreshedUser.email;

    if (currentEmail == null) return;

    final docSnapshot = await _firestore.collection('staffs').doc(uid).get();
    if (!docSnapshot.exists) return;

    final firestoreEmail = docSnapshot.get('email');

    if (firestoreEmail != currentEmail) {
      await _firestore.collection('staffs').doc(uid).update({'email': currentEmail});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email đã được cập nhật thành công.',style: TextStyle(fontSize: 15.sp),),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (staffInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> tabs = [
      CSNPage(),
      NotificationListCSNPage(),
      CSNInfoPage(),
    ];

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
          minimizeApp();
        },
        child: Scaffold(
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
    ));
  }
}
