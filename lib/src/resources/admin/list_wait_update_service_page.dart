import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ListWaitUpdateServicePage extends StatefulWidget {
  const ListWaitUpdateServicePage({super.key});

  @override
  State<ListWaitUpdateServicePage> createState() => _ListWaitUpdateServicePageState();
}

class _ListWaitUpdateServicePageState extends State<ListWaitUpdateServicePage> {
  List<Map<String, dynamic>> _pendingServiceRequests = [];

  @override
  void initState() {
    super.initState();
    _loadServicesWithCompanyInfo();
  }

  Future<void> _loadServicesWithCompanyInfo() async {
    try {
      final companiesSnapshot = await FirebaseFirestore.instance.collection('companies').get();

      List<Map<String, dynamic>> allServices = [];

      for (var companyDoc in companiesSnapshot.docs) {
        final companyId = companyDoc.id;
        final companyData = companyDoc.data();

        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('updateService')
            .get();

        for (var serviceDoc in servicesSnapshot.docs) {
          final serviceData = serviceDoc.data();
          if (serviceData['status'] == 'Đang chờ duyệt') {
            allServices.add({
              'id': serviceDoc.id,
              ...serviceData,
              'companyId': companyId,
              'companyName': companyData['name'] ?? '',
              'companyType': companyData['type'] ?? '',
              'companyDescription': companyData['description'] ?? '',
            });
          }
        }
      }

      setState(() {
        _pendingServiceRequests = allServices;
      });
    } catch (e) {
      print("Lỗi khi load services hoặc companies: $e");
    }
  }

  Future<void> _approveService(String companyId, String serviceId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('updateService')
        .doc(serviceId)
        .update({'status': 'Đã duyệt'});

    // Lấy fcmTokens
    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    final data = companyDoc.data();
    final List<dynamic>? fcmTokens = data?['fcmTokens'];
    final String? type = data?['type'];

    if (fcmTokens != null && fcmTokens.isNotEmpty) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('sendNotificationToOne');
        await callable.call({
          'fcmTokens': fcmTokens,
          'title': "Yêu cầu cập nhật dịch vụ",
          'body': "Đã được duyệt: $type.",
        });
      } catch (e) {
        print("❌ Gửi thông báo lỗi: $e");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt"),backgroundColor: Colors.green,));
    _loadServicesWithCompanyInfo();
  }

  Future<void> _rejectService(String companyId, String serviceId) async {
    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('updateService')
        .doc(serviceId)
        .update({'status': 'Từ chối duyệt'});

    // Lấy fcmTokens
    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    final data = companyDoc.data();
    final List<dynamic>? fcmTokens = data?['fcmTokens'];
    final String? type = data?['type'];

    if (fcmTokens != null && fcmTokens.isNotEmpty) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('sendNotificationToOne');
        await callable.call({
          'fcmTokens': fcmTokens,
          'title': "Yêu cầu cập nhật dịch vụ",
          'body': "Từ chối duyệt: $type.",
        });
      } catch (e) {
        print("❌ Gửi thông báo lỗi: $e");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã từ chối duyệt"),backgroundColor: Colors.red));
    _loadServicesWithCompanyInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                "Cập nhật thông tin dịch vụ ngoài",
                style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.w700,
                  fontSize: 7.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Expanded( // 👈 Cái này sẽ chiếm phần còn lại
                child: _pendingServiceRequests.isEmpty
                    ? Center(
                  child: Text(
                    'Không có yêu cầu nào cần xử lý',
                    style: TextStyle(fontSize: 4.sp),
                  ),
                )
                    : ListView.builder(
                  itemCount: _pendingServiceRequests.length,
                  itemBuilder: (context, index) {
                    final service = _pendingServiceRequests[index];
                    return _buildServiceCard(service);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service['imageServiceUrl'] != null &&
                service['imageServiceUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  service['imageServiceUrl'],
                  width: 60.w,
                  height: 200.h,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 120.w,
                height: 120.h,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 40),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Công ty: ${service['companyName']}", style: TextStyle(fontSize: 4.sp)),
                  Text("Loại hình: ${service['companyType']}", style: TextStyle(fontSize: 4.sp)),
                  Text("Giới thiệu: ${service['companyDescription']}", style: TextStyle(fontSize: 4.sp)),
                  Text("Giá: ${service['price']}", style: TextStyle(fontSize: 4.sp)),
                  Text("Trạng thái: ${service['status']}", style: TextStyle(fontSize: 4.sp)),
                  if (service['timestamp'] != null)
                    Text(
                      "Gửi lúc: ${DateFormat('dd/MM/yyyy HH:mm').format((service['timestamp'] as Timestamp).toDate())}",
                      style: TextStyle(fontSize: 4.sp),
                    ),
                  if (service['fileLink'] != null && service['fileLink'].toString().isNotEmpty)
                    Row(
                      children: [
                        Text('Thông tin chi tiết: ', style: TextStyle(fontSize: 4.sp)),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(service['fileLink'])),
                          child: Text(
                            'Xem tài liệu đính kèm',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 4.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            _approveService(service['companyId'], service['id']),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text("Phê duyệt", style: TextStyle(fontSize: 4.sp)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      SizedBox(width: 10.w),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _rejectService(service['companyId'], service['id']),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: Text("Từ chối", style: TextStyle(fontSize: 4.sp)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
