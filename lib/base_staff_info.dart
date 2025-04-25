import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class BaseStaffInfoScreen<T extends StatefulWidget> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User _staff;
  Map<String, dynamic>? staffInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getStaffInfo();  // Lúc này sẽ không truyền tham số vào nữa, để cho phép ghi đè phương thức này.
  }

  // Lấy thông tin nhân viên từ Firestore (không có tham số nữa)
  Future<void> getStaffInfo([String? staffId]) async {
    try {
      setState(() {
        isLoading = true;
      });

      _staff = _auth.currentUser!;

      // Nếu staffId được truyền vào, sử dụng nó để lấy thông tin, nếu không sẽ lấy thông tin từ UID của người dùng hiện tại
      final doc = await FirebaseFirestore.instance.collection('staffs').doc(staffId ?? _staff.uid).get();

      if (doc.exists) {
        setState(() {
          staffInfo = doc.data()!;
        });
      } else {
        print('❌ Không tìm thấy thông tin nhân viên.');
        showSnackBar('Không tìm thấy thông tin nhân viên.');
      }
    } catch (e) {
      print('⚠️ Lỗi khi lấy thông tin người dùng: $e');
      showSnackBar('Không thể tải thông tin người dùng.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context);
}
