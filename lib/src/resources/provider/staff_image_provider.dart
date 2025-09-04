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

  File? _selectedImageFile;

  Uint8List? _webImageBytes;

  File? get selectedImageFile => _selectedImageFile;

  Uint8List? get webImageBytes => _webImageBytes;

  StaffImageProvider() {
    fetchAvatar();
  }

  @override
  void dispose() {
    _avatarListener?.cancel();
    super.dispose();
  }

  void fetchAvatar() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

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

  void resetImage() {
    _selectedImageFile = null;
    _webImageBytes = null;
    _avatarUrl = null;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    if (kIsWeb) {
      _webImageBytes = await pickedFile.readAsBytes();
      notifyListeners();
    } else {
      File imageFile = File(pickedFile.path);

      if (!imageFile.path.endsWith('.jpg')) {
        imageFile = await _convertToJpegIfNeeded(imageFile);
      }

      _selectedImageFile = imageFile;
      notifyListeners();
    }
  }

  Future<String?> uploadSelectedImageAndGetUrl(String userId, String uniqueFileName) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('staffs/$userId/$uniqueFileName');

      UploadTask uploadTask;

      if (kIsWeb && _webImageBytes != null) {
        uploadTask = storageRef.putData(_webImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
      } else if (_selectedImageFile != null) {
        uploadTask = storageRef.putFile(_selectedImageFile!);
      } else {
        return null;
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadSelectedImageAndGetUrl1(
      String userId, String uniqueFileName, {String? oldImageUrl}) async {
    try {
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        final uri = Uri.tryParse(oldImageUrl);
        final segments = uri?.pathSegments;

        if (segments != null && segments.length >= 2) {
          final index = segments.indexWhere((e) => e.contains('%2F') || e.endsWith('.jpg'));
          final encodedPath = segments.sublist(index).join('/');
          final decodedPath = Uri.decodeFull(encodedPath);

          await FirebaseStorage.instance.ref(decodedPath).delete();

        }
      }

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
        return null;
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<File> _convertToJpegIfNeeded(File file) async {
    if (kIsWeb) return file;

    try {
      final imageBytes = await file.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        return file;
      }

      bool isHeic = file.path.toLowerCase().endsWith('.heic') || file.path.toLowerCase().endsWith('.heif');

      if (isHeic) {
        final tempDir = await getTemporaryDirectory();
        final convertedFile = File('${tempDir.path}/converted.jpg');
        final resized = img.copyResize(decodedImage, width: 512);
        await convertedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));
        return convertedFile;
      }

      return file;
    } catch (e) {
      return file;
    }
  }

  Future<void> deleteImage() async {
    _selectedImageFile = null;
    _webImageBytes = null;

    notifyListeners();
  }

  Future<void> loadImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
      _avatarUrl = null;
    }
  }

  Future<void> loadImageByStaffId(String staffId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('staffs').doc(staffId).get();

      final data = snapshot.data();
      if (data == null || !data.containsKey('imageUrl')) {
        _avatarUrl = null;
      } else {
        _avatarUrl = data['imageUrl'];
      }
      notifyListeners();
    } catch (e) {
      _avatarUrl = null;
      notifyListeners();
    }
  }

}
