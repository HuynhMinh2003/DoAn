import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:do_an/src/resources/contract_review_page.dart';
import 'package:do_an/src/blocs/auth_bloc.dart'; // Nhớ import bloc
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ResidentInfoPage extends StatefulWidget {
  final ContractData contractData;

  ResidentInfoPage({required this.contractData});

  @override
  _ResidentInfoPageState createState() => _ResidentInfoPageState();
}

class _ResidentInfoPageState extends State<ResidentInfoPage> {
  final authBloc = AuthBloc(); // Tạo hoặc lấy từ Provider nếu dùng DI

  final _nameResidentController = TextEditingController();
  final _cccdResidentController = TextEditingController();
  final _phoneResidentController = TextEditingController();
  final _emailResidentController = TextEditingController();
  DateTime? birthDate;

  List<ResidentInfo> residents = [];
  int currentIndex = 0;

  @override
  void dispose() {
    _nameResidentController.dispose();
    _cccdResidentController.dispose();
    _phoneResidentController.dispose();
    _emailResidentController.dispose();
    authBloc.dispose(); // Quan trọng: tránh rò rỉ stream
    super.dispose();
  }

  void nextResident() {
    final isValid = authBloc.isValidResidentSignUp(
      _nameResidentController.text,
      _emailResidentController.text,
      _phoneResidentController.text,
      _cccdResidentController.text,
      birthDate,
    );

    if (!isValid) return;

    final newResident = ResidentInfo(
      fullName: _nameResidentController.text,
      cccd: _cccdResidentController.text,
      phone: _phoneResidentController.text,
      email: _emailResidentController.text,
      birthDate: birthDate!,
    );

    // Ghi đè nếu đã có dữ liệu ở vị trí này
    if (residents.length > currentIndex) {
      residents[currentIndex] = newResident;
    } else {
      residents.add(newResident);
    }

    if (currentIndex < widget.contractData.numberOfResidents - 1) {
      setState(() {
        currentIndex++;
        if (residents.length > currentIndex) {
          final r = residents[currentIndex];
          _nameResidentController.text = r.fullName;
          _cccdResidentController.text = r.cccd;
          _phoneResidentController.text = r.phone;
          _emailResidentController.text = r.email;
          birthDate = r.birthDate;
        } else {
          _nameResidentController.clear();
          _cccdResidentController.clear();
          _phoneResidentController.clear();
          _emailResidentController.clear();
          birthDate = null;
        }
      });
    } else {
      final updatedContract = widget.contractData.copyWith(residents: residents);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContractReviewPage(contractData: updatedContract),
        ),
      );
    }

  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
    required VoidCallback clearError, // 👉 Thêm hàm để clear lỗi
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 15.h),
      child: StreamBuilder<String>(
        stream: stream,
        builder: (context, snapshot) {
          return TextField(
            controller: controller,
            style: TextStyle(fontSize: 4.sp, color: Colors.black),
            onChanged: (value) {
              clearError(); // 👉 Clear lỗi khi người dùng sửa
            },
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: 4.sp),
              errorText: snapshot.hasError ? snapshot.error as String : null,
              errorStyle: TextStyle(fontSize: 3.sp, color: Colors.red),
              helperText: snapshot.hasError ? null : ' ',
              // giữ chỗ dòng lỗi
              contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xffCED0D2), width: 1.w),
                borderRadius: BorderRadius.all(Radius.circular(30.r)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 15.h),
      child: StreamBuilder<DateTime?>(
        stream: authBloc.birthDateStream,
        builder: (context, snapshot) {
          final hasError = snapshot.hasError;

          return SizedBox(
            height: 60.h, // đủ chỗ cho cả button + lỗi
            child: Stack(
              clipBehavior: Clip.none, // cho lỗi có thể "tràn" ra ngoài
              children: [
                SizedBox(
                  height: 50.h,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          birthDate = picked;
                          authBloc.updateBirthDate(picked);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7FEFF),
                      elevation: 0,
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                        side: BorderSide(
                          color: hasError ? Color(0xFFD32F2F) : Colors.black,
                          width: 0.17.w,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (birthDate != null)
                          Text(
                            'Ngày sinh',
                            style: TextStyle(
                              fontSize: 3.sp,
                              color: Colors.black,
                            ),
                          ),
                        Text(
                          birthDate == null
                              ? "Ngày sinh"
                              : "${birthDate!.toLocal()}".split(' ')[0],
                          style: TextStyle(
                            fontSize: 4.sp,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (hasError)
                  Positioned(
                    left: 10.w,
                    bottom: -18.h, // tràn ra ngoài một chút
                    child: Text(
                      snapshot.error as String,
                      style: TextStyle(color: Colors.red, fontSize: 3.sp),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: SafeArea(
          child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset('assets/images/two_circle.png', width: 160),
          ),
          SingleChildScrollView(
              child: Padding(
            padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 170.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 30.w, top: 30.h),
                    child: SvgPicture.asset(
                      'assets/images/info_resident.svg',
                      width: 200.w,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        "Cư dân ${currentIndex + 1}",
                        style: TextStyle(
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp),
                      ),
                      SizedBox(height: 30.h,),
                      _buildTextField(
                        controller: _nameResidentController,
                        label: "Họ tên",
                        stream: authBloc.nameResidentStream,
                        clearError: authBloc.clearNameResidentError,
                      ),
                      _buildTextField(
                        controller: _cccdResidentController,
                        label: "CCCD",
                        stream: authBloc.cccdResidentStream,
                        clearError: authBloc.clearCccdResidentError,
                      ),
                      _buildTextField(
                        controller: _phoneResidentController,
                        label: "SĐT",
                        stream: authBloc.phoneResidentStream,
                        clearError: authBloc.clearPhoneResidentError,
                      ),
                      _buildTextField(
                        controller: _emailResidentController,
                        label: "Email",
                        stream: authBloc.emailResidentStream,
                        clearError: authBloc.clearEmailResidentError,
                      ),
                      _buildDatePickerButton(),
                      SizedBox(height: 25.h),
                      Row(
                        children: [
                          SizedBox(width: 20.w),
                          if (currentIndex > 0) // Nếu có nút "Quay lại"
                            Expanded(
                              child: SizedBox(
                                height: 60.h,
                                child: OutlinedButton(
                                    onPressed: () {
                                      if (currentIndex > 0) {
                                        setState(() {
                                          currentIndex--;

                                          // Nạp lại dữ liệu từ cư dân cũ
                                          final r = residents[currentIndex];
                                          _nameResidentController.text = r.fullName;
                                          _cccdResidentController.text = r.cccd;
                                          _phoneResidentController.text = r.phone;
                                          _emailResidentController.text = r.email;
                                          birthDate = r.birthDate;
                                        });
                                      }
                                    },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                  ),
                                  child: Text(
                                    "Quay lại",
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 7.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                          // Khi không có nút "Quay lại", chiếm không gian

                          SizedBox(width: 20.w),

                          Expanded(
                            child: SizedBox(
                              height: 60.h,
                              child: ElevatedButton(
                                onPressed: () => nextResident(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D80F8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.black45,
                                ),
                                child: Text(
                                  "Tiếp tục",
                                  style: TextStyle(
                                    fontFamily: "Oswald",
                                    fontWeight: FontWeight.w700,
                                    fontSize: 7.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20.w),
                        ],
                      )

                    ],
                  ),)
              ],
            )
          ))
        ],
      )),
    );
  }
}
