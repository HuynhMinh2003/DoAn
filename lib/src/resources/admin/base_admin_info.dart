import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class BaseAdminInfo<T extends StatefulWidget> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User _admin;
  Admin? adminInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getAdminInfo();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message),),
    );
  }

  Future<void> getAdminInfo([String? adminId]) async {
    try {
      setState(() {
        isLoading = true;
      });

      _admin = _auth.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId ?? _admin.uid)
          .get();

      if (doc.exists) {
        setState(() {
          adminInfo = Admin.fromFirestore(doc);
        });
      } else {
        showSnackBar('Không tìm thấy thông tin quản lý.');
      }
    } catch (e) {
      showSnackBar('Không thể tải thông tin người dùng.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context);
}
