import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/provider/user__provider.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  Uint8List? _image; // Chỉ dùng một ảnh

  final picker = ImagePicker();

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataProvider =
    Provider.of<UserDataProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Image"),
        backgroundColor: const Color(0xff3277D8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageCard(), // Gọi hàm để xây dựng widget hiển thị ảnh
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3277D8),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)))),
              onPressed: () async {
                if (_image == null) {
                  // Hiển thị thông báo lỗi nếu chưa có ảnh
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Error"),
                      content: const Text("Please upload an image before signing up."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return; // Dừng lại nếu chưa có ảnh
                }

                // Hiển thị hộp thoại tải
                LoadingDialog.showLoadingDialog(context, 'Loading...');

                // Giả lập thời gian xử lý
                await Future.delayed(const Duration(seconds: 2));

                // Ẩn hộp thoại tải
                LoadingDialog.hideLoadingDialog(context);
              },
              child: const Text(
                "Sign Up",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị ảnh
  Widget _buildImageCard() {
    return GestureDetector(
      onTap: _pickImage, // Bấm vào ảnh để chọn từ thư viện
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _image != null
              ? Image.memory(
            _image!,
            fit: BoxFit.cover, // Ảnh sẽ lấp đầy khung chứa
          )
              : const Center(
            child: Text(
              "Tap to select image",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
