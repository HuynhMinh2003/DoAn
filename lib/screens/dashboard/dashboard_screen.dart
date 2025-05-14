import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants.dart';
import '../../responsive.dart';
import 'components/header.dart';
import 'components/my_fields.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';

class DashboardScreen extends StatelessWidget {
  Future<Map<String, int>> fetchRoomDataFromFirebase() async {
    try {
      // Truy cập collection `apartments` từ Firestore
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('apartments').get();

      int rented = 0;
      int sold = 0;
      int available = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool isRent = data['isRent'] ?? false;
        bool isSale = data['isSale'] ?? false;

        if (isRent) {
          rented++;
        } else if (isSale) {
          sold++;
        } else {
          available++;
        }
      }

      return {'rented': rented, 'sold': sold, 'available': available};
    } catch (e) {
      print("Error fetching data: $e");
      throw e; // Ném lỗi để xử lý trong FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            // Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      MyFiles(),
                      SizedBox(height: defaultPadding),
                      RecentFiles(),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                        FutureBuilder<Map<String, int>>(
                          future: fetchRoomDataFromFirebase(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            } else if (snapshot.hasData) {
                              final data = snapshot.data!;
                              return StorageDetails(
                                rentedRooms: data['rented'] ?? 0,
                                soldRooms: data['sold'] ?? 0,
                                availableRooms: data['available'] ?? 0,
                              );
                            } else {
                              return const Center(
                                child: Text("No data available"),
                              );
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
                    child: FutureBuilder<Map<String, int>>(
                      future: fetchRoomDataFromFirebase(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        } else if (snapshot.hasData) {
                          final data = snapshot.data!;
                          return StorageDetails(
                            rentedRooms: data['rented'] ?? 0,
                            soldRooms: data['sold'] ?? 0,
                            availableRooms: data['available'] ?? 0,
                          );
                        } else {
                          return const Center(
                            child: Text("No data available"),
                          );
                        }
                      },
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