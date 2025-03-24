import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

mixin BaseUser {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Map<String, dynamic>? userInfo;
  bool isLoading = false;

  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      isLoading = true;
      User? user = _auth.currentUser;
      if (user == null) return null;

      DatabaseReference ref = _database.ref('users/${user.uid}');
      DatabaseEvent event = await ref.once();

      if (event.snapshot.exists) {
        userInfo = Map<String, dynamic>.from(event.snapshot.value as Map);
      } else {
        userInfo = null;
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin người dùng: $e");
    } finally {
      isLoading = false;
    }
    return userInfo;
  }
}
