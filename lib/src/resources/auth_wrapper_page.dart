import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/screens/main/main_screen.dart';
import 'package:do_an/src/resources/home_first_company_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_first_csn_page.dart';
import 'home_first_resident_page.dart';
import 'home_first_ktv_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<int?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final firestore = FirebaseFirestore.instance;
    final collections = ['staffs', 'residents', 'companies', 'admins'];

    for (final collection in collections) {
      final doc = await firestore.collection(collection).doc(uid).get();
      if (doc.exists) {
        final role = doc.data()?['role'];
        if (role != null) return role;
      }
    }

    return null; // Không tìm thấy role
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Chưa đăng nhập, về login page
      return LoginPage();
    }

    // Đã đăng nhập, load role
    return FutureBuilder<int?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Đã có lỗi xảy ra', style: TextStyle(fontSize:15))),
          );
        }

        final role = snapshot.data;

        if (role == 1) {
          return MainScreen();
        }
        else if (role == 2) {
          return HomeFirstKTVPage();
        }
        else if (role == 3) {
          return HomeFirstCSNPage();
        } else if (role == 4) {
          return HomeFirstResidentPage();
        } else if (role == 5) {
          return HomeFirstCompanyPage();
        } else {
          // Không xác định được role, logout
          FirebaseAuth.instance.signOut();
          return LoginPage();
        }
      },
    );
  }
}
