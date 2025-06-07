import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final _vehicleTypeController = StreamController<String?>.broadcast();
  final _licensePlateController = StreamController<String?>.broadcast();
  int _selectedTab = 0; // 0 = Danh sách, 1 = Đăng ký

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

  Future<void> _showEditDialog(
      BuildContext context,
      String contractId,
      String docId,
      String currentPlate,
      String currentType,
      ) async {
    final _plateController = TextEditingController(text: currentPlate);
    String selectedType = currentType;
    final _errorController = StreamController<String?>(); // 👈 Cần khai báo tại đây

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Center(
                child: Text(
                  "Chỉnh sửa thông tin xe",
                  style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold),
                )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _plateController,
                  decoration: InputDecoration(labelText: "Biển số xe"),
                ),
                SizedBox(height: 10.h),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: [
                    DropdownMenuItem(value: 'car_roofed', child: Text('Ô tô (có mái che)')),
                    DropdownMenuItem(value: 'car_unroofed', child: Text('Ô tô (không mái che)')),
                    DropdownMenuItem(value: 'motorbike_roofed', child: Text('Xe máy (có mái che)')),
                    DropdownMenuItem(value: 'motorbike_unroofed', child: Text('Xe máy (không mái che)')),
                    DropdownMenuItem(value: 'bike_roofed', child: Text('Xe đạp (có mái che)')),
                    DropdownMenuItem(value: 'bike_unroofed', child: Text('Xe đạp (không mái che)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                  decoration: InputDecoration(labelText: "Loại xe"),
                ),
                StreamBuilder<String?>(
                  stream: _errorController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          snapshot.data!,
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _errorController.close();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text("Hủy", style: TextStyle(fontSize: 15.sp)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedPlate = _plateController.text.trim();
                  if (updatedPlate.isEmpty) {
                    _errorController.add("Vui lòng nhập biển số xe");
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('contracts')
                        .doc(contractId)
                        .collection('parkingRegistrations')
                        .doc(docId)
                        .update({
                      'licensePlate': updatedPlate,
                      'vehicleType': selectedType,
                    });

                    _errorController.close();
                    Navigator.pop(context);
                  } catch (e) {
                    _errorController.add("Lỗi khi cập nhật: $e");
                  }
                },
                child: Text("Lưu", style: TextStyle(fontSize: 15.sp)),
              ),
            ],
          );
        });
      },
    );

    _errorController.close(); // 👈 Đảm bảo luôn đóng sau khi showDialog kết thúc
  }

  Widget _buildRegisteredList(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getContractId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200.h,
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (_, __) => _buildShimmerListItem(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(
              "Chưa có danh sách xe",
              style: TextStyle(fontSize: 25.sp),
            ),
          );
        }

        final contractId = snapshot.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('contracts')
              .doc(contractId)
              .collection('parkingRegistrations')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  "Chưa có xe nào được đăng ký",
                  style: TextStyle(fontSize: 18.sp),
                ),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  child: ListTile(
                    title: Text("$emoji $licensePlate"),
                    subtitle: Text(
                      "Loại: $readableType\n"
                          "Ngày đăng ký: $formattedDate"
                          "${canceled ? '\nNgày hủy: $formattedCanceledDate' : ''}",
                    ),
                    isThreeLine: true,
                    trailing: canceled
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        Text(
                          "Đã hủy",
                          style: TextStyle(color: Colors.red, fontSize: 13.sp),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Chỉnh sửa',
                          onPressed: () {
                            _showEditDialog(
                              context,
                              contractId,
                              doc.id,
                              licensePlate,
                              vehicleType,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Hủy đăng ký',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: Center(
                                  child: Text(
                                    "Xác nhận hủy",
                                    style: TextStyle(
                                        fontSize: 30.sp, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                content: Text(
                                  "Bạn có chắc chắn muốn hủy đăng ký xe này không?",
                                  style: TextStyle(fontSize: 15.sp),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                                    child: Text("Không", style: TextStyle(fontSize: 15.sp)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _cancelRegistration(contractId, doc.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: Text("Hủy đăng ký",
                                        style:
                                        TextStyle(fontSize: 15.sp, color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVehicleRegistrationForm(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),
              StreamBuilder<String?>(
                stream: _vehicleTypeController.stream,
                builder: (context, snapshot) {
                  return DropdownButtonFormField2<String>(
                    value: _vehicleType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                      errorText: snapshot.hasError ? snapshot.error as String : null,
                    ),
                    hint: Text('Chọn loại phương tiện', style: TextStyle(fontSize: 15.sp)),
                    items: const [
                      DropdownMenuItem(value: 'motorbike_roofed', child: Text('Xe máy (có mái)')),
                      DropdownMenuItem(value: 'motorbike_unroofed', child: Text('Xe máy (không mái)')),
                      DropdownMenuItem(value: 'car_roofed', child: Text('Ô tô (có mái)')),
                      DropdownMenuItem(value: 'car_unroofed', child: Text('Ô tô (không mái)')),
                      DropdownMenuItem(value: 'bike_roofed', child: Text('Xe đạp (có mái)')),
                      DropdownMenuItem(value: 'bike_unroofed', child: Text('Xe đạp (không mái)')),
                    ],
                    onChanged: (value) {
                      _vehicleType = value;
                      if (_vehicleType == null) {
                        _vehicleTypeController.sink.addError('Vui lòng chọn loại phương tiện');
                      } else {
                        _vehicleTypeController.sink.add(null);
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 50.h),
              StreamBuilder<String?>(
                stream: _licensePlateController.stream,
                builder: (context, snapshot) {
                  return TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      labelText: "Điền biển số xe",
                      labelStyle: TextStyle(fontSize: 15.sp),
                      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                      errorText: snapshot.hasError ? snapshot.error as String : null,
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _licensePlateController.sink.addError('Nhập biển số xe');
                      } else {
                        _licensePlateController.sink.add(null);
                        _licensePlate = value;
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 50.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      // reset dữ liệu nếu cần
                      _vehicleType = null;
                      _licensePlate = "";
                      _vehicleTypeController.sink.add(null);
                      _licensePlateController.sink.add(null);
                    },
                    child: Text("Hủy", style: TextStyle(fontSize: 15.sp)),
                  ),),
                  SizedBox(width: 8.w),
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      bool valid = true;

                      if (_vehicleType == null) {
                        _vehicleTypeController.sink.addError('Vui lòng chọn loại phương tiện');
                        valid = false;
                      }

                      if (_licensePlate == null || _licensePlate!.trim().isEmpty) {
                        _licensePlateController.sink.addError('Nhập biển số xe');
                        valid = false;
                      }

                      if (valid) {
                        _registerVehicle(); // Gọi hàm xử lý đăng ký xe
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Xác nhận", style: TextStyle(fontSize: 15.sp, color: Colors.white)),
                  ),),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context,String text, int index, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15.sp
            ),
          ),
        ),
      ),
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

  @override
  void dispose() {
    _vehicleTypeController.close();
    _licensePlateController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = (int index) => _selectedTab == index;

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus(); // Thoát khỏi focus (ẩn bàn phím)
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Gửi xe',
            style: TextStyle(
              color: Colors.white,
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 25.sp,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // === Tab Buttons ===
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabButton(context,"Đăng ký mới", 0, isSelected(0)),
                    SizedBox(width: 12.w),
                    _buildTabButton(context,"Danh sách", 1,isSelected(1)),
                  ],
                ),
              ),

              // === Tab Content ===
              Expanded(
                  child: Padding(padding: EdgeInsets.all(12.w),
                    child: _selectedTab == 0
                        ? _buildVehicleRegistrationForm(context)
                        : _buildRegisteredList(context))
              ),
            ],
          ),
        ),
      ),
    );
  }
}
