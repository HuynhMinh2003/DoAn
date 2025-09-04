import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/information.dart';
import 'package:do_an/src/resources/notification/notification_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class NotificationListCompanyPage extends StatefulWidget {
  const NotificationListCompanyPage({super.key});

  @override
  State<NotificationListCompanyPage> createState() => _NotificationListCompanyPageState();
}

class _NotificationListCompanyPageState extends State<NotificationListCompanyPage> {
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.white,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(width: 50, height: 50, color: Colors.grey),
              title: Container(height: 14, width: double.infinity, color: Colors.grey),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(height: 12, width: double.infinity, color: Colors.grey),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 100, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Danh sách thông báo",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("information_companies")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có thông báo nào."));
          }

          var notifications = snapshot.data!.docs
              .map((doc) => Information.fromFirestore(doc, "Công ty dịch vụ ngoài"))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final info = notifications[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailPage(notification: info),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: info.imageUrl != null
                          ? Image.network(info.imageUrl!,
                          width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.notifications, size: 50, color: Colors.grey),
                    ),
                    title: Text(
                      info.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.message,
                          style: TextStyle(fontSize: 14.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(info.timestamp),
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

