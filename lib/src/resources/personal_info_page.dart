import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_storage/firebase_storage.dart';


class PersonalInfoPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const PersonalInfoPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  String? _avatarUrl;

  late User _user;
  Map<String, dynamic>? userInfo;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isLoading = false; // Trạng thái loading

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _fetchUserAvatar();
  }

  Future<void> _getUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });
      _user = _auth.currentUser!;
      DatabaseReference ref = _database.ref('users/${_user.uid}');
      DatabaseEvent event = await ref.once();

      if (event.snapshot.exists) {
        setState(() {
          userInfo = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      } else {
        print('Không có dữ liệu người dùng.');
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin người dùng: $e');
      _showSnackBar('Không thể tải thông tin người dùng.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserAvatar() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("users/$userId/avatar");

    dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _avatarUrl = event.snapshot.value.toString();
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Sau khi chọn ảnh, upload lên Firebase Storage
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Tạo tên file duy nhất
      Reference storageRef = FirebaseStorage.instance.ref().child('avatars/$fileName.jpg');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      String imageUrl = await snapshot.ref.getDownloadURL(); // Lấy URL ảnh
      print("URL ảnh: $imageUrl");

      // Sau khi upload xong, lưu URL vào Firebase Realtime Database
      await _saveImageUrlToDatabase(imageUrl);
    } catch (e) {
      print('Lỗi khi upload ảnh: $e');
    }
  }

  Future<void> _saveImageUrlToDatabase(String imageUrl) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("users/$userId");

    await dbRef.update({
      "avatarUrl": imageUrl, // Lưu URL vào database
    });

    print("Đã lưu URL ảnh vào Firebase Database!");

    // Cập nhật UI để hiển thị ảnh từ Firebase
    setState(() {
      _avatarUrl = imageUrl;
    });
  }

  Future<void> _deleteImage() async {
    if (_avatarUrl == null) return;

    try {
      // Xóa ảnh khỏi Firebase Storage
      Reference storageRef = FirebaseStorage.instance.refFromURL(_avatarUrl!);
      await storageRef.delete();

      // Xóa URL ảnh trong Realtime Database
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("users/$userId");
      await dbRef.update({"avatar": null});

      // Cập nhật UI
      setState(() {
        _avatarUrl = null;
        _image = null;
      });

      print("Ảnh đã được xóa!");
    } catch (e) {
      print("Lỗi khi xóa ảnh: $e");
    }
  }
  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi ngày sinh từ Firebase (chuỗi) thành DateTime
    String formattedBirthDate = _formatDate(userInfo?['birthDate']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: const Color(0xff3277D8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[200],
                    child: _avatarUrl != null
                        ? ClipOval(
                      child: Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        width: 160,
                        height: 160,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(); // Hiển thị loading khi đang tải ảnh
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: Colors.red),
                      ),
                    )
                        : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _avatarUrl == null ? 'Thêm ảnh' : 'Thay đổi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_avatarUrl != null)
                    Positioned(
                      top: 10,
                      right: 110,
                      child: GestureDetector(
                        onTap: () async {
                          await _deleteImage(); // Xóa ảnh
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 40.h,),
            _buildInfoRow('Tên:', userInfo?['name']),
            _buildInfoRow('Số CCCD:', userInfo?['cccd']),
            _buildInfoRow('Ngày sinh:', formattedBirthDate),
            _buildInfoRow('Email:', userInfo?['email']),
            _buildInfoRow('Số điện thoại:', userInfo?['phone']),
            _buildInfoRow('Tên căn hộ:', userInfo?['nameHouse']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8), // Điều chỉnh padding theo màn hình
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều ngang
        children: [
          RichText(
            textAlign: TextAlign.center, // Đảm bảo căn giữa nội dung
            text: TextSpan(
              style: TextStyle(fontSize: 16, color: Colors.black), // Áp dụng style chung
              children: [
                TextSpan(
                  text: "$label ", // Tiêu đề (Ví dụ: "Tên: ")
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value ?? 'Không có dữ liệu', // Giá trị hiển thị
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm chuyển đổi ngày sinh thành định dạng chuẩn
  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        DateTime parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsedDate);  // Định dạng ngày
      } catch (e) {
        return 'Không có dữ liệu';
      }
    }
    return 'Không có dữ liệu';
  }
}
