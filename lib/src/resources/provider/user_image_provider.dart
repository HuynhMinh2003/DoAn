import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserImageProvider extends ChangeNotifier {
  Uint8List? _image;

  Uint8List? get image => _image;

  // Phương thức cập nhật ảnh người dùng
  void setUserImage(Uint8List? newImage) {
    _image = newImage;
    notifyListeners();
  }
}
