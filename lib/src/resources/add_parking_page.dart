import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class GuiXeScreen extends StatefulWidget {
  const GuiXeScreen({super.key});

  @override
  State<GuiXeScreen> createState() => _GuiXeScreenState();
}

class _GuiXeScreenState extends State<GuiXeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleType;
  String _licensePlate = '';
  bool _showRegistrationForm = false; // Thêm state này để điều khiển việc hiển thị form

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

      LoadingDialog.hideLoadingDialog(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("✅ Đăng ký xe thành công")));
      Navigator.pop(context);
    } catch (e) {
      Navigator.of(context).pop(); // Đóng loading dialog
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("✅ Hủy đăng ký thành công")));
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
                    left: 15.w,
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
                          if (!snapshot.hasData) return Text("Không có hợp đồng hiện tại.");
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
                                height: 300.h,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: docs.length,
                                  itemBuilder: (_, index) {
                                    final doc = docs[index];
                                    final canceled = doc['canceledAt'] != null;
                                    final vehicleType = doc['vehicleType'];
                                    final licensePlate = doc['licensePlate'];
                                    final registeredAt = doc['registeredAt'] as Timestamp?;
                                    final formattedDate = registeredAt != null
                                        ? DateFormat('dd/MM/yyyy – HH:mm').format(registeredAt.toDate())
                                        : 'Không rõ ngày';

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
                                      subtitle: Text("Loại: $readableType\nNgày đăng ký: $formattedDate"),
                                      isThreeLine: true,
                                      trailing: canceled
                                          ? Text("⛔ Đã hủy", style: TextStyle(color: Colors.red))
                                          : TextButton(
                                        onPressed: () => _cancelRegistration(contractId, doc.id),
                                        child: Text("Hủy"),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Nút Đăng ký thêm xe
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showRegistrationForm = !_showRegistrationForm;
                          });
                        },
                        icon: Icon(_showRegistrationForm ? Icons.close : Icons.add),
                        label: Text(_showRegistrationForm ? "Hủy" : "Đăng ký thêm xe"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Form đăng ký xe
                      if (_showRegistrationForm)
                        Padding(padding: EdgeInsets.only(
                          left: 15.w,
                          right: 15.w,
                        ),
                            child: Form(
                              key: _formKey,
                              child: Column(children: [
                                DropdownButtonFormField2<String>(
                                  value: _vehicleType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                                  ),
                                  hint: const Text('Chọn loại phương tiện'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'motorbike_roofed',
                                      child: Text('Xe máy (có mái)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'motorbike_unroofed',
                                      child: Text('Xe máy (không mái)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'car_roofed',
                                      child: Text('Ô tô (có mái)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'car_unroofed',
                                      child: Text('Ô tô (không mái)'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _vehicleType = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Vui lòng chọn loại phương tiện' : null,
                                ),
                                SizedBox(height: 12.h),
                                TextFormField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    labelText: "Điền biển số xe",
                                    contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'Nhập biển số xe' : null,
                                  onSaved: (value) => _licensePlate = value!,
                                ),
                                SizedBox(height: 20.h),
                                ElevatedButton(
                                  onPressed: _registerVehicle,
                                  child: Text("Xác nhận đăng ký"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                )
                              ]),
                            )),
                    ],
                  ),
                )
            )
          ],
        )),
      )
    );
  }
}
