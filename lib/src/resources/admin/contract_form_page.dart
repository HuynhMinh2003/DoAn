import 'package:do_an/constants.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  String formatCustomBirthDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<ResidentInfo> residents = [];

  // Thông tin căn hộ
  String apartmentName = '';
  double area = 0;
  String building = '';
  int rentPrice = 0;

  // // Các controller cho thông tin khác
  final purposeController = TextEditingController();

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
          title: Center(child: Text('Xác nhận', style: TextStyle(
              fontSize: 7.sp,
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold),),),
          content: Text('Bạn đã nhập $count người. Bạn có chắc muốn tiếp tục với số lượng này không?',style: TextStyle(fontSize: 4.sp),),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Không', style: TextStyle(fontSize: 3.5.sp,color: Colors.white)),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Có', style: TextStyle(fontSize: 3.5.sp,color: Colors.white)),
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

  Future<Map<String, int>> getLatestParkingFees() async {
    final Map<String, int> latestFees = {};
    final vehicleTypesSnapshot = await FirebaseFirestore.instance
        .collection('services')
        .doc('parking')
        .collection('vehicleTypes')
        .get();

    final futures = vehicleTypesSnapshot.docs.map((doc) async {
      final vehicleType = doc.id;
      final feeHistorySnapshot = await doc.reference
          .collection('feeHistory')
          .orderBy('effectiveFrom', descending: true)
          .limit(1)
          .get();
      if (feeHistorySnapshot.docs.isNotEmpty) {
        final fee = feeHistorySnapshot.docs.first.data()['fee'] as int;
        latestFees[vehicleType] = fee;
      }
    });

    await Future.wait(futures);
    return latestFees;
  }

  Future<int?> getLatestManagementFee() async {
    try {
      final feeHistorySnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc('managementFee')
          .collection('feeHistory')
          .orderBy('effectiveFrom', descending: true)
          .limit(1)
          .get();

      if (feeHistorySnapshot.docs.isNotEmpty) {
        final latestFee = feeHistorySnapshot.docs.first.data()['feePerM2'] as int;
        return latestFee;
      } else {
        return null; // Không có dữ liệu
      }
    } catch (e) {
      print('Lỗi khi lấy management fee: $e');
      return null; // Hoặc throw nếu muốn xử lý phía trên
    }
  }

  Future<Map<String, dynamic>?> checkExistingResident(String cccd, String email) async {
    final query = await FirebaseFirestore.instance
        .collection("residents")
        .where("cccd", isEqualTo: cccd)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return {
        'residentId': query.docs.first.id,
        ...query.docs.first.data(),
      };
    }

    final queryByEmail = await FirebaseFirestore.instance
        .collection("residents")
        .where("email", isEqualTo: email)
        .limit(1)
        .get();

    if (queryByEmail.docs.isNotEmpty) {
      return {
        'residentId': queryByEmail.docs.first.id, // ✅ Thêm dòng này
        ...queryByEmail.docs.first.data(),
      };
    }

    return null;
  }

  Future<void> uploadContractDocx(String contractId, String apartmentName, Uint8List fileBytes) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final filePath = 'contracts/${contractId}_${apartmentName}_${DateTime.now().millisecondsSinceEpoch}.docx';

      final uploadTask = storageRef
          .child(filePath)
          .putData(
        fileBytes,
        SettableMetadata(
          contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );

      final snapshot = await uploadTask.whenComplete(() => null);

      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('File Word đã được upload thành công: $downloadUrl');

      // Cập nhật Firestore document contracts/{contractId} với đường dẫn và URL file Word
      await FirebaseFirestore.instance.collection('contracts').doc(contractId).update({
        'docxStoragePath': filePath,
        'docxUrl': downloadUrl,
      });
    } catch (e) {
      print('Lỗi upload file Word: $e');
      rethrow; // hoặc xử lý lỗi tùy ý
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.decimalPattern('vi');
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('      Nhập thông tin hợp đồng', style: TextStyle(fontSize: 8.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),),backgroundColor: bgColor,),
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
                  color: secondaryColor,
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
                                style: TextStyle(fontSize: 4.sp,color: Colors.white),
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

            SizedBox(height: 20.h),

            TextField(
              controller: purposeController,
              decoration: InputDecoration(labelText: 'Mục đích thuê',labelStyle: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold)),
            ),

            SizedBox(height: 20.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 60.h,
                  width: 80.w,
                  child: ElevatedButton(
                    onPressed: () async {
                      LoadingDialog.showLoadingDialog(context, "Đang tải ...");

                      try {
                        String apartmentId = widget.apartmentId;
                        String purpose = purposeController.text;

                        if (representativeIndex == null || representativeIndex! >= residents.length) {
                          throw Exception("Vui lòng chọn người đại diện hợp lệ.");
                        }

                        final pool = Pool(3); // Giới hạn 3 request đồng thời

                        // === 1. Tạo hợp đồng trước để lấy contractId ===
                        final contractRef = await _firestore.collection('contracts').add({
                          "apartmentDocId": apartmentId,
                          'apartmentName': apartmentName,
                          'building': building,
                          'area': area,
                          'purpose': purpose,
                          'startDate': Timestamp.fromDate(startDate!),
                          'endDate': Timestamp.fromDate(endDate!),
                          "createdAt": Timestamp.now(),
                          "isActive": true,
                        });
                        String contractId = contractRef.id;

                        List<ResidentInfo> failedResidents = [];
                        List<ResidentInfo> successfulResidents = [];

                        for (final resident in residents) {
                          await pool.withResource(() async {
                            try {
                              // === Kiểm tra dữ liệu thiết yếu ===
                              if (resident.birthDate == null) {
                                throw Exception("Thiếu ngày sinh của cư dân ${resident.fullName}");
                              }

                              if (resident.email.isEmpty || resident.fullName.isEmpty || resident.cccd.isEmpty) {
                                throw Exception("Dữ liệu không đầy đủ cho cư dân ${resident.fullName}");
                              }

                              // === 1. Kiểm tra cư dân đã tồn tại bằng CCCD hoặc Email ===
                              final existingData = await checkExistingResident(resident.cccd, resident.email);

                              if (existingData != null) {
                                // Kiểm tra residentId có trong dữ liệu không
                                if (existingData['residentId'] == null) {
                                  throw Exception("Dữ liệu cư dân ${resident.fullName} bị thiếu residentId khi khôi phục.");
                                }

                                final shouldProceed = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Center(
                                        child: Text("Cư dân đã tồn tại", style: TextStyle(fontSize: 5.sp)),
                                      ),
                                      content: Text(
                                        "${resident.fullName} đã tồn tại trong hệ thống.\nBạn có muốn khôi phục lại thông tin này không?",
                                        style: TextStyle(fontSize: 4.sp),
                                      ),
                                      actions: [
                                        OutlinedButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.white),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp)),
                                        ),
                                        OutlinedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.green),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text("Khôi phục", style: TextStyle(fontSize: 3.5.sp, color: Colors.green)),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldProceed != true) {
                                  print("⛔ Người dùng chọn Hủy, bỏ qua ${resident.fullName}");
                                  failedResidents.add(resident);
                                  return;
                                }

                                print("🔁 Người dùng chọn Khôi phục — tiếp tục tạo mới tài khoản cho ${resident.fullName}");
                              }

                              // === 2. Gọi API tạo cư dân mới ===
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
                                  'birthDate': resident.birthDate!.toIso8601String(),
                                  'apartmentId': apartmentId,
                                  'contractId': contractId,
                                  'residentId': existingData?['residentId'], // chỉ truyền nếu có
                                  'imageUrl': existingData?['imageUrl'],
                                }),
                              );

                              if (response.statusCode == 200) {
                                final data = json.decode(response.body);
                                if (data['residentId'] == null) {
                                  throw Exception("API không trả về residentId cho cư dân ${resident.fullName}");
                                }
                                resident.residentId = data['residentId'];
                                successfulResidents.add(resident);
                                print("✅ Tạo ${resident.fullName} OK");
                              } else {
                                print("❌ Lỗi response: ${response.body}");
                                failedResidents.add(resident);
                              }
                            } catch (e) {
                              print("❌ Lỗi xử lý ${resident.fullName}: $e");
                              failedResidents.add(resident);
                            }
                          });
                        }

                        if (successfulResidents.isEmpty) {
                          await contractRef.delete(); // ✅ Xóa hợp đồng chưa dùng
                          throw Exception("❌ Không có cư dân nào được tạo thành công. Hợp đồng đã bị hủy.");
                        }

                        await contractRef.update({
                          "numberOfResidents": successfulResidents.length,
                        });

                        // === Kiểm tra người đại diện có còn không
                        final representative = residents[representativeIndex!];
                        if (!successfulResidents.contains(representative)) {
                          throw Exception("❌ Người đại diện đã bị loại bỏ — vui lòng chọn lại.");
                        }

                        await contractRef.update({
                          'representative': {
                            'id': representative.residentId,
                            'fullName': representative.fullName,
                          }
                        });

                        // === 4. Cập nhật residents vào apartments ===
                        final residentObjects = successfulResidents.map((r) => {
                          'fullName': r.fullName,
                          'id': r.residentId,
                        }).toList();

                        final apartmentRef = _firestore.collection("apartments").doc(apartmentId);
                        await apartmentRef.update({
                          "status": 'Đang cho thuê',
                          "residents": FieldValue.arrayUnion(residentObjects),
                          "currentContractId": contractId
                        });

                        final residentNames = successfulResidents.map((r) => r.fullName).toList();

                        await contractRef.collection("contractHistory").add({
                          "action": "Kí hợp đồng mới",
                          "performedBy": "Admin",
                          "residents": residentNames,
                          "representativeName": representative.fullName,
                          "timestamp": FieldValue.serverTimestamp(),
                        });

                        // === 6. Tạo file hợp đồng DOCX ===
                        final templateData = await rootBundle.load('assets/templates/hd_dichvu.docx');
                        final docx = await DocxTemplate.fromBytes(templateData.buffer.asUint8List());
                        final content = Content();

                        final latestFeesParking = await getLatestParkingFees();
                        final latestFeesManagement = await getLatestManagementFee();

                        content
                          ..add(TextContent("apartment_name", apartmentName))
                          ..add(TextContent("building", building))
                          ..add(TextContent("area", area.toString()))
                          ..add(TextContent("start_date", formatCustomDate(startDate!)))
                          ..add(TextContent("end_date", formatCustomDate(endDate!)))
                          ..add(TextContent("representative_fullName", representative.fullName))
                          ..add(TextContent("representative_birthDate", formatCustomBirthDate(representative.birthDate!)))
                          ..add(TextContent("representative_gender", representative.gender))
                          ..add(TextContent("representative_phone", representative.phone))
                          ..add(TextContent("representative_cccd", representative.cccd))
                          ..add(TextContent("representative_email", representative.email))
                          ..add(TextContent("representative_address", representative.address))
                          ..add(TextContent("bike_roofed_fee", currencyFormat.format(latestFeesParking["bike_roofed"] ?? 0)))
                          ..add(TextContent("bike_unroofed_fee", currencyFormat.format(latestFeesParking["bike_unroofed"] ?? 0)))
                          ..add(TextContent("car_unroofed_fee", currencyFormat.format(latestFeesParking["car_unroofed"] ?? 0)))
                          ..add(TextContent("car_roofed_fee", currencyFormat.format(latestFeesParking["car_roofed"] ?? 0)))
                          ..add(TextContent("motorbike_roofed_fee", currencyFormat.format(latestFeesParking["motorbike_roofed"] ?? 0)))
                          ..add(TextContent("motorbike_unroofed_fee", currencyFormat.format(latestFeesParking["motorbike_unroofed"] ?? 0)))
                          ..add(TextContent("management_fee", currencyFormat.format(latestFeesManagement ?? 0)));

                        // === Danh sách cư dân ===
                        final residentsList = <PlainContent>[];

                        for (final r in successfulResidents) {
                          final residentContent = PlainContent("residents")
                            ..add(TextContent("resident_name", "Họ và tên: " + r.fullName))
                            ..add(TextContent("resident_cccd", "Số CCCD: " + r.cccd))
                            ..add(TextContent("resident_gender", "Giới tính: " + r.gender))
                            ..add(TextContent("resident_birthdate", "Ngày sinh: " + formatCustomBirthDate(r.birthDate!)))
                            ..add(TextContent("resident_address", "Địa chỉ: " + r.address))
                            ..add(TextContent("resident_phone", "Số điện thoại: " + r.phone))
                            ..add(TextContent("resident_email", "Email: " + r.email));

                          residentsList.add(residentContent);
                        }

                        // residents là tag list, resident là mỗi item trong list
                        content.add(ListContent("residents", residentsList));

                        final fileBytes = await docx.generate(content);

                        if (fileBytes != null) {
                          final uint8ListFileBytes = Uint8List.fromList(fileBytes);

                          final fileName = "Hợp đồng dịch vụ căn hộ ${apartmentName}_${DateTime.now().millisecondsSinceEpoch}.docx";

                          // 1. Upload file Word lên Firebase Storage (đã convert đúng kiểu)
                          await uploadContractDocx(contractId, apartmentName, uint8ListFileBytes);

                          // 2. Tải file về máy (nếu cần)
                          await downloadWordFile(fileName, uint8ListFileBytes);
                        }

                        LoadingDialog.hideLoadingDialog(context);

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Center(child: Text("Thành công", style: TextStyle(fontFamily: "Oswald",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 6.sp))),
                              content: Text("Hợp đồng đã được tạo thành công!", style: TextStyle(fontSize: 4.sp)),
                              actions: [
                                OutlinedButton(
                                  onPressed: () {
                                    Provider.of<ContractNotifier>(context, listen: false).markAsCreated();
                                    Navigator.pop(context); // Đóng dialog
                                    Navigator.pop(context); // Quay lại trang trước
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text("Đồng ý", style: TextStyle(fontSize: 3.5.sp,color:Colors.white)),
                                ),
                              ],
                            );
                          },
                        );
                      } catch (e) {
                        print("❌ Lỗi: $e");
                        LoadingDialog.hideLoadingDialog(context);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Center(child: Text("Thất bại", style: TextStyle(fontFamily: "Oswald",
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 6.sp))),
                              content: Text("Hợp đồng tạo thất bại!", style: TextStyle(fontSize: 4.sp)),
                              actions: [
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Đóng dialog
                                    Navigator.pop(context); // Quay lại trang trước
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text("Đồng ý", style: TextStyle(fontSize: 3.5.sp,color: Colors.white)),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(30.r),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black45,
                      alignment: Alignment.center,
                      padding: EdgeInsets.zero,
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
