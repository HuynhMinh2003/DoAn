import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:do_an/src/models/staffs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

abstract class BaseResidentInfoScreen<T extends StatefulWidget> extends State<T> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User _resident;
  ResidentInfo? residentInfo;
  bool isLoading = false;
  String? apartmentName;
  String? building;
  var area;

  @override
  void initState() {
    super.initState();
    getResidentInfo();  // Không cần truyền tham số, mặc định lấy theo UID hiện tại
  }

  // Lấy thông tin nhân viên từ Firestore và parse thành đối tượng Staff
  Future<void> getResidentInfo([String? residentId]) async {
    try {
      setState(() {
        isLoading = true;
      });

      _resident = _auth.currentUser!;
      final doc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(residentId ?? _resident.uid)
          .get();

      if (doc.exists) {
        setState(() {
          residentInfo = ResidentInfo.fromFirestore(doc);
        });

        // Sau khi residentInfo đã được set, gọi lấy apartmentName
        await fetchApartmentName();

      } else {
        print('❌ Không tìm thấy thông tin cư dân.');
        showSnackBar('Không tìm thấy thông tin cư dân.');
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

  Future<void> fetchApartmentName() async {
    if (residentInfo?.apartmentId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('apartments')
          .doc(residentInfo!.apartmentId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          apartmentName = data?['apartmentName'] ?? 'Không rõ';
          building = data?['building'] ?? 'Không rõ';
          area = data?['area'] as int? ?? 0;

          // Gán contractId cho residentInfo từ field currentContractId
          residentInfo = residentInfo!.copyWith(
            contractId: data?['currentContractId'],
          );
        });
      }
    }
  }


  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,style: TextStyle(fontSize: 15.sp),),
        backgroundColor: Colors.green,  // Màu nền xanh
      ),
    );
  }


  @override
  Widget build(BuildContext context);
}
