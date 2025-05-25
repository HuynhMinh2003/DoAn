import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart'; // THÊM DÒNG NÀY

import '../../constants.dart';
import 'dialog/msg_dialog.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  File? _image;
  Uint8List? _webImage;

  final _titleStream = StreamController<String>.broadcast();
  final _messageStream = StreamController<String>.broadcast();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    } else {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    try {
      if (_image == null && _webImage == null) {
        print('Không có ảnh nào được chọn.');
        return null;
      }

      String userId = _auth.currentUser?.uid ?? 'unknown_user';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('information_images/$userId/$timestamp.jpg');

      UploadTask uploadTask;

      if (kIsWeb && _webImage != null) {
        uploadTask = storageRef.putData(_webImage!);
      } else if (!kIsWeb && _image != null) {
        uploadTask = storageRef.putFile(_image!);
      } else {
        print("Không có dữ liệu ảnh hợp lệ để upload.");
        return null;
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Ảnh upload thành công: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Lỗi khi upload ảnh: $e');
      return null;
    }
  }

  void _sendInfo() async {
    String title = _titleController.text.trim();
    String feedbackText = _infoController.text.trim();

    _titleStream.sink.add(title);
    _messageStream.sink.add(feedbackText);

    if (title.isEmpty || feedbackText.isEmpty) {
      // StreamBuilder sẽ hiển thị lỗi, không cần show SnackBar ở đây
      return;
    }

    if (_image == null && _webImage == null) {
      // Nếu chưa chọn ảnh → hiện dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Center(child: Text("Thiếu ảnh", style: TextStyle(fontSize: 6.sp),),),
          content: Text("Vui lòng chọn ảnh cho thông báo!", style: TextStyle(fontSize: 4.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: TextStyle(fontSize: 4.sp)),
            ),
          ],
        ),
      );
      return;
    }

    try {
      String? uploadedImageUrl = await _uploadImage();

      // 1. Lưu thông báo vào Firestore
      await _firestore.collection("information").add({
        "title": title,
        "message": feedbackText,
        "imageUrl": uploadedImageUrl,
        "timestamp": FieldValue.serverTimestamp(),
        "seenBy": [],
      });

      // 2. Gửi FCM
      final callable = FirebaseFunctions.instance.httpsCallable('sendNotificationToResidents');
      final result = await callable.call({"title": title, "body": feedbackText});

      final data = result.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['success'] == true
            ? "Đã gửi thông báo đến ${data['sent']} người dùng."
            : "Lưu thành công nhưng không gửi được FCM: ${data['message']}")),
      );

      // 3. Reset form
      _titleController.clear();
      _infoController.clear();
      setState(() {
        _image = null;
        _webImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi gửi thông báo: $e")),
      );
    }
  }

  @override
  void dispose() {
    _titleStream.close();
    _messageStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 600;

                      return Column(
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            'Đăng thông báo chung',
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 50.h),

                          isMobile
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildImagePicker(),
                              SizedBox(height: 30.h),
                              _buildTextFields(),
                            ],
                          )
                              : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                flex: 4,
                                child: _buildImagePicker(),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                flex: 6,
                                child: _buildTextFields(),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildImagePicker() {
    final bool hasImage = _image != null || _webImage != null;

    Widget _buildImage() {
      if (_webImage != null && kIsWeb) {
        return Image.memory(
          _webImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else if (_image != null && !kIsWeb) {
        return Image.file(
          _image!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        return Icon(
          Icons.add_a_photo,
          size: 24.sp,
          color: Colors.grey,
        );
      }
    }

    double imageBoxSize = min(300.w, 300.h); // Đảm bảo ảnh không bị quá to

    return Center(
      child: SizedBox(
        width: imageBoxSize,
        height: imageBoxSize + 40.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: imageBoxSize,
              height: imageBoxSize,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 0.5.w),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await _pickImage();
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (_image == null && _webImage == null) {
                      MsgDialog.showMsgDialog(
                          context, "Lỗi", "Chưa chọn ảnh hoặc không tải được ảnh");
                    }
                  },
                  splashColor: Colors.grey.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  hasImage ? 'Thay đổi' : 'Thêm ảnh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 4.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<String>(
          stream: _titleStream.stream,
          builder: (context, snapshot) {
            return TextField(
              controller: _titleController,
              onChanged: (value) => _titleStream.sink.add(value),
              decoration: InputDecoration(
                labelText: "Thông báo",
                hintText: "Nhập tiêu đề thông báo...",
                labelStyle: TextStyle(fontSize: 4.sp),
                hintStyle: TextStyle(fontSize: 4.sp),
                border: OutlineInputBorder(),
                errorText: (snapshot.hasData && snapshot.data!.isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
            );
          },
        ),
        SizedBox(height: 50.h),
        StreamBuilder<String>(
          stream: _messageStream.stream,
          builder: (context, snapshot) {
            return TextField(
              controller: _infoController,
              maxLines: 5,
              onChanged: (value) => _messageStream.sink.add(value),
              decoration: InputDecoration(
                labelText: "Nội dung thông báo",
                hintText: "Nhập chi tiết thông báo...",
                labelStyle: TextStyle(fontSize: 4.sp),
                hintStyle: TextStyle(fontSize: 4.sp),
                border: OutlineInputBorder(),
                errorText: (snapshot.hasData && snapshot.data!.isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
            );
          },
        ),
        SizedBox(height: 30.h),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _sendInfo,
            child: Text(
              "Gửi thông báo",
              style: TextStyle(fontSize: 4.sp),
            ),
          ),
        ),
      ],
    );
  }


}