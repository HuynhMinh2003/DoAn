import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/base_resident_info.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/payment_summary_screen_page.dart';
import 'package:do_an/src/resources/pdf_Viewer_Screen_page.dart';
import 'package:do_an/src/resources/provider/resident_image_provider.dart';
import 'package:do_an/src/resources/report_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../models/company_info.dart';
import 'add_parking_page.dart';
import 'company_detail_page.dart';

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
    if (residentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ResidentImageProvider>(context, listen: false)
            .loadImageByResidentId(residentId); // đúng hàm và id
      });
    }
  }

  Future<List<CompanyInfo>> fetchActiveCompanies() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('isExit', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => CompanyInfo.fromMap(doc.data()))
        .toList();
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

  Future<List<CompanyInfo>> fetchCompaniesWithEnabledUpdateService() async {
    final companyDocs = await FirebaseFirestore.instance.collection('companies').get();

    List<CompanyInfo> filteredCompanies = [];

    for (var doc in companyDocs.docs) {
      final updateServiceSnap = await doc.reference
          .collection('updateService')
          .where('status', isEqualTo: "Đã duyệt")
          .limit(1)
          .get();

      if (updateServiceSnap.docs.isNotEmpty) {
        // Lấy data công ty, giả sử có hàm fromDocument
        final company = CompanyInfo.fromFirestore(doc);
        filteredCompanies.add(company);
      }
    }

    return filteredCompanies;
  }

  Future<Map<String, dynamic>?> fetchActiveUpdateService(String companyId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('updateService')
        .where('status', isEqualTo: "Đã duyệt")
        .orderBy('timestamp', descending: true) // Sắp xếp bản mới nhất trước
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return querySnapshot.docs.first.data();
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
              child: Text('Đồng ý', style: TextStyle(fontSize: 14.sp,color: Colors.white)),
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
                color: Theme.of(context).colorScheme.primary,
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
                            child: Consumer<ResidentImageProvider>(
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

                          SizedBox(height: 5.h),
                          Text(
                            "Xin chào, ${residentInfo?.fullName ?? "người dùng"} 👋",
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontSize: 25.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '   Dịch vụ cơ bản',
                        style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold, fontFamily: "Oswald"),
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(left: 50.w, right: 50.w, top: 10.h, bottom: 10.h),
                        mainAxisSpacing: 45,
                        crossAxisSpacing: 45,
                        children: [
                          buildServiceCard(
                            context,
                            svgPath: 'assets/images/parking.svg',
                            label: 'Gửi xe',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => GuiXeScreen()));
                            },
                          ),
                          buildServiceCard(
                            context,
                            svgPath: 'assets/images/water.svg',
                            label: 'Chỉ số nước',
                            onTap: () {
                            },
                          ),
                        ],
                      ),
                      Text(
                        '   Tiện ích cư dân',
                        style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold, fontFamily: "Oswald"),
                      ),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          buildServiceCard(
                            context,
                            svgPath: 'assets/images/contract.svg',
                            label: 'Xem hợp đồng',
                            onTap: () async {
                              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                              if (currentUserId == null) return;

                              final residentSnapshot = await FirebaseFirestore.instance
                                  .collection('residents')
                                  .doc(currentUserId)
                                  .get();

                              final apartmentId = residentSnapshot.data()?['apartmentId'];
                              if (apartmentId == null) return;

                              final contractsSnapshot = await FirebaseFirestore.instance
                                  .collection('contracts')
                                  .where('apartmentDocId', isEqualTo: apartmentId)
                                  .where('isActive', isEqualTo: true)
                                  .limit(1)
                                  .get();

                              if (contractsSnapshot.docs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Không tìm thấy hợp đồng đang hoạt động')),
                                );
                                return;
                              }

                              final contractData = contractsSnapshot.docs.first.data();
                              final contractUrl = contractData['pdfUrl'];

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PdfViewerScreen(pdfUrl: contractUrl)),
                              );
                            },
                          ),
                          buildServiceCard(
                            context,
                            svgPath: 'assets/images/problem.svg',
                            label: 'Báo cáo sự cố',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ReportPage()));
                            },
                          ),
                          buildServiceCard(
                            context,
                            svgPath: 'assets/images/paycard.svg',
                            label: 'Thanh toán',
                            onTap: () {
                              final contractId = residentInfo?.contractId;
                              if (contractId != null && contractId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreen(contractId: contractId),
                                  ),
                                );
                              } else {
                                // Hiển thị thông báo nếu chưa có hợp đồng
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Không tìm thấy hợp đồng. Vui lòng liên hệ ban quản lý.")),
                                );
                              }
                            },

                          ),
                        ],
                      ),
                      Text(
                        '   Dịch vụ từ công ty ngoài',
                        style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold, fontFamily: "Oswald"),
                      ),
                      Padding(padding: EdgeInsets.only(left: 9.w, right: 9.w, top: 10.h),
                      child: FutureBuilder<List<CompanyInfo>>(
                        future: fetchCompaniesWithEnabledUpdateService(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('Không có công ty nào có dịch vụ được duyệt'));
                          }

                          final companies = snapshot.data!;

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: companies.map((company) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: buildServiceCard1(
                                    context,
                                    imagePath: company.imageUrl,
                                    label: company.type,
                                    onTap: () async {
                                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                      if (currentUserId == null) return;

                                      // Lấy thêm thông tin cư dân
                                      final residentSnapshot = await FirebaseFirestore.instance
                                          .collection('residents')
                                          .doc(currentUserId)
                                          .get();

                                      final residentData = residentSnapshot.data();
                                      if (residentData == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Không tìm thấy thông tin cư dân')),
                                        );
                                        return;
                                      }

                                      final updateService = await fetchActiveUpdateService(company.companyId ?? '');
                                      if (updateService == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Không có dịch vụ được duyệt cho công ty này.')),
                                        );
                                        return;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CompanyDetailPage(
                                            company: company,
                                            updateService: updateService,
                                            residentName: residentInfo!.fullName,
                                            apartmentNumber: apartmentName,
                                            building: building,
                                            phone: residentInfo!.phone,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                );
                              }).toList(),
                            ),
                          );
                        },
                      )
                        ,
                      )
                    ],
                  ),
                ),
              )
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      svgPath,
                      width: 50,
                      height: 50,

                    ),
                    const SizedBox(height: 8),
                    Text(label, style:TextStyle(fontWeight: FontWeight.bold,fontSize: 12.sp),textAlign: TextAlign.center),
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
        required String imagePath,
        required String label,
        required VoidCallback onTap,
      }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 100),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) => (context as Element).markNeedsBuild(),
          onTapUp: (_) => onTap(),
          child: Material(
            color: Colors.white,
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.blue.withOpacity(0.2),
              highlightColor: Colors.blue.withOpacity(0.1),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagePath,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 60,
                              height: 60,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        label,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}
