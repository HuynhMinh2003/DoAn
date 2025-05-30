import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/resident_info_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

import 'base_resident_info.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends BaseResidentInfoScreen<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _priority;
  File? _selectedImage;
  bool _isLoading = false;

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final fileName = '${const Uuid().v4()}_${basename(image.path)}';
    final ref = FirebaseStorage.instance.ref().child('incident_images/$fileName');
    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _submitIncident(BuildContext context) async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin và chọn hình ảnh')),
      );
      return;
    }

    setState(() => _isLoading = true);

    LoadingDialog.showLoadingDialog(context, "Đang gửi ... ");

    try {
      final imageUrl = await _uploadImage(_selectedImage!);

      await FirebaseFirestore.instance.collection('incidents').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'reporterId': residentInfo!.residentId,
        'reporterName': residentInfo!.fullName,
        'building': building,
        'apartmentAddress': apartmentName,
        'priority': null,
        'seenBy': null,
        'status': 'Đang chờ xử lí',
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'assignedStaffId': null,
        'assignedStaffName': null,
        'managerNote': null,
        'handledAt': null,
      });

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi sự cố thành công'),backgroundColor: Colors.green,),
      );

      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi sự cố: $e'),backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị dialog lịch sử sự cố
  Future<void> _showIncidentHistoryDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text('Lịch sử sự cố',style: TextStyle(fontSize: 25.sp,fontWeight: FontWeight.bold, fontFamily: "Oswald"),),),
          content: SizedBox(
            width: double.maxFinite,
            height: 400.h,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .where('reporterId', isEqualTo: residentInfo!.residentId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Chưa có báo cáo sự cố nào.',style: TextStyle(fontSize: 15.sp)));
                }
                final incidents = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: incidents.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final doc = incidents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    final status = data['status'] ?? 'Chưa có trạng thái';
                    final timestamp = data['createdAt'] as Timestamp?;
                    final createdAt = timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000)
                        : null;
                    final imageUrl = data['imageUrl'] as String?;

                    return ListTile(
                      title: Text(
                        "Tên sự cố: $title",
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Trạng thái: $status",
                            style: TextStyle(fontSize: 15.sp),
                          ),
                          SizedBox(height: 5.h),
                          if (createdAt != null)
                            Text(
                              '${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                              style: TextStyle(fontSize: 15.sp),
                            ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Center(child: Text("Tên sự cố: ${data['title']} ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),),
                            content: SizedBox(
                              width: double.maxFinite,
                              // Giới hạn chiều cao để scroll hoạt động ổn định
                              height: 350.h,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Mô tả: ${data['description']}", style: TextStyle(fontSize: 16.sp)),
                                    SizedBox(height: 10.h),
                                    Text("Trạng thái: ${data['status']}", style: TextStyle(fontSize: 15.sp)),
                                    SizedBox(height: 10.h),
                                    if (createdAt != null)
                                      Text("Ngày báo cáo: ${createdAt.day}/${createdAt.month}/${createdAt.year}", style: TextStyle(fontSize: 15.sp)),
                                    SizedBox(height: 10.h),
                                    if (imageUrl != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Hình ảnh:", style: TextStyle( fontSize: 15.sp)),
                                          SizedBox(height: 8.h),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              width: double.infinity,
                                              height: 200.h, // cố định chiều cao cho ảnh
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              ElevatedButton(
                                child: Text('Đóng', style: TextStyle(fontSize: 15.sp)),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      },

                    );
                  },
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              child: Text('Đóng',style: TextStyle(fontSize: 15.sp)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Báo cáo sự cố',
            style: TextStyle(
              color: Colors.white,
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 25.sp,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SafeArea(
          bottom: true,
          top: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 15.w,
              top: 30.h,
            ),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ảnh sự cố: ',style: TextStyle(fontSize: 15.sp),),
                    SizedBox(height: 20.h,),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 230.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade400),
                          color: Colors.grey.shade100,
                          image: _selectedImage != null
                              ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40.sp, color: Colors.grey),
                              SizedBox(height: 8.h),
                              Text(
                                'Nhấn để chọn hình ảnh',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                            : null,
                      ),
                    ),
                    SizedBox(height: 40.h),

                    // TIÊU ĐỀ
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề',
                        labelStyle: TextStyle(fontSize: 15.sp),
                        hintText: 'Nhập tiêu đề sự cố',
                        hintStyle: TextStyle(fontSize: 15.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 40.h),

                    // MÔ TẢ
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả',
                        labelStyle: TextStyle(fontSize: 15.sp),
                        hintText: 'Nhập mô tả chi tiết về sự cố',
                        hintStyle: TextStyle(fontSize: 15.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 40.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _submitIncident(context),
                          child: Text(
                            'Gửi sự cố',
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15.sp),
                          ),
                        ),

                        ElevatedButton(
                          onPressed: () => _showIncidentHistoryDialog(context),
                          child: Text(
                            'Xem lịch sử sự cố',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ),
      ),
    );
  }

}
