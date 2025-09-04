import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/company/base_company_info.dart';
import 'package:do_an/src/resources/provider/company_image_provider.dart';
import 'package:do_an/src/resources/resident/resident_request_list_page.dart';
import 'package:do_an/src/resources/company/service_update_list_page.dart';
import 'package:do_an/src/resources/company/update_service_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../login_page.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key});

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends BaseCompanyInfo<CompanyPage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    final companyId = FirebaseAuth.instance.currentUser?.uid;
    if (companyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<CompanyImageProvider>(context, listen: false)
            .loadImageByCompanyId(companyId);
      });
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

  Future<void> _removeFcmToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      return;
    }

    DocumentReference userRef =
    FirebaseFirestore.instance.collection('companies').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();

    if (!userDoc.exists) {
      return;
    }

    List<String> tokens = List<String>.from(userDoc['fcmTokens'] ?? []);

    if (tokens.contains(fcmToken)) {
      await userRef.update({
        'fcmTokens': FieldValue.arrayRemove([fcmToken]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
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
                color: Colors.red,
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
                            child: Consumer<CompanyImageProvider>(
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
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 2),
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
                            "${companyInfo?.name ?? "Công ty"}",
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontSize: 25.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 10.h,
              ),
              Container(
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h,),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                              left: 50.w, right: 50.w, top: 10.h, bottom: 10.h),
                          mainAxisSpacing: 30,
                          crossAxisSpacing: 30,
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('serviceRequests')
                                  .where('companyId', isEqualTo: companyInfo?.companyId)
                                  .where('status', isEqualTo: 'Đang chờ duyệt')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final docs = snapshot.data?.docs ?? [];

                                final unseenDocs = docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final seenBy = data.containsKey('seenBy') ? data['seenBy'] as String? : null;
                                  return userId != null && seenBy != userId;
                                }).toList();

                                final count = unseenDocs.length;

                                return buildServiceCard1(
                                  context,
                                  svgPath: 'assets/images/request.svg',
                                  label: 'Danh sách đăng kí',
                                  badgeCount: count,
                                  onTap: () async {
                                    if (userId != null) {
                                      for (final doc in unseenDocs) {
                                        await doc.reference.update({
                                          'seenBy': userId,
                                        });
                                      }
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ResidentRequestListPage(
                                          companyId: companyInfo!.companyId!,
                                          companyName: companyInfo!.name,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            buildServiceCard(
                              context,
                              svgPath: 'assets/images/update_service.svg',
                              label: 'Cập nhật dịch vụ',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateServicePage(
                                        company: companyInfo!),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        GridView.count(
                          crossAxisCount: 1,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                              left: 120.w, right: 120.w, top: 35.h, bottom: 40.h),
                          mainAxisSpacing: 30,
                          crossAxisSpacing: 30,
                          children: [
                            buildServiceCard(
                              context,
                              svgPath: 'assets/images/pending_status.svg',
                              label: 'Trạng thái chờ duyệt',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceUpdateListPage(
                                        companyId: companyInfo!.companyId!),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                      ],
                    )),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget buildServiceCard(
    BuildContext context, {
    required String svgPath,
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
              splashColor: Colors.blue.withValues(alpha: 0.2),
              highlightColor: Colors.blue.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      svgPath,
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(height: 8),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.sp),
                        textAlign: TextAlign.center),
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
                splashColor: Colors.blue.withValues(alpha: 0.2),
                highlightColor: Colors.blue.withValues(alpha: 0.1),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        svgPath,
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
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
