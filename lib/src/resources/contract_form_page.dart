import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:provider/provider.dart';
import 'package:pool/pool.dart';
import 'contract_form_mobile_page.dart' if (dart.library.html) 'contract_form_web_page.dart';
import 'dart:convert';
import 'package:do_an/src/models/resident_info.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:docx_template/docx_template.dart';

class ContractFormRentPage extends StatefulWidget {
  final String apartmentId;

  const ContractFormRentPage({super.key, required this.apartmentId});

  @override
  State<ContractFormRentPage> createState() => _ContractFormRentPageState();
}

class _ContractFormRentPageState extends State<ContractFormRentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? startDate;
  DateTime? endDate;
  int residentCount = 0;

  bool isLoading = false; // Trạng thái loading


  String formatCustomDate(DateTime date) {
    return 'ngày ${date.day.toString().padLeft(2, '0')} tháng ${date.month.toString().padLeft(2, '0')} năm ${date.year}';
  }

  List<ResidentInfo> residents = [];

  // Thông tin căn hộ
  String apartmentName = '';
  double area = 0;
  String building = '';
  int rentPrice = 0;

  // Các controller cho thông tin khác
  final purposeController = TextEditingController();
  final devicesController = TextEditingController();
  final limitationsController = TextEditingController();
  final benefitsController = TextEditingController();
  final commitmentController = TextEditingController();
  final dutiesController = TextEditingController();

  final residentCountController = TextEditingController();
  int? representativeIndex;

  @override
  void initState() {
    super.initState();
    fetchApartmentData();
  }

  Future<void> fetchApartmentData() async {
    final doc = await FirebaseFirestore.instance
        .collection('apartments')
        .doc(widget.apartmentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        apartmentName = data['apartmentName'];
        area = data['area']?.toDouble() ?? 0.0;
        building = data['building'];
        rentPrice = data['rentPrice'];
      });
    }
  }

  Future<void> pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        startDate = selected;
        endDate = null; // reset end date nếu có
      });
    }
  }

  Future<void> pickEndDate() async {
    if (startDate == null) return;
    final minEndDate =
    DateTime(startDate!.year, startDate!.month + 1, startDate!.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: minEndDate,
      firstDate: minEndDate,
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        endDate = selected;
      });
    }
  }

  Future<void> handleResidentInputChange() async {
    String input = residentCountController.text.trim();
    int? count = int.tryParse(input);

    if (count == null || count <= 0) {
      // Nếu người dùng xóa số hoặc nhập sai
      setState(() {
        residentCount = 0;
        residents.clear();
      });
      return;
    }

    if (count > 10) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Text('Bạn đã nhập $count người. Bạn có chắc muốn tiếp tục với số lượng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Có'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        residentCountController.clear();
        setState(() {
          residentCount = 0;
          residents.clear();
          representativeIndex = null;
        });
        return;
      }
    }

    setState(() {
      residentCount = count!;
      residents = List.generate(
        count,
            (_) => ResidentInfo(
          fullName: '',
          cccd: '',
          address: '',
          phone: '',
          gender: '',
          email: '',
        ),
      );
      representativeIndex = null;
    });
  }

  void handleSubmit() {
    if (representativeIndex == null) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('Thiếu thông tin'),
              content: Text('Vui lòng chọn một người làm đại diện.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.decimalPattern('vi');
    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      appBar: AppBar(title: Text('      Nhập thông tin hợp đồng', style: TextStyle(fontSize: 8.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),),backgroundColor: Color(0xFFF7FEFF),),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin căn hộ hiển thị sẵn
            SizedBox(height: 10.h,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60.w,
                  child: Material(
                    color: Colors.transparent, // Đảm bảo ripple hiện đúng
                    child: InkWell(
                      onTap: pickStartDate,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text('Ngày bắt đầu: ', style: TextStyle(fontSize:4.sp,fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                startDate != null
                                    ? dateFormat.format(startDate!)
                                    : 'Chưa chọn',
                                style: TextStyle(fontSize: 4.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text('-',style: TextStyle(fontSize:4.sp),),
                SizedBox(width: 8.w),
                SizedBox(
                  width: 60.w,
                  child: Material(
                    color: Colors.transparent, // Đảm bảo ripple hiện đúng
                    child: InkWell(
                      onTap: pickEndDate,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text('Ngày kết thúc: ', style: TextStyle(fontSize:4.sp,fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                endDate != null
                                    ? dateFormat.format(endDate!)
                                    : 'Chưa chọn',
                                style: TextStyle(fontSize: 4.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tên căn hộ: $apartmentName    /    ",style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),),
                Text("$building    /    ",style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
                Text("Diện tích: ${area.toStringAsFixed(1)} m²    /    ",style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
                Text(
                  "Giá thuê: ${currencyFormat.format(rentPrice)} VNĐ/tháng",
                  style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),
                )
              ],
            ),
            SizedBox(height: 30.h,),

            // Nhập số người ở
            Row(
              children: [
                Text(
                  'Số người ở:',
                  style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 35.w,
                  child: TextField(
                    controller: residentCountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'Nhập số người',
                      hintStyle: TextStyle(fontSize: 4.sp ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => handleResidentInputChange(),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h,),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: residents.length,
              itemBuilder: (_, index) {
                final resident = residents[index];

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6.h),
                  child: Padding(
                    padding: EdgeInsets.all(12.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Người thứ ${index + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 5.sp)),
                        RadioListTile<int>(
                          value: index,
                          groupValue: representativeIndex,
                          onChanged: (val) {
                            setState(() {
                              representativeIndex = val;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          title: Text('Chọn làm người đại diện',
                              style: TextStyle(fontSize: 4.sp)),
                        ),
                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Họ và tên',
                              labelStyle: TextStyle(fontSize: 4.sp)),
                          onChanged: (val) => setState(() {
                            residents[index] =
                                resident.copyWith(fullName: val);
                          }),
                        ),

                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(fontSize: 4.sp)),
                          onChanged: (val) => setState(() {
                            residents[index] = resident.copyWith(email: val);
                          }),
                        ),
                        SizedBox(height: 20.h,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, // Căn lề các item theo chiều ngang
                          children: [
                            Text('Giới tính',style: TextStyle(fontSize: 4.sp),),
                            SizedBox(width: 20.w), // Khoảng cách giữa các radio button
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Nam',
                                  groupValue: resident.gender,
                                  onChanged: (val) {
                                    setState(() {
                                      residents[index] = resident.copyWith(gender: val!);
                                    });
                                  },
                                ),
                                Text(
                                  'Nam',
                                  style: TextStyle(fontSize: 4.sp),
                                ),
                              ],
                            ),
                            SizedBox(width: 20.w), // Khoảng cách giữa các radio button
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Nữ',
                                  groupValue: resident.gender,
                                  onChanged: (val) {
                                    setState(() {
                                      residents[index] = resident.copyWith(gender: val!);
                                    });
                                  },
                                ),
                                Text(
                                  'Nữ',
                                  style: TextStyle(fontSize: 4.sp),
                                ),
                              ],
                            ),
                            SizedBox(width: 20.w), // Khoảng cách giữa các radio button
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Khác',
                                  groupValue: resident.gender,
                                  onChanged: (val) {
                                    setState(() {
                                      residents[index] = resident.copyWith(gender: val!);
                                    });
                                  },
                                ),
                                Text(
                                  'Khác',
                                  style: TextStyle(fontSize: 4.sp),
                                ),
                              ],
                            ),
                          ],
                        ),

                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Số CCCD',
                              labelStyle: TextStyle(fontSize: 4.sp)),
                          onChanged: (val) => setState(() {
                            residents[index] = resident.copyWith(cccd: val);
                          }),
                        ),

                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Địa chỉ',
                              labelStyle: TextStyle(fontSize: 4.sp)),
                          onChanged: (val) => setState(() {
                            residents[index] = resident.copyWith(address: val);
                          }),
                        ),

                        TextField(
                          decoration: InputDecoration(
                              labelText: 'Số điện thoại',
                              labelStyle: TextStyle(fontSize: 4.sp)),
                          onChanged: (val) => setState(() {
                            residents[index] = resident.copyWith(phone: val);
                          }),
                        ),

                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Text('Ngày sinh: ',
                                style: TextStyle(fontSize: 4.sp)),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: resident.birthDate ?? DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    residents[index] = resident.copyWith(
                                      birthDate: picked, // Lưu trữ DateTime
                                    );
                                  });
                                }
                              },
                              child: Text(
                                resident.birthDate != null
                                    ? '${resident.birthDate!.day}/${resident.birthDate!.month}/${resident.birthDate!.year}'
                                    : 'Chọn ngày',
                                style: TextStyle(fontSize: 4.sp, color: Colors.black),
                              )

                            ),
                          ],

                        ),

                      ],
                    ),
                  ),
                );
              },
            ),
            // Các trường nhập thông tin hợp đồng khác
            TextField(
              controller: purposeController,
              decoration: InputDecoration(labelText: 'Mục đích thuê',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 30.h,),
            TextField(
              controller: devicesController,
              decoration: InputDecoration(labelText: 'Đồ đạc, thiết bị đi kèm (nếu có)',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 30.h,),
            TextField(
              controller: limitationsController,
              decoration: InputDecoration(labelText: 'Hạn chế (nếu có)',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 30.h,),
            TextField(
              controller: benefitsController,
              decoration: InputDecoration(labelText: 'Lợi ích thỏa thuận (nếu có)',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 30.h,),
            TextField(
              controller: commitmentController,
              decoration: InputDecoration(labelText: 'Cam kết (nếu có)',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 30.h,),
            TextField(
              controller: dutiesController,
              decoration: InputDecoration(labelText: 'Nghĩa vụ thỏa thuận (nếu có)',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),

            SizedBox(height: 20.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 60.h,
                  child: ElevatedButton(
                    onPressed: () async {
                      LoadingDialog.showLoadingDialog(context,"Đang tải ...");

                      try {
                        // Đảm bảo bạn có thông tin căn hộ như apartmentId để tạo đường dẫn chính xác.
                        String apartmentId = widget.apartmentId;

                        // Lấy giá trị từ các controller
                        String purpose = purposeController.text;
                        String devices = devicesController.text;
                        String limitations = limitationsController.text;
                        String benefits = benefitsController.text;
                        String commitment = commitmentController.text;
                        String duties = dutiesController.text;

                        final pool = Pool(3); // Tối đa 3 yêu cầu cùng lúc

                        await Future.wait(residents.map((resident) async {
                          return pool.withResource(() async {
                            try {
                              final response = await http.post(
                                Uri.parse('https://createresidentaccount-ttrkrlo35a-uc.a.run.app'),
                                headers: {'Content-Type': 'application/json'},
                                body: json.encode({
                                  'email': resident.email,
                                  'fullName': resident.fullName,
                                  'cccd': resident.cccd,
                                  'address': resident.address,
                                  'gender': resident.gender,
                                  'phone': resident.phone,
                                  'birthDate': resident.birthDate?.toIso8601String(),
                                  'apartmentId': apartmentId,
                                }),
                              );

                              if (response.statusCode == 200) {
                                final data = json.decode(response.body);
                                resident.residentId = data['residentId'];
                                print("✅ Tạo ${resident.fullName} OK");
                              } else {
                                print("❌ Lỗi: ${response.body}");
                              }
                            } catch (e) {
                              print("❌ Lỗi gửi cho ${resident.fullName}: $e");
                            }
                          });
                        }));

                        // Tạo dữ liệu hợp đồng
                        Map<String, dynamic> contractData = {
                          "apartmentDocId": apartmentId,
                          'apartmentName': apartmentName,
                          'building': building,
                          'area': area,
                          'rentPrice': rentPrice,
                          'startDate': startDate,
                          'endDate': endDate,
                          'purpose': purpose,
                          'devices': devices,
                          'limitations': limitations,
                          'benefits': benefits,
                          'commitment': commitment,
                          'duties': duties,
                          "numberOfResidents": residents.length,
                          "createdAt": Timestamp.now(),
                        };

                        // ✅ Thêm người đại diện
                        final representative = residents[representativeIndex!];
                        contractData['representative'] = {
                          'id': representative.residentId,
                          'fullName': representative.fullName,
                        };

                        DocumentReference contractRef = await _firestore
                            .collection('apartments')
                            .doc(apartmentId)
                            .collection('contract')
                            .add(contractData);

                        // Cập nhật danh sách cư dân vào Firestore
                        final residentObjects = residents.map((r) => {
                          'fullName': r.fullName,
                          'id': r.residentId, // Lưu ID của cư dân
                        }).toList();

                        final apartmentRef = FirebaseFirestore.instance
                            .collection("apartments")
                            .doc(apartmentId);

                        await apartmentRef.update({
                          "isRent": true,
                          "residents": FieldValue.arrayUnion(residentObjects),
                        });

                        // Tạo hóa đơn nước đầu tiên
                        final billRef =
                        apartmentRef.collection("billWater").doc();
                        await billRef.set({
                        "month": DateFormat("yyyy-MM").format(DateTime.now()),
                        "oldMeterReading": 0,
                        "newMeterReading": 0,
                        "totalAmount":0,
                        "photoUrl":"",
                        "createdAt": Timestamp.now(),
                        });

                        final templateData = await rootBundle.load('assets/templates/hd_thue_ch.docx');
                        print("✅ Đã tải template DOCX");

                        // Tạo DocxTemplate từ template đã tải
                        final docx = await DocxTemplate.fromBytes(templateData.buffer.asUint8List());
                        print("✅ Đã tạo DocxTemplate");

                        final content = Content();
                        print("✅ Bắt đầu tạo nội dung");

                        // Thêm thông tin chính vào contract
                        content
                        ..add(TextContent("apartment_name", apartmentName))
                        ..add(TextContent("building", building))
                        ..add(TextContent("area", area.toString()))
                        ..add(TextContent("price", currencyFormat.format(rentPrice)))
                        ..add(TextContent("start_date", formatCustomDate(startDate!)))
                        ..add(TextContent("representative", representative.fullName))
                        ..add(TextContent("end_date",  formatCustomDate(endDate!)))
                        ..add(TextContent("purpose",  purpose))
                        ..add(TextContent("devices",  devices))
                        ..add(TextContent("limit",  limitations))
                        ..add(TextContent("obligation",  duties))
                        ..add(TextContent("benefit",  benefits))
                        ..add(TextContent("commit",  commitment));

                        print("✅ Đã thêm thông tin chính");

                        // === Danh sách cư dân ===
                        final residentsList = <PlainContent>[];

                        for (final r in List<ResidentInfo>.from(residents)) {
                        final residentContent = PlainContent("residents")
                        ..add(TextContent("resident_name", "Họ và tên: " + r.fullName))
                        ..add(TextContent("resident_cccd", "Số CCCD: " + r.cccd))
                        ..add(TextContent("resident_gender", "Giới tính: " + r.cccd))
                        ..add(TextContent("resident_birthdate", "Ngày sinh: " + r.cccd))
                        ..add(TextContent("resident_address", "Địa chỉ: " + r.cccd))
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
                        final fileName = "thuê_${apartmentName}_${DateTime.now().millisecondsSinceEpoch}.docx";
                        await downloadWordFile(fileName, fileBytes!);

                        LoadingDialog.hideLoadingDialog(context);

                        // Hiển thị dialog thành công
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Center(child: Text(
                                "Thành công",
                                style: TextStyle(fontSize: 5.sp),
                              ),),
                              content: Text(
                                  "Hợp đồng đã được tạo thành công!",
                                  style: TextStyle(fontSize: 4.sp)),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Provider.of<ContractNotifier>(context, listen: false).markAsCreated();

                                    Navigator.pop(context); // Đóng dialog
                                    Navigator.pop(context);
                                    // Quay lại trang trước
                                  },
                                  child: Text("Đồng ý",
                                      style: TextStyle(fontSize: 4.sp)),
                                ),
                              ],
                            );
                          },
                        );
                      } catch (e) {
                        // Xử lý lỗi
                        print("❌ Lỗi: $e");
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Center(child: Text(
                                "Thất bại",
                                style: TextStyle(fontSize: 5.sp),
                              ),),
                              content: Text(
                                  "Hợp đồng tạo thất bại!",
                                  style: TextStyle(fontSize: 4.sp)),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Đóng dialog
                                    Navigator.pop(context); // Quay lại trang trước
                                  },
                                  child: Text("Đồng ý",
                                      style: TextStyle(fontSize: 4.sp)),
                                ),
                              ],
                            );
                          },
                        );
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
                SizedBox(width: 30.w),
              ],
            )
          ],
        ),
      ),
    );
  }

}
