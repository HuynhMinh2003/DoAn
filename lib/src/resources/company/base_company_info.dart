import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/company_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class BaseCompanyInfo<T extends StatefulWidget> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User _company;
  CompanyInfo? companyInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getCompanyInfo();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> getCompanyInfo([String? companyId]) async {
    try {
      setState(() {
        isLoading = true;
      });

      _company = _auth.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId ?? _company.uid)
          .get();

      if (doc.exists) {
        setState(() {
          companyInfo = CompanyInfo.fromFirestore(doc);
        });
      } else {
        showSnackBar('Không tìm thấy thông tin công ty.');
      }
    } catch (e) {
      showSnackBar('Không thể tải thông tin công ty.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context);
}
