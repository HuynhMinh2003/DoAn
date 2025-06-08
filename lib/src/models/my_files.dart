import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';

class CloudStorageInfo {
  final String? svgSrc;
  final int working;
  final int resigned;
  final String labelWorking;
  final String labelResigned;
  final Color? color;
  final String category;  // thêm trường này

  CloudStorageInfo({
    this.svgSrc,
    this.working = 0,
    this.resigned = 0,
    this.labelWorking = "Đang làm",
    this.labelResigned = "Đã nghỉ",
    this.color,
    required this.category,  // bắt buộc truyền
  });

  factory CloudStorageInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CloudStorageInfo(
      svgSrc: data['svgSrc'],
      working: data['working'] ?? 0,
      resigned: data['resigned'] ?? 0,
      labelWorking: data['labelWorking'] ?? "Đang làm",
      labelResigned: data['labelResigned'] ?? "Đã nghỉ",
      color: Color(int.tryParse(data['color'] ?? '') ?? 0xFF2196F3),
      category: data['category'] ?? "Không xác định",
    );
  }
}

Future<List<CloudStorageInfo>> fetchCloudStorageInfoList() async {
  final firestore = FirebaseFirestore.instance;

  // 1. Residents
  final residentsSnap = await firestore.collection('residents').get();
  final workingResidents = residentsSnap.docs.where((doc) => doc['isExit'] == false).length;
  final resignedResidents = residentsSnap.docs.where((doc) => doc['isExit'] == true).length;

  // 2. Staffs - CSN (role == 3)
  final staffsSnap = await firestore.collection('staffs').get();
  final csn = staffsSnap.docs.where((doc) => doc['role'] == 3);
  final workingCSN = csn.where((doc) => doc['isExit'] == false).length;
  final resignedCSN = csn.where((doc) => doc['isExit'] == true).length;

  // 3. Staffs - KTV (role == 2)
  final ktv = staffsSnap.docs.where((doc) => doc['role'] == 2);
  final workingKTV = ktv.where((doc) => doc['isExit'] == false).length;
  final resignedKTV = ktv.where((doc) => doc['isExit'] == true).length;

  // 4. Companies
  final companiesSnap = await firestore.collection('companies').get();
  final workingCompanies = companiesSnap.docs.where((doc) => doc['isExit'] == false).length;
  final resignedCompanies = companiesSnap.docs.where((doc) => doc['isExit'] == true).length;

  return [
    CloudStorageInfo(
      svgSrc: "assets/icons/resident.svg",
      working: workingResidents,
      resigned: resignedResidents,
      labelWorking: "Đang ở",
      labelResigned: "Đã rời đi",
      color: primaryColor,
      category: "Cư dân",
    ),
    CloudStorageInfo(
      svgSrc: "assets/icons/ktv.svg",
      working: workingKTV,
      resigned: resignedKTV,
      labelWorking: "Đang làm",
      labelResigned: "Đã nghỉ",
      color: Color(0xFFA4CDFF),
      category: "Kỹ thuật viên",
    ),
    CloudStorageInfo(
      svgSrc: "assets/icons/csn.svg",
      working: workingCSN,
      resigned: resignedCSN,
      labelWorking: "Đang làm",
      labelResigned: "Đã nghỉ",
      color: Color(0xFFFFA113),
      category: "Nhân viên ghi chỉ số nước",
    ),
    CloudStorageInfo(
      svgSrc: "assets/icons/company.svg",
      working: workingCompanies,
      resigned: resignedCompanies,
      labelWorking: "Đang hợp tác",
      labelResigned: "Đã thôi",
      color: Color(0xFF007EE5),
      category: "Công ty dịch vụ ngoài",
    ),
  ];
}
