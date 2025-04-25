import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/provider/user_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:do_an/base_staff_info.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends BaseStaffInfoScreen<StaffPage> {
  @override
  void initState() {
    super.initState();
    final staffId = FirebaseAuth.instance.currentUser?.uid;
    if (staffId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<UserImageProvider>(context, listen: false).loadImageByStaffId(staffId);
        getStaffInfo(staffId);
      });
    }
  }

  /// Hàm xóa token khỏi Firestore khi đăng xuất
  Future<void> _removeFcmToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // Không có userId thì không làm gì cả

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print("⚠️ Không lấy được FCM Token");
        return;
      }

      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        print("⚠️ User document không tồn tại trong Firestore!");
        return;
      }

      List<String> tokens = List<String>.from(userDoc['fcmTokens'] ?? []);

      if (tokens.contains(fcmToken)) {
        await userRef.update({
          'fcmTokens': FieldValue.arrayRemove([fcmToken]),
        });
        print("✅ Đã xóa token FCM: $fcmToken");
      } else {
        print("⚠️ Token không tồn tại trong danh sách, không cần xóa.");
      }

    } catch (e) {
      print("❌ Lỗi khi xóa token FCM: $e");
    }
  }

  /// Đăng xuất tài khoản
  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text('Đăng xuất',style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: 25.sp ),),) ,
          content: Text('Bạn có chắc chắn muốn đăng xuất không?', style: TextStyle(fontSize: 13.sp),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy', style: TextStyle(fontSize: 14.sp),),
            ),
            TextButton(
              onPressed: () async {
                await _removeFcmToken(); // Xóa token FCM trước khi đăng xuất
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              child: Text('Đồng ý', style: TextStyle(fontSize: 14.sp),),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final avatarProvider = Provider.of<UserImageProvider>(context);
    String? avatarUrl = avatarProvider.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.grey[200], // Màu nền nhẹ
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Color(0xFF00BAAA),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Image.asset(
                    'assets/images/two_circle.png',
                    width: 160,
                  ),
                ),
                Positioned(
                  top: 32,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () {
                      _logout();
                    },
                    tooltip: 'Đăng xuất',
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 100.h),
                      CircleAvatar(
                        radius: 70.r,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "Xin chào, ${staffInfo?["name"] ?? "người dùng"}",
                        style: TextStyle(fontFamily:"Oswald",fontSize: 25.sp, color: Colors.white),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        "${staffInfo?["position"] ?? "Chức vụ không rõ"}",
                        style: TextStyle(fontFamily:"Oswald",fontSize: 20.sp, color: Colors.white),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              // Khoảng trắng bên dưới
            ),
          ),
        ],
      ),

    );
  }
}

