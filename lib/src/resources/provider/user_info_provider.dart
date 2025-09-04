import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserInfoProvider with ChangeNotifier {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;

  Future<void> getUserInfo() async {
    try {
      _isLoading = true;
      notifyListeners();

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DatabaseReference ref = FirebaseDatabase.instance.ref('users/${user.uid}');
      DatabaseEvent event = await ref.once();

      if (event.snapshot.exists) {
        _userInfo = Map<String, dynamic>.from(event.snapshot.value as Map);
      } else {
        _userInfo = null;
      }
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
