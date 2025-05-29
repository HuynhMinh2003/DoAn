import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/company_info.dart';

class CompanyDetailPage extends StatelessWidget {
  final CompanyInfo company;
  final Map<String, dynamic> updateService;

  // Thêm các tham số mới:
  final String? residentName;
  final String? apartmentNumber;
  final String? building;
  final String? phone;

  const CompanyDetailPage({
    super.key,
    required this.company,
    required this.updateService,
    this.residentName,
    this.apartmentNumber,
    this.building,
    this.phone,
  });

  Future<void> _openFile(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết')),
      );
    }
  }

  Future<void> _showBookingDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String requestTime = '';
    String note = '';

    await showDialog(
      context: context,
      builder: (dialogContext) { // sử dụng dialogContext để đóng dialog
        return AlertDialog(
          title: Center(
            child: Text(
              'Đặt dịch vụ',
              style: TextStyle(fontSize: 25.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tên cư dân: $residentName', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 8),
                  Text('Số căn hộ: $apartmentNumber', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 8),
                  Text('Số điện thoại: $phone', style: TextStyle(fontSize: 15.sp)),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Thời gian yêu cầu',
                      labelStyle: TextStyle(fontSize: 15.sp),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập thời gian';
                      }
                      return null;
                    },
                    onChanged: (value) => requestTime = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Ghi chú',
                      labelStyle: TextStyle(fontSize: 15.sp),
                    ),
                    onChanged: (value) => note = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy', style: TextStyle(fontSize: 15.sp)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: Text('Gửi yêu cầu', style: TextStyle(fontSize: 15.sp)),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final user = FirebaseAuth.instance.currentUser;
                  final residentId = user?.uid;

                  final requestData = {
                    'serviceName': company.type,
                    'companyId': company.companyId,
                    'companyName': company.name,
                    'residentId': residentId,
                    'residentName': residentName,
                    'apartmentNumber': apartmentNumber,
                    'building': building,
                    'phone': phone,
                    'requestTime': requestTime,
                    'note': note,
                    "seenBy": null,
                    'status': 'Đang chờ duyệt',
                    'createdAt': Timestamp.now(),
                  };

                  try {
                    await FirebaseFirestore.instance.collection('serviceRequests').add(requestData);

                    Navigator.of(dialogContext).pop(); // đóng dialog

                    // Gọi SnackBar sau khi dialog đóng xong
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã gửi yêu cầu dịch vụ thành công',style: TextStyle(fontSize: 15.sp, color: Colors.white),),backgroundColor: Colors.green,),
                    );

                  } catch (e) {
                    Navigator.of(dialogContext).pop(); // đóng dialog nếu có lỗi
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gửi yêu cầu dịch vụ thất bại',
                          style: TextStyle(fontSize: 15.sp, color: Colors.white
                          ),
                        ), backgroundColor: Colors.red,
                      ),
                    );

                    print('Lỗi khi gửi yêu cầu: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showServiceHistoryDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('residentId', isEqualTo: user.uid)
        .where('companyId', isEqualTo: company.companyId)
        .orderBy('createdAt', descending: true)
        .get();

    final requests = snapshot.docs;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Lịch sử đặt dịch vụ',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0), // padding 2 lề
            child: SizedBox(
              width: double.maxFinite,
              child: requests.isEmpty
                  ? Text(
                'Không có lịch sử đặt dịch vụ nào.',
                style: TextStyle(fontSize: 25.sp),
              )
                  : ListView.separated(
                shrinkWrap: true,
                itemCount: requests.length,
                separatorBuilder: (context, index) => Divider(thickness: 1.0),
                itemBuilder: (context, index) {
                  final data = requests[index].data();
                  final time = (data['createdAt'] as Timestamp).toDate();
                  return ListTile(
                    contentPadding: EdgeInsets.zero, // bỏ padding mặc định của ListTile
                    title: Text(
                      'Thời gian yêu cầu: ${data['requestTime'] ?? 'Không rõ'}',
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ghi chú: ${data['note'] ?? ''}',
                          style: TextStyle(fontSize: 15.sp),
                        ),
                        Text(
                          'Trạng thái: ${data['status'] ?? 'Đang xử lý'}',
                          style: TextStyle(fontSize: 15.sp),
                        ),
                        Text(
                          'Ngày gửi: ${time.day}/${time.month}/${time.year} - ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 15.sp),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Đóng', style: TextStyle(fontSize: 15.sp)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = updateService['price'] ?? 'Chưa có';
    final fileLink = updateService['fileLink'] ?? '';
    final imageServiceUrl = updateService['imageServiceUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          company.name,
          style: TextStyle(
              color: Colors.white,
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 25.sp),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageServiceUrl.isNotEmpty)
              Center(
                child: Image.network(imageServiceUrl, height: 200),
              ),
            SizedBox(height: 20.h),
            Text('Tên công ty: ${company.name}',
                style: TextStyle(fontSize: 15.h)),
            SizedBox(height: 20.h),
            Text('Loại dịch vụ: ${company.type}',
                style: TextStyle(fontSize: 15.h)),
            SizedBox(height: 20.h),
            Text('Mô tả: ${company.description}',
                style: TextStyle(fontSize: 15.h)),
            SizedBox(height: 20.h),
            Text('Số điện thoại: ${company.phone}',
                style: TextStyle(fontSize: 15.h)),
            SizedBox(height: 20.h),
            Text('Địa chỉ: ${company.address}',
                style: TextStyle(fontSize: 15.h)),
            SizedBox(height: 20.h),
            Text('Giá dịch vụ: $price', style: TextStyle(fontSize: 15.h)),
            SizedBox(height: 10.h),
            if (fileLink.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Trang dịch vụ: ", style: TextStyle(fontSize: 15.h)),
                  TextButton(
                      onPressed: () {
                        _openFile(context, fileLink);
                      },
                      child: Text(
                        'Xem chi tiết',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: 15.h,
                            fontStyle: FontStyle.italic),
                      )),
                ],
              ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              ElevatedButton(
                onPressed: () => _showBookingDialog(context),
                child: Text('Đặt dịch vụ', style: TextStyle(fontSize: 15.h)),
              ),
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: () => _showServiceHistoryDialog(context),
                child: Text('Xem lịch sử đặt dịch vụ', style: TextStyle(fontSize: 15.h)),
              ),

            ],)
          ],
        ),
      ),
    );
  }
}
