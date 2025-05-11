import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/base_resident_info.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ResidentPage extends StatefulWidget {
  const ResidentPage({super.key});

  @override
  State<ResidentPage> createState() => _ResidentPageState();
}

class _ResidentPageState extends BaseResidentInfoScreen<ResidentPage> {
  @override
  void initState() {
    super.initState();
    final residentId = FirebaseAuth.instance.currentUser?.uid;
    // if (residentId != null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     Provider.of<UserImageProvider>(context, listen: false)
    //         .loadImageByStaffId(staffId);
    //   });
    // }
  }

  Future<void> _removeFcmToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print("⚠️ Không lấy được FCM Token");
        return;
      }

      DocumentReference userRef =
      FirebaseFirestore.instance.collection('residents').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        print("⚠️ User document không tồn tại trong Firestore!");
        return;
      }

      List<String> tokens = List<String>.from(userDoc['fcmTokens'] ?? []);

      if (tokens.contains(fcmToken)) {
        await userRef.update({
          'fcmTokens': FieldValue.arrayRemove([fcmToken]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print("✅ Đã xóa token FCM: $fcmToken");
      } else {
        print("⚠️ Token không tồn tại trong danh sách, không cần xóa.");
      }
    } catch (e) {
      print("❌ Lỗi khi xóa token FCM: $e");
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Đăng xuất',
              style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold,
                  fontSize: 25.sp),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: TextStyle(fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy', style: TextStyle(fontSize: 14.sp)),
            ),
            TextButton(
              onPressed: () async {
                await _removeFcmToken();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              child: Text('Đồng ý', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = Provider.of<StaffImageProvider>(context);
    String? avatarUrl = avatarProvider.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 9,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
            ),
            color: Colors.blueAccent,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Image.asset(
                    'assets/images/two_circle_green.png',
                    width: 160,
                  ),
                ),
                Positioned(
                  top: 32,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: _logout,
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
                      // CircleAvatar(
                      //   radius: 50.r,
                      //   backgroundImage: avatarUrl != null
                      //       ? NetworkImage(avatarUrl)
                      //       : null,
                      //   child: avatarUrl == null
                      //       ? const Icon(Icons.person, size: 50)
                      //       : null,
                      // ),
                      SizedBox(height: 60.h),
                      Text(
                        "Xin chào, ${residentInfo?.fullName ?? "người dùng"}",
                        style: TextStyle(
                            fontFamily: "Oswald",
                            fontSize: 25.sp,
                            color: Colors.white),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chỗ trống để thêm các widget nội dung phía dưới nếu cần
          Container(),
        ],
      ),
    );
  }
}
