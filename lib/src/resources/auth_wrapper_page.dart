import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_first_resident_page.dart';
import 'home_first_ktv_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<int?> _getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final firestore = FirebaseFirestore.instance;

    // Tìm trong staff collection
    final staffDoc = await firestore.collection('staffs').doc(uid).get();
    if (staffDoc.exists) {
      final role = staffDoc.data()?['role'];
      if (role != null) return role;
    }

    // Tìm trong resident collection
    final residentDoc = await firestore.collection('residents').doc(uid).get();
    if (residentDoc.exists) {
      final role = residentDoc.data()?['role'];
      if (role != null) return role;
    }

    // Tìm trong companies collection
    final companyDoc = await firestore.collection('companies').doc(uid).get();
    if (companyDoc.exists) {
      final role = companyDoc.data()?['role'];
      if (role != null) return role;
    }

    // Nếu không tìm thấy role thì trả null
    return null;
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

        if (role == 2 || role == 3) {
          return HomeFirstKTVPage();
        } else if (role == 4) {
          return HomeFirstResidentPage();
        } else if (role == 5) {
          return HomeFirstResidentPage();
        } else {
          // Không xác định được role, logout
          FirebaseAuth.instance.signOut();
          return LoginPage();
        }
      },
    );
  }
}
