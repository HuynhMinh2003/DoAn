import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/staffs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class BaseStaffInfoScreen<T extends StatefulWidget> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User _staff;
  Staff? staffInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getStaffInfo();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message),),
    );
  }

  Future<void> getStaffInfo([String? staffId]) async {
    try {
      setState(() {
        isLoading = true;
      });

      _staff = _auth.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('staffs')
          .doc(staffId ?? _staff.uid)
          .get();

      if (doc.exists) {
        setState(() {
          staffInfo = Staff.fromFirestore(doc);
        });
      } else {
        showSnackBar('Không tìm thấy thông tin nhân viên.');
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
