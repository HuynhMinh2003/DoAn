import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class StaffImageProvider extends ChangeNotifier {
  String? _avatarUrl;

  String? get avatarUrl => _avatarUrl;

  final ImagePicker _picker = ImagePicker();

  StreamSubscription<DocumentSnapshot>? _avatarListener;

  File? _selectedImageFile; // Ảnh chọn tạm

  Uint8List? _webImageBytes; // Ảnh web chọn tạm

  File? get selectedImageFile => _selectedImageFile;

  Uint8List? get webImageBytes => _webImageBytes;

  StaffImageProvider() {
    _fetchAvatar();
  }

  void _fetchAvatar() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Tham chiếu Firestore đến tài liệu người dùng
    DocumentReference docRef = FirebaseFirestore.instance.collection("staffs").doc(userId);

    _avatarListener?.cancel();
    _avatarListener = docRef.snapshots().listen((event) {
      if (event.exists) {
        _avatarUrl = (event.data() as Map<String, dynamic>)['imageUrl'] as String?;
      }
      else {
        _avatarUrl = null;
      }
      notifyListeners();
    });
  }

  // Chọn ảnh → lưu tạm (KHÔNG upload)
  Future<void> pickImage() async {
    print("🖼️ Bắt đầu pick ảnh");
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      print("❌ Không chọn ảnh nào");
      return;
    }

    if (kIsWeb) {
      _webImageBytes = await pickedFile.readAsBytes();
      notifyListeners(); // Cập nhật ảnh web hiển thị
    } else {
      File imageFile = File(pickedFile.path);

      if (!imageFile.path.endsWith('.jpg')) {
        imageFile = await _convertToJpegIfNeeded(imageFile);
      }

      _selectedImageFile = imageFile;
      notifyListeners(); // Cập nhật ảnh native hiển thị
    }
  }

  // Phương thức reset ảnh
  void resetImage() {
    _selectedImageFile = null;
    _webImageBytes = null;
    _avatarUrl = null;
    notifyListeners(); // Cập nhật UI
  }

  // Chỉ gọi khi nhấn nút đăng ký → upload ảnh + lưu Firestore
  Future<String?> uploadSelectedImageAndGetUrl(String userId, String uniqueFileName) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('staffs/$userId/$uniqueFileName'); // Sử dụng tên file duy nhất

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        // Với web
        uploadTask = storageRef.putData(_webImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
      } else if (_selectedImageFile != null) {
        // Với thiết bị thật
        uploadTask = storageRef.putFile(_selectedImageFile!);
      } else {
        print('❌ Không có ảnh để upload');
        return null;
      }

      // Đợi upload hoàn tất
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload thành công. URL = $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Lỗi khi upload ảnh: $e');
      return null;
    }
  }

  Future<String?> uploadSelectedImageAndGetUrl1(
      String userId, String uniqueFileName, {String? oldImageUrl}) async {
    try {
      // 🧹 Xoá ảnh cũ trước (nếu có)
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        final uri = Uri.tryParse(oldImageUrl);
        final segments = uri?.pathSegments;

        if (segments != null && segments.length >= 2) {
          // Với đường dẫn dạng: /v0/b/your-project.appspot.com/o/residents%2Fuid%2Ffilename.jpg?alt=media...
          final index = segments.indexWhere((e) => e.contains('%2F') || e.endsWith('.jpg'));
          final encodedPath = segments.sublist(index).join('/');
          final decodedPath = Uri.decodeFull(encodedPath);

          try {
            await FirebaseStorage.instance.ref(decodedPath).delete();
            print('🗑️ Đã xoá ảnh cũ: $decodedPath');
          } catch (e) {
            print('⚠️ Không thể xóa ảnh cũ: $e');
          }
        }
      }

      // 📤 Upload ảnh mới
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('staffs/$userId/$uniqueFileName');

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        uploadTask = storageRef.putData(
            _webImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
      } else if (_selectedImageFile != null) {
        uploadTask = storageRef.putFile(_selectedImageFile!);
      } else {
        print('❌ Không có ảnh để upload');
        return null;
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload thành công. URL = $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Lỗi khi upload ảnh: $e');
      return null;
    }
  }

  Future<File> _convertToJpegIfNeeded(File file) async {
    if (kIsWeb) return file;

    try {
      final imageBytes = await file.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        print("⚠️ Không thể đọc ảnh: giữ nguyên file gốc");
        return file;
      }

      bool isHeic = file.path.toLowerCase().endsWith('.heic') || file.path.toLowerCase().endsWith('.heif');

      if (isHeic) {
        print("🔄 Chuyển HEIC → JPEG...");
        final tempDir = await getTemporaryDirectory();
        final convertedFile = File('${tempDir.path}/converted.jpg');
        final resized = img.copyResize(decodedImage, width: 512);
        await convertedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));
        return convertedFile;
      }

      return file;
    } catch (e) {
      print("❌ Lỗi chuyển ảnh: $e");
      return file;
    }
  }

  Future<void> deleteImage() async {
    // Chỉ xóa ảnh đang hiển thị tạm thời (không ảnh hưởng đến Firestore hay Storage)
    _selectedImageFile = null;
    _webImageBytes = null;

    notifyListeners();
  }

  Future<void> loadImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 🔹 Lấy thông tin người dùng từ Firestore để biết tên file ảnh
      final snapshot = await FirebaseFirestore.instance.collection('staffs').doc(user.uid).get();
      final data = snapshot.data();
      if (data == null || !data.containsKey('imageFileName')) {
        _avatarUrl = null;
        notifyListeners();
        return;
      }

      final fileName = data['imageFileName'];
      final storageRef = FirebaseStorage.instance.ref('avatars/$fileName');

      String downloadURL = await storageRef.getDownloadURL();
      _avatarUrl = downloadURL;
      notifyListeners();
    } catch (e) {
      print("⚠️ Không thể tải ảnh từ Firebase Storage: $e");
      _avatarUrl = null;
    }
  }

  Future<void> loadImageByStaffId(String staffId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('staffs').doc(staffId).get();
      print("Snapshot data: ${snapshot.data()}");  // Log dữ liệu nhận được từ Firestore

      final data = snapshot.data();
      if (data == null || !data.containsKey('imageUrl')) {
        _avatarUrl = null;
      } else {
        _avatarUrl = data['imageUrl'];
      }
      print("Avatar URL: $_avatarUrl");  // Kiểm tra giá trị avatarUrl
      notifyListeners();
    } catch (e) {
      print("⚠️ Không thể tải ảnh từ Firestore: $e");
      _avatarUrl = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _avatarListener?.cancel();
    super.dispose();
  }
}
