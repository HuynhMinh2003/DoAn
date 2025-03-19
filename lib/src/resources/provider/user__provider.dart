import 'package:flutter/foundation.dart';

class UserDataProvider with ChangeNotifier {
  String name = '';
  String email = '';
  String phone = '';
  DateTime birthDate = DateTime.now();
  String apartment = '';
  String password = '';

  void updateUserData({
    required String name,
    required String email,
    required String phone,
    required String birthDate,
    required String apartment,
    required String password,
  }) {
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.birthDate = DateTime.parse(birthDate);;
    this.apartment = apartment;
    this.password = password;
    notifyListeners();
  }
}
