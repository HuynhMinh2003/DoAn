import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/resident_info_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
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
        'status': 'Đang chờ xử lí',
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'assignedStaffId': null,
        'assignedStaffName': null,
        'managerNote': null,
        'handledAt': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi sự cố thành công')),
      );

      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi sự cố: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          bottom: true,
          top: true,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset('assets/images/two_circle_blue.png', width: 160),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 15.w,
                  top: 140.h,
                ),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2.w, bottom: 10.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/problem.svg',
                              width: 45.w,
                              height: 45.h,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Báo cáo sự cố',
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 45.sp,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30.h),

                        // KHUNG ẢNH CHỌN ẢNH
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
                        SizedBox(height: 16.h),

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
                        SizedBox(height: 10.h),

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

                        SizedBox(height: 24.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(width: 1.w,),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context), child: Text("Quay lại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),),),
                            ElevatedButton(
                              onPressed: () => _submitIncident(context),
                              child: Text(
                                'Gửi sự cố',
                                style: TextStyle(fontSize: 15.sp),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            SizedBox(width: 1.w,),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
