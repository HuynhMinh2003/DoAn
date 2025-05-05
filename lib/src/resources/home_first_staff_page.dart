import 'package:do_an/base_staff_info.dart';
import 'package:do_an/src/resources/staff_page_1.dart';
import 'package:do_an/src/resources/test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeFirstStaffPage extends StatelessWidget {
  const HomeFirstStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00F5DD),
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

class _HomeFirstPageState extends BaseStaffInfoScreen<HomeFirstPage> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (staffInfo == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
    );
    }

    final List<Widget> tabs = [
    // const HomePage(),
      StaffPage(),
      TestPage(),
    ];

    return Scaffold(
    body: CupertinoTabScaffold(
    tabBar: CupertinoTabBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        activeColor: Colors.white,
        items: const [
           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Trang chủ'),
           BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
      ],
    ),
    tabBuilder: (BuildContext context, int index) {
    return tabs[index];
    },
    ),
    );
  }
}
