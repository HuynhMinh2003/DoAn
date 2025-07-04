import 'package:do_an/constants.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UpdateFeeScreen extends StatefulWidget {
  @override
  _UpdateFeeScreenState createState() => _UpdateFeeScreenState();
}

class _UpdateFeeScreenState extends State<UpdateFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();
  final _dateController = TextEditingController();

  String? _feeType;
  String? _vehicleType;
  DateTime? _selectedDate;

  final Map<String, String> vehicleTypeLabels = {
    'bike_roofed': 'Xe đạp có mái che',
    'bike_unroofed': 'Xe đạp không mái che',
    'motobike_roofed': 'Xe máy có mái che',
    'motorbike_unroofed': 'Xe máy không mái che',
    'car_roofed': 'Ô tô có mái che',
    'car_unroofed': 'Ô tô không mái che',
  };

  Future<void> _saveFee() async {
    if (!_formKey.currentState!.validate()) return;

    final feeValue = int.parse(_feeController.text);
    LoadingDialog.showLoadingDialog(context, 'Đang tải ...');

    try {
      if (_feeType == 'managementFee') {
        await FirebaseFirestore.instance
            .collection('services')
            .doc('managementFee')
            .collection('feeHistory')
            .add({
          'feePerM2': feeValue,
          'effectiveFrom': _selectedDate,
        });
      } else if (_feeType == 'parking' && _vehicleType != null) {
        await FirebaseFirestore.instance
            .collection('services')
            .doc('parking')
            .collection('vehicleTypes')
            .doc(_vehicleType!)
            .collection('feeHistory')
            .add({
          'fee': feeValue,
          'effectiveFrom': _selectedDate,
        });
      }

      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, 'Giá dịch vụ', 'Cập nhật giá thành công');
      _feeController.clear();
      _dateController.clear();
      setState(() {
        _selectedDate = null;
        _feeType = null;
        _vehicleType = null;
      });
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, 'Giá dịch vụ', 'Cập nhật giá thất bại');
    }
  }

  @override
  void dispose() {
    _feeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            'Cập nhật giá dịch vụ',
                            style: TextStyle(
                              fontFamily: "Oswald",
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 50.h),
                          DropdownButtonFormField2<String>(
                            value: _feeType,
                            decoration: _inputDecoration(hint: 'Chọn loại phí'),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'managementFee',
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w), // 👈 cùng giá trị với `InputDecoration.contentPadding`
                                  child: Text(
                                    'Phí quản lý vận hành',
                                    style: TextStyle(fontSize: 4.5.sp, color: Colors.white),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'parking',
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w), // 👈 như trên
                                  child: Text(
                                    'Phí gửi xe',
                                    style: TextStyle(fontSize: 4.5.sp, color: Colors.white),
                                  ),
                                ),
                              ),

                            ],
                            onChanged: (val) {
                              setState(() {
                                _feeType = val!;
                                _vehicleType = null;
                              });
                            },
                            validator: (val) =>
                            val == null ? 'Vui lòng chọn loại phí' : null,
                          ),
                          SizedBox(height: 60.h),
                          if (_feeType == 'parking') ...[
                            DropdownButtonFormField2<String>(
                              value: _vehicleType,
                              decoration:
                              _inputDecoration(hint: 'Chọn loại phương tiện'),
                              isExpanded: true,
                              items: vehicleTypeLabels.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _vehicleType = val!;
                                });
                              },
                              validator: (val) =>
                              val == null ? 'Chọn loại phương tiện' : null,
                            ),
                            SizedBox(height: 60.h),
                          ],

                          TextFormField(
                            controller: _feeController,
                            decoration: _inputDecoration(hint: 'Nhập giá phí (VNĐ)'),
                            keyboardType: TextInputType.number,
                            validator: (val) =>
                            val == null || val.isEmpty ? 'Nhập phí' : null,
                          ),
                          SizedBox(height: 60.h),
                          TextFormField(
                            readOnly: true,
                            controller: _dateController,
                            decoration: _inputDecoration(
                              hint: 'Chọn ngày hiệu lực',
                            ).copyWith(
                              suffixIcon: Icon(Icons.calendar_today, size: 20),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(), // Chỉ cho chọn từ hôm nay trở đi
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                  _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                                });
                              }
                            },
                            validator: (val) =>
                            _selectedDate == null ? 'Vui lòng chọn ngày hiệu lực' : null,
                          ),
                          SizedBox(height: 60.h),
                          Center(
                            child: SizedBox(
                              height: 60.h,
                              width: 60.w,
                              child: ElevatedButton(
                                onPressed: () {
                                  _saveFee();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor, // Màu xanh dương sáng
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black45,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  "Lưu giá dịch vụ",
                                  style: TextStyle(
                                    fontFamily: "Oswald",
                                    fontWeight: FontWeight.w700,
                                    fontSize: 7.sp,
                                    color: Colors.white, // Màu chữ trắng
                                    height: 1.h,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white,
        fontSize: 5.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey),
      ),
    );
  }
}
