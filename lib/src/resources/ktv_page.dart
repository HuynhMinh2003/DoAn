import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/problem_history_page.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:do_an/src/resources/staff_incident_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../base_staff_info.dart';
import 'login_page.dart';

class KTVPage extends StatefulWidget {
  const KTVPage({super.key});

  @override
  State<KTVPage> createState() => _KTVPageState();
}

class _KTVPageState extends BaseStaffInfoScreen<KTVPage> {
  @override
  void initState() {
    super.initState();
    final staffId = FirebaseAuth.instance.currentUser?.uid;
    if (staffId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<StaffImageProvider>(context, listen: false)
            .loadImageByStaffId(staffId); // đúng hàm và id
      });
    }
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
      FirebaseFirestore.instance.collection('staffs').doc(userId);
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
              child: Text('Hủy', style: TextStyle(fontSize: 14.sp,color: Colors.black)),
            ),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Đồng ý',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Column(
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
                color: Color(0xFF3C4DFF),
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
                        onPressed: _logout,
                        tooltip: 'Đăng xuất',
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 80.h),
                          Center(
                            child: Consumer<StaffImageProvider>(
                              builder: (context, imageProvider, _) {
                                Widget avatarChild;

                                if (imageProvider.avatarUrl != null && imageProvider.avatarUrl!.isNotEmpty) {
                                  avatarChild = Image.network(
                                    imageProvider.avatarUrl!,
                                    width: 140.r,
                                    height: 140.r,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return SvgPicture.asset(
                                        'assets/images/default_avatar.svg',
                                        width: 65.r,
                                        height: 65.r,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  );
                                } else {
                                  avatarChild = SvgPicture.asset(
                                    'assets/images/default_avatar.svg',
                                    width: 65.r,
                                    height: 65.r,
                                    fit: BoxFit.contain,
                                  );
                                }

                                return Container(
                                  width: 140.r,
                                  height: 140.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white, // ✅ Nền trắng
                                    border: Border.all(color: Colors.white, width: 2), // ✅ Viền trắng
                                  ),
                                  alignment: Alignment.center,
                                  child: ClipOval(
                                    child: avatarChild,
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: 20.h),
                          Text(
                            "${staffInfo?.fullName ??
                                "kỹ thuật viên"}",
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontSize: 25.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            "- Kỹ thuật viên -" ,
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontSize: 20.sp,
                              color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic
                            ),
                          ),
                          SizedBox(height: 5.h),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 10.h,),
              Container(
                  child: Padding(padding: EdgeInsets.only(top: 50.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('incidents')
                                    .where('assignedStaffId', isEqualTo: staffInfo?.uid)
                                    .where('status', isEqualTo: 'Đang xử lý')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final docs = snapshot.data?.docs ?? [];

                                  final unseenDocs = docs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final seenByList = data['seenBy'] as List<dynamic>? ?? [];
                                    return staffInfo?.uid != null && !seenByList.contains(staffInfo!.uid);
                                  }).toList();

                                  final count = unseenDocs.length;

                                  return buildServiceCard1(
                                    context,
                                    svgPath: 'assets/images/warning.svg',
                                    label: 'Sự cố mới',
                                    badgeCount: count,
                                    onTap: () async {
                                      if (staffInfo?.uid != null) {
                                        for (final doc in unseenDocs) {
                                          await doc.reference.update({
                                            'seenBy': FieldValue.arrayUnion([staffInfo!.uid]),
                                          });
                                        }
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StaffIncidentPage(
                                            staffId: staffInfo!.uid,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 30.h), // Khoảng cách giữa 2 card

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
                              child: buildServiceCard(
                                context,
                                svgPath: 'assets/images/clipboard.svg',
                                label: 'Lịch sử sự cố',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProblemHistoryScreen(
                                        staffId: staffInfo!.uid,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                          ],
                        )
                    ),)

            ],
          )
        ],
      ),
    );
  }
  Widget buildServiceCard(
      BuildContext context, {
        required String svgPath, // Đường dẫn ảnh SVG
        required String label,
        required VoidCallback onTap,
      }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) {
            (context as Element).markNeedsBuild();
          },
          onTapUp: (_) {
            onTap();
          },
          child: Material(
            color: Colors.white,
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.blue.withOpacity(0.2),
              highlightColor: Colors.blue.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.all(12),
                width: 120.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      svgPath,
                      width: 70,
                      height: 70

                    ),
                    SizedBox(height: 8.h),
                    Text(label, style:TextStyle(fontWeight: FontWeight.bold,fontSize: 13.sp),textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildServiceCard1(
      BuildContext context, {
        required String svgPath,
        required String label,
        required VoidCallback onTap,
        int? badgeCount,
      }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Stack(
          children: [
            Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.blue.withOpacity(0.2),
                highlightColor: Colors.blue.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: 120.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        svgPath,
                        width: 70,
                        height: 70,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
