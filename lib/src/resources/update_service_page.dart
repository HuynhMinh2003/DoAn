import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../models/company_info.dart';
import 'dialog/loading_dialog.dart';

class UpdateServicePage extends StatefulWidget {
  final CompanyInfo company;

  const UpdateServicePage({super.key, required this.company});

  @override
  State<UpdateServicePage> createState() => _UpdateServicePageState();
}

class _UpdateServicePageState extends State<UpdateServicePage> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _fileLinkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  final _priceErrorController = StreamController<String?>.broadcast();
  final _fileLinkErrorController = StreamController<String?>.broadcast();
  final _descriptionErrorController = StreamController<String?>.broadcast();

  File? _selectedImageFile;
  String? _imagePreviewUrl;

  @override
  void initState() {
    super.initState();
    _loadLatestServiceData();
  }

  Future<void> _loadLatestServiceData() async {
    final docRef = FirebaseFirestore.instance.collection('companies').doc(widget.company.companyId);

    final companyDoc = await docRef.get();
    _descriptionController.text = companyDoc['description'] ?? '';
    _typeController.text = companyDoc['type'] ?? '';

    final updates = await docRef
        .collection('updateService')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (updates.docs.isNotEmpty) {
      final data = updates.docs.first.data();
      _priceController.text = data['price'] ?? '';
      _fileLinkController.text = data['fileLink'] ?? '';
      _imagePreviewUrl = data['imageServiceUrl'];
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImageFile = File(picked.path);
        _imagePreviewUrl = null; // clear old preview
      });
    }
  }

  Future<void> _submitUpdate() async {
    final price = _priceController.text.trim();
    final fileLink = _fileLinkController.text.trim();
    final description = _descriptionController.text.trim();
    final type = _typeController.text.trim();

    bool hasError = false;

    if (price.isEmpty) {
      _priceErrorController.sink.add('Vui lòng nhập giá');
      hasError = true;
    } else {
      _priceErrorController.sink.add(null);
    }

    if (fileLink.isEmpty) {
      _fileLinkErrorController.sink.add('Vui lòng nhập link tài liệu');
      hasError = true;
    } else {
      _fileLinkErrorController.sink.add(null);
    }

    if (description.isEmpty) {
      _descriptionErrorController.sink.add('Vui lòng nhập mô tả');
      hasError = true;
    } else {
      _descriptionErrorController.sink.add(null);
    }

    if (_selectedImageFile == null && _imagePreviewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ảnh dịch vụ trước khi cập nhật', style: TextStyle(fontSize: 15.sp)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (hasError) return;

    LoadingDialog.showLoadingDialog(context, "Đang cập nhật ...");

    try {
      final companyRef = FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.company.companyId);

      await companyRef.update({
        'description': description,
        'type': type,
      });

      String? imageUrl;
      if (_selectedImageFile != null) {
        final fileName = 'service_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('service_images/$fileName');

        // Upload ảnh
        final uploadTask = await ref.putFile(_selectedImageFile!);
        imageUrl = await ref.getDownloadURL();

        // ✅ Chờ ảnh sẵn sàng (đặc biệt quan trọng với Flutter Web)
        await Future.delayed(Duration(seconds: 1));
      }

      await companyRef.collection('updateService').add({
        'price': price,
        'fileLink': fileLink,
        'imageServiceUrl': imageUrl ?? _imagePreviewUrl,
        'status': "Đang chờ duyệt",
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật dịch vụ thành công', style: TextStyle(fontSize: 15.sp)), backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required Stream<String?> errorStream,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return StreamBuilder<String?>(
      stream: errorStream,
      builder: (context, snapshot) {
        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            errorText: snapshot.data,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _fileLinkController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _priceErrorController.close();
    _fileLinkErrorController.close();
    _descriptionErrorController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cập nhật dịch vụ',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(left: 20.w, right: 15.w, top: 40.h),
            child: Padding(
              padding: EdgeInsets.only(left: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ảnh dịch vụ:', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 10.h),

                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_selectedImageFile == null && _imagePreviewUrl == null) {
                            _pickImage(); // Gọi chọn ảnh nếu chưa có ảnh
                          }
                        },
                        child: Container(
                          height: 230.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade400),
                            color: Colors.grey.shade100,
                            image: _selectedImageFile != null
                                ? DecorationImage(
                              image: FileImage(_selectedImageFile!),
                              fit: BoxFit.cover,
                            )
                                : _imagePreviewUrl != null
                                ? DecorationImage(
                              image: NetworkImage(_imagePreviewUrl!),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: (_selectedImageFile == null && _imagePreviewUrl == null)
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40.sp, color: Colors.grey),
                                SizedBox(height: 8.h),
                                Text(
                                  'Nhấn để chọn ảnh',
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

                      // Nút đổi ảnh nếu đã có ảnh
                      if (_selectedImageFile != null || _imagePreviewUrl != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: CircleBorder(),
                            child: InkWell(
                              onTap: _pickImage,
                              customBorder: CircleBorder(),
                              child: Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  _buildInputField(
                    controller: _typeController,
                    label: 'Loại dịch vụ',
                    errorStream: const Stream.empty(), // không cần validate
                  ),
                  SizedBox(height: 20.h),

                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Mô tả dịch vụ',
                    errorStream: _descriptionErrorController.stream,
                    maxLines: 3,
                  ),
                  SizedBox(height: 20.h),

                  _buildInputField(
                    controller: _priceController,
                    label: 'Giá',
                    errorStream: _priceErrorController.stream,
                  ),
                  SizedBox(height: 20.h),

                  _buildInputField(
                    controller: _fileLinkController,
                    label: 'Link chi tiết',
                    errorStream: _fileLinkErrorController.stream,
                  ),
                  SizedBox(height: 20.h),

                  Center(child: SizedBox(
                    width: 200.w,
                    child: ElevatedButton(
                      onPressed: _submitUpdate,
                      child: Text('Cập nhật', style: TextStyle(fontSize: 16.sp)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                    ),
                  ))
                ],
              ),
            ),
          )
        ),
      ),
    );
  }
}
