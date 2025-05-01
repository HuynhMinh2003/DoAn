import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ContractReviewPage extends StatefulWidget {
  final ContractData contractData;

  ContractReviewPage({required this.contractData});

  @override
  State<ContractReviewPage> createState() => _ContractReviewPageState();
}

class _ContractReviewPageState extends State<ContractReviewPage> {
  String? selectedRep;

  @override
  void initState() {
    super.initState();
    selectedRep = widget.contractData.residents.first.fullName;
  }

  Future<String> generateRandomPassword() async {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final representativeNames = widget.contractData.residents.map((r) => r.fullName).toList();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final String start = dateFormat.format(widget.contractData.startDate);
    final String end = widget.contractData.endDate != null
        ? dateFormat.format(widget.contractData.endDate!)
        : '∞';

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
                                'assets/images/confirm_contract.svg',
                                width: 100.w,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(child: Text('Xác nhận hợp đồng', style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.w700, fontSize: 12.sp),),),
                                SizedBox(height: 20.h),
                                Text("Căn hộ: ${widget.contractData.apartmentName}", style: TextStyle(fontSize: 6.sp)),
                                SizedBox(height: 20.h),
                                Text("Diện tích: ${widget.contractData.area} m²", style: TextStyle(fontSize: 6.sp)),
                                SizedBox(height: 20.h),
                                Text("Loại hợp đồng: ${widget.contractData.contractType}", style: TextStyle(fontSize: 6.sp)),
                                SizedBox(height: 20.h),
                                Text(
                                  "Thời gian: $start - $end",
                                  style: TextStyle(fontSize: 6.sp),
                                ),
                                SizedBox(height: 20.h),
                                Text("Số người ở: ${widget.contractData.numberOfResidents}", style: TextStyle(fontSize: 6.sp)),
                                SizedBox(height: 20.h),
                                Row(children: [
                                  Text("Người đại diện: ", style: TextStyle(fontSize: 6.sp)),
                                  SizedBox(width: 10.w,),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton2<String>(
                                      isExpanded: true,
                                      hint: Text(
                                        'Chọn người đại diện',
                                        style: TextStyle(fontSize: 5.sp, color: Colors.grey[600]),
                                      ),
                                      value: selectedRep,
                                      items: representativeNames.map(
                                            (e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Text(e, style: TextStyle(fontSize: 5.sp)),
                                        ),
                                      ).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedRep = value!;
                                        });
                                      },
                                      buttonStyleData: ButtonStyleData(
                                        height: 40.h,
                                        width: 40.w,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14.r),
                                          color: const Color(0xFFF7FEFF),
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 0.1.w,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                                      ),
                                      iconStyleData: IconStyleData(
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                                        iconSize: 5.sp,
                                      ),
                                      dropdownStyleData: DropdownStyleData(
                                        maxHeight: 150.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14.r),
                                          color: const Color(0xFFF7FEFF),
                                        ),
                                      ),
                                      menuItemStyleData: MenuItemStyleData(
                                        height: 40.h,
                                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                                      ),
                                    ),
                                  ),

                                ],),
                                SizedBox(height: 40.h),
                                Row(
                                  children: [
                                    SizedBox(width: 20.w),

                                    // Nút "Quay lại"
                                    Expanded(
                                      child: SizedBox(
                                        height: 60.h,
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(context),
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
                                    ),

                                    SizedBox(width: 20.w),

                                    // Nút "Tạo hợp đồng"
                                    Expanded(
                                      child: SizedBox(
                                        height: 60.h,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await saveToFirestore(widget.contractData, selectedRep!);
                                            Navigator.popUntil(context, (route) => route.isFirst);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2D80F8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30.r),
                                            ),
                                            elevation: 4,
                                            shadowColor: Colors.black45,
                                          ),
                                          child: Text(
                                            "Tạo hợp đồng",
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
                            ))
                        ],
                      )
                  ))
            ],
          )),
    );
  }

  Future<void> saveToFirestore(ContractData contract, String representative) async {
    final apartmentRef = FirebaseFirestore.instance.collection("apartments").doc(contract.apartmentDocId);

    // Tạo document hợp đồng mới trong subcollection "contracts" của căn hộ
    final contractDoc = apartmentRef.collection("contracts").doc();

    // Lưu thông tin hợp đồng
    await contractDoc.set({
      "apartmentDocId": contract.apartmentDocId,
      "apartmentName": contract.apartmentName,
      "building": contract.building,
      "area": contract.area,
      "price": contract.contractType == "thuê" ? contract.rentPrice : contract.salePrice,
      "type": contract.contractType,
      "startDate": contract.startDate,
      "endDate": contract.endDate,
      "representative": representative,
      "numberOfResidents": contract.numberOfResidents,
      "createdAt": Timestamp.now(),
    });

    // Lưu từng cư dân vào collection "residents"
    for (final resident in contract.residents) {
      final password = await generateRandomPassword();

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: resident.email, password: password);

        final uid = userCredential.user!.uid;

        // Lưu thêm vào collection "residents" để truy vấn dễ hơn
        await FirebaseFirestore.instance.collection("residents").doc(uid).set({
          "name": resident.fullName,
          "cccd": resident.cccd,
          "phone": resident.phone,
          "birthDate": resident.birthDate,
          "email": resident.email,
          "role": 3,
          "apartmentId": contract.apartmentDocId,
          "fcmTokens": [],
          "createdAt": Timestamp.now(),
        });

        print("Tạo tài khoản cho ${resident.fullName} - Mật khẩu: $password");

        // TODO: Gửi email qua Cloud Function nếu cần
      } catch (e) {
        print("Lỗi khi tạo user cho ${resident.fullName}: $e");
      }
    }

    // Cập nhật danh sách cư dân trong document căn hộ
    final residentNames = contract.residents.map((r) => r.fullName).toList();
    await apartmentRef.update({
      contract.contractType == "thuê" ? "isRent" : "isSale": true,
      "residents": residentNames,
    });

    // Tạo hóa đơn nước đầu tiên
    final billRef = apartmentRef.collection("billWater").doc();
    await billRef.set({
      "month": DateFormat("yyyy-MM").format(DateTime.now()),
      "oldMeterReading": 0,
      "newMeterReading": 0,
      "totalAmount": 0,
      "photoURL": "",
      "createdAt": Timestamp.now(),
    });
  }
}
