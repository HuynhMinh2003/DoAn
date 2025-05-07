import 'dart:html' as html;import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:do_an/src/resources/chon_can_ho_page.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:docx_template/docx_template.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class ContractReviewPage extends StatefulWidget {
  final ContractData contractData;

  ContractReviewPage({required this.contractData});

  @override
  State<ContractReviewPage> createState() => _ContractReviewPageState();
}

class _ContractReviewPageState extends State<ContractReviewPage> {
  String? selectedRep;

  // Hàm format tiền VND: ví dụ 10000000 -> "10.000.000"
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);

// Hàm format ngày: ví dụ DateTime(2025, 5, 4) -> "ngày 04 tháng 05 năm 2025"
  String formatCustomDate(DateTime date) {
    return 'ngày ${date.day.toString().padLeft(2, '0')} tháng ${date.month.toString().padLeft(2, '0')} năm ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    final residents = widget.contractData.residents;
    if (residents.isNotEmpty) {
      selectedRep = residents.first.fullName;
    }
  }

  Future<String> generateRandomPassword() async {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final representativeNames = widget.contractData.residents.map((r) =>
    r.fullName).toList();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final String start = dateFormat.format(widget.contractData.startDate);
    final String end = widget.contractData.endDate != null
        ? dateFormat.format(widget.contractData.endDate!)
        : '∞';

    final rentPrice = widget.contractData.rentPrice;
    final formattedrentPrice = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '', // nếu muốn bỏ ký hiệu "₫"
      decimalDigits: 0,
    ).format(rentPrice);

    final salePrice = widget.contractData.salePrice;
    final formattedsalePrice = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '', // nếu muốn bỏ ký hiệu "₫"
      decimalDigits: 0,
    ).format(salePrice);

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
                      padding: EdgeInsets.only(
                          left: 30.w, right: 30.w, top: 170.h),
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
                                  Center(child: Text('Xác nhận hợp đồng',
                                    style: TextStyle(fontFamily: "Oswald",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp),),),
                                  SizedBox(height: 5.h),
                                  Text("Tòa: ${widget.contractData.building}",
                                      style: TextStyle(fontSize: 5.sp)),
                                  SizedBox(height: 25.h),
                                  Text("Căn hộ: ${widget.contractData
                                      .apartmentName}", style: TextStyle(
                                      fontSize: 5.sp)),
                                  SizedBox(height: 25.h),
                                  Text("Diện tích: ${widget.contractData
                                      .area} m²", style: TextStyle(
                                      fontSize: 5.sp)),
                                  SizedBox(height: 25.h),
                                  Text("Loại hợp đồng: ${widget.contractData
                                      .contractType}", style: TextStyle(
                                      fontSize: 5.sp)),
                                  SizedBox(height: 25.h),
                                  Text("${widget.contractData.contractType ==
                                      'thuê'
                                      ? "Giá thuê: $formattedrentPrice VNĐ /tháng"
                                      : "Giá mua: $formattedsalePrice VNĐ"}",
                                    style: TextStyle(fontSize: 5.sp),),
                                  SizedBox(height: 25.h),
                                  Text(
                                    "Thời gian: $start - $end",
                                    style: TextStyle(fontSize: 5.sp),
                                  ),
                                  SizedBox(height: 25.h),
                                  Text("Số người ở: ${widget.contractData
                                      .numberOfResidents}", style: TextStyle(
                                      fontSize: 5.sp)),
                                  SizedBox(height: 25.h),
                                  Row(children: [
                                    Text("Người đại diện: ",
                                        style: TextStyle(fontSize: 5.sp)),
                                    SizedBox(width: 10.w,),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton2<String>(
                                        isExpanded: true,
                                        hint: Text(
                                          'Chọn người đại diện',
                                          style: TextStyle(fontSize: 5.sp,
                                              color: Colors.grey[600]),
                                        ),
                                        value: representativeNames.contains(
                                            selectedRep) ? selectedRep : null,
                                        items: representativeNames.map(
                                              (e) =>
                                              DropdownMenuItem<String>(
                                                value: e,
                                                child: Text(e, style: TextStyle(
                                                    fontSize: 4.5.sp)),
                                              ),
                                        ).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedRep = value!;
                                          });
                                        },
                                        buttonStyleData: ButtonStyleData(
                                          height: 40.h,
                                          width: 80.w,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                14.r),
                                            color: const Color(0xFFF7FEFF),
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 0.1.w,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6.w),
                                        ),
                                        iconStyleData: IconStyleData(
                                          icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.black54),
                                          iconSize: 4.5.sp,
                                        ),
                                        dropdownStyleData: DropdownStyleData(
                                          maxHeight: 150.h,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                14.r),
                                            color: const Color(0xFFF7FEFF),
                                          ),
                                        ),
                                        menuItemStyleData: MenuItemStyleData(
                                          height: 40.h,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 6.w),
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
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.grey),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius
                                                    .circular(30.r),
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
                                              // Hiển thị dialog loading
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) {
                                                  return Center(
                                                    child: CircularProgressIndicator(),
                                                  );
                                                },
                                              );

                                              try {
                                                // Lưu hợp đồng vào Firestore
                                                await saveToFirestore(widget.contractData, selectedRep!, context);

                                                await Future.delayed(Duration(seconds: 3));

                                                // Đánh dấu là hợp đồng đã được tạo
                                                Provider.of<ContractNotifier>(context, listen: false).markAsCreated();

                                                // Đóng dialog
                                                Navigator.of(context).pop();

                                                Navigator.pushNamedAndRemoveUntil(
                                                  context,
                                                  '/apartmentFilterPage',
                                                      (route) => false,  // Điều này sẽ xóa tất cả các route trước đó, bao gồm cả contractreviewPage.
                                                );

                                              } catch (e) {
                                                // Xử lý lỗi nếu có
                                                print("Lỗi: $e");
                                                Navigator.of(context).pop(); // Đảm bảo đóng dialog khi có lỗi
                                              }
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

  Future<void> saveToFirestore(ContractData contract, String representative, BuildContext context) async {
    final apartmentRef = FirebaseFirestore.instance.collection("apartments")
        .doc(contract.apartmentDocId);
    final contractDoc = apartmentRef.collection("contracts").doc();

    // Gửi yêu cầu tạo tài khoản cho từng cư dân
    for (final resident in contract.residents) {
      try {
        final response = await http.post(
          Uri.parse('https://createresidentaccount-ttrkrlo35a-uc.a.run.app'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': resident.email,
            'fullName': resident.fullName,
            'cccd': resident.cccd,
            'phone': resident.phone,
            'birthDate': resident.birthDate?.toIso8601String(),
            'apartmentId': contract.apartmentDocId,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final residentId = responseData['residentId']; // Lấy residentId từ response

          // Gán lại vào resident
          resident.residentId = residentId;

          print("✅ Tạo tài khoản cho ${resident.fullName} thành công. ID: $residentId");
        } else {
          print("❌ Lỗi tạo tài khoản: ${response.body}");
          // Nếu có lỗi khi tạo tài khoản, dừng lại và không tiếp tục lưu vào Firestore
          MsgDialog.showMsgDialog(context, "Lỗi", "Tạo tài khoản thất bại");
          return;
        }
      } catch (e) {
        print("❌ Lỗi tạo tài khoản cho ${resident.fullName}: $e");
        // Nếu có lỗi khi gửi yêu cầu, dừng lại và không tiếp tục lưu vào Firestore
        MsgDialog.showMsgDialog(context, "Lỗi", "Tạo tài khoản thất bại");
        return;
      }
    }

    // Lưu hợp đồng vào Firestore
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

    // Cập nhật danh sách cư dân vào Firestore
    final residentObjects = contract.residents.map((r) => {
      'fullName': r.fullName,
      'id': r.residentId, // Lưu ID của cư dân
    }).toList();

    await apartmentRef.update({
      contract.contractType == "thuê" ? "isRent" : "isSale": true,
      "residents": FieldValue.arrayUnion(residentObjects),
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

    // Lấy template hợp đồng
    final templateData = await rootBundle.load(contract.contractType == 'thuê'
        ? 'assets/templates/hd_thue_ch.docx'
        : 'assets/templates/hd_mua_ch.docx');
    print("✅ Đã tải template DOCX");

    // Tạo DocxTemplate từ template đã tải
    final docx = await DocxTemplate.fromBytes(templateData.buffer.asUint8List());
    print("✅ Đã tạo DocxTemplate");

    final content = Content();
    print("✅ Bắt đầu tạo nội dung");

    // Thêm thông tin chính vào contract
    content
      ..add(TextContent("apartment_name", contract.apartmentName))
      ..add(TextContent("building", contract.building))
      ..add(TextContent("area", contract.area.toString()))
      ..add(TextContent("price", currencyFormat.format(contract.contractType == "thuê" ? contract.rentPrice : contract.salePrice)))
      ..add(TextContent("start_date", formatCustomDate(contract.startDate)))
      ..add(TextContent("representative", representative))
      ..add(TextContent("end_date", contract.endDate != null ? formatCustomDate(contract.endDate!) : ""));

    print("✅ Đã thêm thông tin chính");

    // === Danh sách cư dân ===
    final residentsList = <PlainContent>[];

    for (final r in List<ResidentInfo>.from(contract.residents)) {
      final residentContent = PlainContent("residents")
        ..add(TextContent("resident_name", "Họ và tên: " + r.fullName))
        ..add(TextContent("resident_cccd", "Số CCCD: " + r.cccd))
        ..add(TextContent("resident_phone", "Số điện thoại: " + r.phone));

      residentsList.add(residentContent);
    }

    // residents là tag list, resident là mỗi item trong list
    content.add(ListContent("residents", residentsList));

    final fileBytes = await docx.generate(content);
    print("Đã tạo file bytes từ DocxTemplate");

    // Kiểm tra fileBytes có hợp lệ không
    if (fileBytes == null) {
      print("Lỗi: Không thể tạo file bytes.");
    } else {
      print("File bytes hợp lệ.");
    }

    // Tạo file Word
    final fileName = "${contract.contractType}_${contract.apartmentName}_${DateTime.now().millisecondsSinceEpoch}.docx";
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    print("✅ File Word đã được tải về: $fileName");

    MsgDialog.showMsgDialog(context, "Chúc mừng", "Tạo tài khoản thành công");

  }

// Hàm hiển thị thông báo lỗi
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

}