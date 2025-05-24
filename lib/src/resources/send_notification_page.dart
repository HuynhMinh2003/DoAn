import 'dart:async';
import 'dart:io';
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
                padding: EdgeInsets.only(left: 50.w, right: 40.w, top: 40.h),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
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

                        // Vùng ảnh có thể bấm vào để chọn ảnh
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            margin: EdgeInsets.only(bottom: 30.h),
                            decoration: BoxDecoration(
                              border: Border.all(color: bgColor),
                              borderRadius: BorderRadius.circular(12),
                              color: (_image != null || _webImage != null) ? null : Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (_image != null && !kIsWeb)
                                  ? Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                                  : (_webImage != null && kIsWeb)
                                  ? Image.memory(
                                _webImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                                  : Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        StreamBuilder<String>(
                          stream: _titleStream.stream,
                          builder: (context, snapshot) {
                            return TextField(
                              controller: _titleController,
                              onChanged: (value) => _titleStream.sink.add(value),
                              decoration: InputDecoration(
                                labelText: "Thông báo",
                                labelStyle: TextStyle(fontSize: 4.sp),
                                hintText: "Nhập tiêu đề thông báo...",
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
                                labelStyle: TextStyle(fontSize: 4.sp),
                                hintText: "Nhập chi tiết thông báo...",
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

                        // Chỉ còn nút gửi thông báo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: _sendInfo,
                              child: Text("Gửi thông báo",
                                  style: TextStyle(fontSize: 4.sp)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}