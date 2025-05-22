import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      if (_image == null && _webImage == null) return null;
      String userId = _auth.currentUser!.uid;
      Reference storageRef = FirebaseStorage.instance.ref().child('information_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = storageRef.putData(_webImage!);
      } else {
        uploadTask = storageRef.putFile(_image!);
      }

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Lỗi khi upload ảnh: $e');
      return null;
    }
  }

  void _sendInfo() async {
    String title = _titleController.text.trim();
    String feedbackText = _infoController.text.trim();
    if (title.isEmpty || feedbackText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ tiêu đề và nội dung thông báo!")),
      );
      return;
    }

    try {
      String? uploadedImageUrl = await _uploadImage();

      await _firestore.collection("information").add({
        "title": title,
        "message": feedbackText,
        "imageUrl": uploadedImageUrl,
        "timestamp": FieldValue.serverTimestamp(),
        "seenBy": [], // 👈 Thêm trường seenBy để theo dõi ai đã xem
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thông báo đã được gửi thành công!")),
      );

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gửi thông báo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Thông báo",
                hintText: "Nhập tiêu đề thông báo...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _infoController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Nội dung thông báo",
                hintText: "Nhập chi tiết thông báo...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_image != null && !kIsWeb)
              Image.file(_image!, height: 150),
            if (_webImage != null && kIsWeb)
              Image.memory(_webImage!, height: 150),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Chọn ảnh"),
                ),
                ElevatedButton(
                  onPressed: _sendInfo,
                  child: const Text("Gửi thông báo"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}