import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shimmer/shimmer.dart';

class GuiXeScreen extends StatefulWidget {
  const GuiXeScreen({super.key});

  @override
  State<GuiXeScreen> createState() => _GuiXeScreenState();
}

class _GuiXeScreenState extends State<GuiXeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleType;
  String _licensePlate = '';

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,style: TextStyle(fontSize: 15.sp),),
        backgroundColor: Colors.green,  // Màu nền xanh
      ),
    );
  }

  Future<void> _registerVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    LoadingDialog.showLoadingDialog(context,"Đang tải ...");

    try {
      // Lấy thông tin cư dân
      final residentDoc = await FirebaseFirestore.instance
          .collection('residents')
          .doc(userId)
          .get();
      if (!residentDoc.exists) throw 'Không tìm thấy cư dân';

      final apartmentId = residentDoc['apartmentId'];

      // Lấy căn hộ
      final apartmentDoc = await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .get();
      if (!apartmentDoc.exists) throw 'Không tìm thấy căn hộ';

      final contractId = apartmentDoc['currentContractId'];
      if (contractId == null) throw 'Căn hộ chưa có hợp đồng';

      // Kiểm tra hợp đồng còn hiệu lực
      final contractDoc = await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .get();
      if (!contractDoc.exists || !(contractDoc['isActive'] ?? false)) {
        throw 'Hợp đồng không hợp lệ';
      }

      // Đăng ký xe
      final regRef = FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('parkingRegistrations')
          .doc();

      await regRef.set({
        'vehicleType': _vehicleType,
        'licensePlate': _licensePlate,
        'registeredAt': Timestamp.now(),
        'canceledAt': null,
      });

      Navigator.of(context, rootNavigator: true).pop(); // Đóng loading dialog
      Navigator.of(context, rootNavigator: true).pop(); // Đóng loading dialog

      showSnackBar("✅ Đăng ký xe thành công");
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Đóng loading dialog nếu có lỗi
      print('❌ Lỗi: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Đăng ký thất bại")));
    }
  }

  Future<void> _cancelRegistration(String contractId, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('contracts')
          .doc(contractId)
          .collection('parkingRegistrations')
          .doc(docId)
          .update({'canceledAt': Timestamp.now()});
      showSnackBar("✅ Hủy đăng ký thành công");
      setState(() {}); // Refresh
    } catch (e) {
      print('❌ Lỗi khi hủy đăng ký: $e');
    }
  }

  Future<String?> _getContractId() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final residentDoc = await FirebaseFirestore.instance
        .collection('residents')
        .doc(userId)
        .get();
    if (!residentDoc.exists) return null;

    final apartmentId = residentDoc['apartmentId'];

    final apartmentDoc = await FirebaseFirestore.instance
        .collection('apartments')
        .doc(apartmentId)
        .get();
    if (!apartmentDoc.exists) return null;

    final contractId = apartmentDoc['currentContractId'];
    if (contractId == null) return null;

    final contractDoc = await FirebaseFirestore.instance
        .collection('contracts')
        .doc(contractId)
        .get();
    return (contractDoc.exists && contractDoc['isActive'] == true)
        ? contractId
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(bottom: true, top: true, child: Stack(
          children: [
            Positioned(child: Image.asset('assets/images/two_circle.png',width: 160,),
            ),
            SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: 20.w,
                    right: 15.w,
                    top: 140.h
                ),
                child: Padding(
                  padding: EdgeInsets.only(left:2.w,bottom: 10.h ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/parking.svg',
                            width: 45.w,
                            height: 45.h,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Gửi xe',
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontWeight: FontWeight.w700,
                              fontSize: 45.sp,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Danh sách xe đã đăng ký
                      FutureBuilder<String?>(
                        future: _getContractId(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            // Khi đang load Future, hiện shimmer
                            return SizedBox(
                              height: 200.h,
                              child: ListView.builder(
                                itemCount: 3,
                                itemBuilder: (_, __) => _buildShimmerListItem(),
                              ),
                            );
                          }
                          if (!snapshot.hasData) return Text("Chưa có danh sách xe",style: TextStyle(fontSize: 25.sp),);
                          final contractId = snapshot.data!;
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('contracts')
                                .doc(contractId)
                                .collection('parkingRegistrations')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return CircularProgressIndicator();
                              final docs = snapshot.data!.docs;
                              return SizedBox(
                                height: 450.h,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: docs.length,
                                  itemBuilder: (_, index) {
                                    final doc = docs[index];
                                    final canceled = doc['canceledAt'] != null;
                                    final canceledAt = doc['canceledAt'] as Timestamp?;
                                    final vehicleType = doc['vehicleType'];
                                    final licensePlate = doc['licensePlate'];
                                    final registeredAt = doc['registeredAt'] as Timestamp?;
                                    final formattedDate = registeredAt != null
                                        ? DateFormat('dd/MM/yyyy – HH:mm').format(registeredAt.toDate())
                                        : 'Không rõ ngày';
                                    final formattedCanceledDate = canceledAt != null
                                        ? DateFormat('dd/MM/yyyy – HH:mm').format(canceledAt.toDate())
                                        : '';

                                    // Gán biểu tượng và tên tiếng Việt
                                    String emoji;
                                    String readableType;
                                    switch (vehicleType) {
                                      case 'car_roofed':
                                        emoji = '🚗';
                                        readableType = 'Ô tô (có mái che)';
                                        break;
                                      case 'car_unroofed':
                                        emoji = '🚗';
                                        readableType = 'Ô tô (không mái che)';
                                        break;
                                      case 'motorbike_roofed':
                                        emoji = '🛵';
                                        readableType = 'Xe máy (có mái che)';
                                        break;
                                      case 'motorbike_unroofed':
                                        emoji = '🛵';
                                        readableType = 'Xe máy (không mái che)';
                                        break;
                                      case 'bike_roofed':
                                        emoji = '🚲';
                                        readableType = 'Xe đạp (có mái che)';
                                        break;
                                      case 'bike_unroofed':
                                        emoji = '🚲';
                                        readableType = 'Xe đạp (không mái che)';
                                        break;
                                      default:
                                        emoji = '❓';
                                        readableType = 'Không xác định';
                                    }

                                    return ListTile(
                                      title: Text("$emoji $licensePlate"),
                                      subtitle: Text(
                                        "Loại: $readableType\n"
                                            "Ngày đăng ký: $formattedDate"
                                            "${canceledAt != null ? '\nNgày hủy: $formattedCanceledDate' : ''}",
                                      ),
                                      isThreeLine: true,
                                      trailing: canceled
                                          ? Text(
                                        "     ⛔\nĐã hủy",
                                        style: TextStyle(color: Colors.red, fontSize: 15.sp),
                                      )
                                          : TextButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Center(
                                                child: Text(
                                                  "Xác nhận hủy",
                                                  style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold, fontFamily: "Oswald"),
                                                ),
                                              ),
                                              content: Text(
                                                "Bạn có chắc chắn muốn hủy đăng ký xe này không?",
                                                style: TextStyle(fontSize: 15.sp),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text("Không", style: TextStyle(fontSize: 15.sp)),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _cancelRegistration(contractId, doc.id);
                                                  },
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  child: Text("Hủy đăng ký", style: TextStyle(fontSize: 15.sp, color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: Text("Hủy", style: TextStyle(fontSize: 15.sp)),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(width: 1.w,),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context), child: Text("Quay lại", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),),),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => _buildVehicleRegistrationDialog(dialogContext),
                              );
                            },
                            icon: Icon(Icons.add),
                            label: Text("Đăng ký xe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          SizedBox(width: 1.w,),
                        ],
                      )

                    ],
                  ),
                )
            )
          ],
        )),
      )
    );
  }

  Widget _buildVehicleRegistrationDialog(BuildContext dialogContext) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(child: Text("Đăng ký thêm xe", style:TextStyle(fontFamily:"Oswald", fontSize: 30.sp, fontWeight: FontWeight.bold)),),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField2<String>(
                value: _vehicleType,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                ),
                hint: Text('Chọn loại phương tiện',style: TextStyle(fontSize: 15.sp)),
                items: const [
                  DropdownMenuItem(value: 'motorbike_roofed', child: Text('Xe máy (có mái)')),
                  DropdownMenuItem(value: 'motorbike_unroofed', child: Text('Xe máy (không mái)')),
                  DropdownMenuItem(value: 'car_roofed', child: Text('Ô tô (có mái)')),
                  DropdownMenuItem(value: 'car_unroofed', child: Text('Ô tô (không mái)')),
                  DropdownMenuItem(value: 'bike_roofed', child: Text('Xe đạp (có mái)')),
                  DropdownMenuItem(value: 'bike_unroofed', child: Text('Xe đạp (không mái)')),
                ],
                onChanged: (value) => setState(() => _vehicleType = value),
                validator: (value) => value == null ? 'Vui lòng chọn loại phương tiện' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  labelText: "Điền biển số xe",
                  labelStyle: TextStyle(fontSize: 15.sp),
                  contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nhập biển số xe' : null,
                onSaved: (value) => _licensePlate = value!,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text("Hủy",style: TextStyle(fontSize: 15.sp),),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              _registerVehicle();     // xử lý đăng ký
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text("Xác nhận",style: TextStyle(fontSize: 15.sp,color: Colors.white),),
        ),
      ],
    );
  }

  Widget _buildShimmerListItem() {
    return ListTile(
      title: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(height: 20.h, width: 150.w, color: Colors.white),
      ),
      subtitle: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(height: 14.h, width: 200.w, color: Colors.white),
      ),
      trailing: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(height: 30.h, width: 50.w, color: Colors.white),
      ),
    );
  }

}
