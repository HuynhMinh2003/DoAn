import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceUpdateListPage extends StatelessWidget {
  final String companyId;

  const ServiceUpdateListPage({super.key, required this.companyId});

  void openFileLink(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết')),
      );
    }
  }

  void showDetailDialog(BuildContext context, Map<String, dynamic> data, String type, String description) {
    final String price = data['price'] ?? '';
    final String fileLink = data['fileLink'] ?? '';
    final String status = data['status'] ?? '';
    final Timestamp? timestamp = data['timestamp'];

    String dateString;
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      dateString = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else {
      dateString = 'Không xác định';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Text(
            type,
            style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold, fontFamily: "Oswald"),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mô tả: $description', style: TextStyle(fontSize: 15.sp)),
            SizedBox(height: 20.h),
            Text('Giá: $price', style: TextStyle(fontSize: 15.sp)),
            SizedBox(height: 20.h),
            Text('Trạng thái: $status', style: TextStyle(fontSize: 15.sp)),
            SizedBox(height: 20.h),
            Text('Ngày cập nhật: $dateString', style: TextStyle(fontSize: 15.sp)),
            if (fileLink.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Chi tiết dịch vụ", style: TextStyle(fontSize: 15.sp)),
                  TextButton(
                    onPressed: () => openFileLink(context, fileLink),
                    child: Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15.sp,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
          ],
        ),
        actions: [
          Builder(
            builder: (dialogContext) => ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Đóng', style: TextStyle(fontSize: 15.sp)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyDocRef =
    FirebaseFirestore.instance.collection('companies').doc(companyId);
    final updateServiceRef = companyDocRef
        .collection('updateService')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trạng thái chờ duyệt',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: companyDocRef.get(),
        builder: (context, companySnapshot) {
          if (companySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!companySnapshot.hasData || !companySnapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin công ty'));
          }

          final companyData = companySnapshot.data!.data() as Map<String, dynamic>;
          final String type = companyData['type'] ?? 'Chưa có tên';
          final String description = companyData['description'] ?? 'Chưa có mô tả';

          return StreamBuilder<QuerySnapshot>(
            stream: updateServiceRef.snapshots(),
            builder: (context, updateSnapshot) {
              if (updateSnapshot.hasError) {
                return Center(child: Text('Lỗi: ${updateSnapshot.error}'));
              }
              if (updateSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!updateSnapshot.hasData || updateSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Chưa có bản cập nhật nào'));
              }

              final docs = updateSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data()! as Map<String, dynamic>;

                  final String imageUrl = data['imageServiceUrl'] ?? '';
                  final String status = data['status'] ?? '';
                  final Timestamp? timestamp = data['timestamp'];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showDetailDialog(context, data, type, description),
                        child: Row(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: imageUrl.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                                color: Colors.grey[300],
                              ),
                              child: imageUrl.isEmpty
                                  ? const Center(child: Icon(Icons.image_not_supported))
                                  : null,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10, top: 12, bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Dòng 1: Type (tên dịch vụ)
                                    Text(
                                      type,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                      ),
                                    ),

                                    SizedBox(height: 8.h),

                                    /// Dòng 2: Ngày cập nhật
                                    Text(
                                      'Ngày cập nhật: ${timestamp != null ? DateFormat('dd/MM/yyyy – HH:mm').format(timestamp.toDate()) : 'Không rõ'}',
                                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                                    ),

                                    SizedBox(height: 10.h),
                                    /// Dòng cuối: trạng thái (status) nằm góc phải
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: status == 'Đã duyệt'
                                              ? Colors.green[100]
                                              : status == 'Từ chối duyệt'
                                              ? Colors.red[100]
                                              : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: status == 'Đã duyệt'
                                                ? Colors.green[800]
                                                : status == 'Từ chối duyệt'
                                                ? Colors.red[800]
                                                : Colors.orange[800],
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
