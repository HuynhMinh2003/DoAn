import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/service_request.dart';


class ResidentRequestListPage extends StatefulWidget {
  final String companyId;
  final String companyName;

  const ResidentRequestListPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<ResidentRequestListPage> createState() => _ResidentRequestListPageState();
}

class _ResidentRequestListPageState extends State<ResidentRequestListPage> {
  bool _loading = true;
  List<ServiceRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('companyId', isEqualTo: widget.companyId)
        .orderBy('createdAt', descending: true)
        .get();

    final requests = snapshot.docs
        .map((doc) => ServiceRequest.fromDoc(doc))
        .toList();

    setState(() {
      _requests = requests;
      _loading = false;
    });
  }

  Future<void> _updateStatus(String requestId, String newStatus) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('serviceRequests').doc(requestId);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();

      if (data == null) return;

      await docRef.update({'status': newStatus});
      await fetchRequests();

      final String userId = data['residentId'];
      final userSnapshot = await FirebaseFirestore.instance.collection('residents').doc(userId).get();
      final userData = userSnapshot.data();

      if (userData == null || userData['fcmTokens'] == null) {
        return;
      }

      final List<dynamic> tokens = userData['fcmTokens'];
      if (tokens.isEmpty) {
        return;
      }

      final String title = 'Yêu cầu dịch vụ đã được cập nhật';
      final String body = newStatus == 'Đã duyệt'
          ? 'Yêu cầu dịch vụ "${data['serviceName']}" của bạn đã được chấp nhận.'
          : 'Yêu cầu dịch vụ "${data['serviceName']}" của bạn đã bị từ chối.';

      await _sendNotificationToMany(title, body, tokens.cast<String>());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái thành "$newStatus"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật trạng thái'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNotificationToMany(String title, String body, List<String> tokens) async {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendNotificationToOne');
    final result = await callable.call({
      'title': title,
      'body': body,
      'tokens': tokens,
    });

    final data = result.data as Map<String, dynamic>;
    if (data['success'] == true) {
      print('Đã gửi thông báo đến ${tokens.length} thiết bị');
      if ((data['failedTokens'] as List).isNotEmpty) {
        print('Các token lỗi: ${data['failedTokens']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Danh sách đăng ký',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? Center(child: Text('Không có đăng ký nào.'))
          : ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${req.residentName} (${req.building} / Phòng ${req.apartmentNumber})',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5.h),
                  Text(
                    'Thời gian đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(req.createdAt.toDate())}',
                    style: TextStyle(fontSize: 14.sp,color: Colors.grey),
                  ),                  SizedBox(height: 10.h),
                  Text('Dịch vụ: ${req.serviceName}', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 10.h),
                  Text('Thời gian: ${req.requestTime}', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 10.h),
                  Text('SĐT: ${req.phone}', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 10.h),
                  Text('Ghi chú: ${req.note}', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 10.h),
                  Text('Trạng thái: ${req.status}', style: TextStyle(fontSize: 15.sp)),

                  if (req.status == 'Đang chờ duyệt') ...[
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          tooltip: 'Chấp nhận',
                          onPressed: () => _updateStatus(req.id, 'Đã duyệt'),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Từ chối',
                          onPressed: () => _updateStatus(req.id, 'Từ chối'),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
