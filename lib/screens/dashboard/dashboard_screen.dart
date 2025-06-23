import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants.dart';
import '../../responsive.dart';
import 'components/header.dart';
import 'components/my_fields.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';

class DashboardScreen extends StatelessWidget {
  Future<Map<String, int>> fetchContractAndApartmentStats() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Lấy số hợp đồng còn hiệu lực
      final contractSnapshot = await firestore
          .collection('contracts')
          .where('isActive', isEqualTo: true)
          .get();
      int activeContracts = contractSnapshot.size;

      // 1. Lấy số hợp đồng còn hiệu lực
      final contractSnapshot1 = await firestore
          .collection('contracts')
          .where('isActive', isEqualTo: false)
          .get();
      int expiredContracts = contractSnapshot1.size;

      // 2. Lấy toàn bộ căn hộ
      final apartmentSnapshot = await firestore.collection('apartments').get();
      int totalApartments = apartmentSnapshot.size;

      // 3. Đếm số căn hộ đã có hợp đồng (currentContractId != null)
      int apartmentsWithContract = apartmentSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['currentContractId'] != null;
      }).length;

      // 4. Căn hộ chưa có hợp đồng = tổng - đã có
      int apartmentsWithoutContract = totalApartments - apartmentsWithContract;

      return {
        'activeContracts': activeContracts,
        'expiredContracts': expiredContracts,
        'totalApartments': totalApartments,
        'apartmentsWithContract': apartmentsWithContract,
        'apartmentsWithoutContract': apartmentsWithoutContract,
      };
    } catch (e) {
      print("Error fetching stats: $e");
      throw e;
    }
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      MyFiles(),
                      SizedBox(height: defaultPadding),
                      SizedBox(
                        height: 460.h,
                        child: RecentFiles(),
                      ),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                        FutureBuilder<Map<String, int>>(
                          future: fetchContractAndApartmentStats(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState
                                .waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text("Error: ${snapshot.error}"));
                            } else if (snapshot.hasData) {
                                final data = snapshot.data!;
                                return StorageDetails(
                                  totalApartments: data['totalApartments'] ?? 0,
                                  activeContracts: data['activeContracts']??0,
                                  expiredContracts: data['expiredContracts']??0,
                                  apartmentsWithContract: data['apartmentsWithContract'] ?? 0,
                                  apartmentsWithoutContract: data['apartmentsWithoutContract'] ?? 0,
                                );
                            } else {
                              return const Center(
                                  child: Text("No data available"));
                            }
                          },
                        ),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 725.h,
                      child: FutureBuilder<Map<String, int>>(
                        future: fetchContractAndApartmentStats(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text("Error: ${snapshot.error}"));
                          } else if (snapshot.hasData) {
                              final data = snapshot.data!;
                              return StorageDetails(
                                totalApartments: data['totalApartments'] ?? 0,
                                activeContracts: data['activeContracts']??0,
                                expiredContracts: data['expiredContracts']??0,
                                apartmentsWithContract: data['apartmentsWithContract'] ?? 0,
                                apartmentsWithoutContract: data['apartmentsWithoutContract'] ?? 0,
                              );
                          } else {
                            return const Center(
                                child: Text("No data available"));
                          }
                        },
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
