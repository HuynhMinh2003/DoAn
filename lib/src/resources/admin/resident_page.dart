import 'dart:async';
import 'dart:convert';
import 'package:do_an/custom_paginated_table.dart';
import 'package:do_an/src/resources/provider/resident_image_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../constants.dart';
import '../../blocs/auth_bloc.dart';
import 'resident_mobile_page.dart'
    if (dart.library.html) 'resident_web_page.dart';

class ResidentPage extends StatefulWidget {
  const ResidentPage({super.key});

  @override
  State<ResidentPage> createState() => _ResidentPageState();
}

class _ResidentPageState extends State<ResidentPage> {
  List<Apartment> apartments = [];
  List<ResidentInfo> residents = [];

  String? selectedBuilding;
  int? selectedFloor;
  Apartment? selectedApartment;

  String? selectedStatus;

  String _searchQuery = ""; // Biến lưu trữ giá trị tìm kiếm
  Timer? _debounce; // Biến debounce

  bool _isEditDialogShowing = false;
  bool _isViewDialogShowing = false;
  bool _isHistoryDialogShowing = false;

  final AuthBloc _authBloc = AuthBloc();

  List<String> getBuildings() {
    return apartments.map((a) => a.building).toSet().toList()..sort();
  }

  List<int> getFloorsByBuilding(String building) {
    return apartments
        .where((a) => a.building == building)
        .map((a) => a.floor)
        .toSet()
        .toList()
      ..sort();
  }

  List<Apartment> getApartmentsByFloor(String building, int floor) {
    final list = apartments
        .where((a) => a.building == building && a.floor == floor)
        .toList();

    list.sort((a, b) {
      final reg = RegExp(r'(\d+)-(\d+)');
      final matchA = reg.firstMatch(a.apartmentName);
      final matchB = reg.firstMatch(b.apartmentName);

      if (matchA != null && matchB != null) {
        final blockA = int.parse(matchA.group(1)!);
        final roomA = int.parse(matchA.group(2)!);
        final blockB = int.parse(matchB.group(1)!);
        final roomB = int.parse(matchB.group(2)!);

        if (blockA != blockB) return blockA.compareTo(blockB);
        return roomA.compareTo(roomB);
      }

      return a.apartmentName.compareTo(b.apartmentName);
    });

    return list;
  }

  List<ResidentInfo> getResidentsByApartmentId(String apartmentId) {
    return residents.where((r) => r.apartmentId == apartmentId).toList();
  }

  Future<void> loadData() async {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('apartments').get(),
      FirebaseFirestore.instance.collection('residents').get(),
    ]);

    if (!mounted) return;

    setState(() {
      apartments =
          results[0].docs.map((doc) => Apartment.fromFirestore(doc)).toList();
      residents = results[1]
          .docs
          .map((doc) => ResidentInfo.fromFirestore(doc))
          .toList();
    });
  }

  // Hàm debounce cho tìm kiếm theo tên
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

// Hàm refresh để tải lại dữ liệu
  Future<void> refresh() async {
    await loadData();
    // Reset các lựa chọn liên quan đến tòa nhà, tầng và căn hộ
    setState(() {
      selectedBuilding = null;
      selectedFloor = null;
      selectedApartment = null;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Hủy debounce khi widget bị dispose
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> getContractHistoryWithApartmentNames(String residentId) async {
    final historySnapshots = await FirebaseFirestore.instance
        .collection('residents')
        .doc(residentId)
        .collection('contractHistory')
        .get();

    List<Map<String, dynamic>> historyList = [];

    for (var doc in historySnapshots.docs) {
      final data = doc.data();
      final apartmentId = data['apartmentId'];
      String apartmentName = 'Không rõ';

      final aptSnapshot = await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .get();

      if (aptSnapshot.exists) {
        apartmentName = aptSnapshot.data()?['apartmentName'] ?? 'Không rõ';
      }

      historyList.add({
        'apartmentId': apartmentId,
        'apartmentName': apartmentName,
        'contractId': data['contractId'] ?? '',
        'joinedAt': (data['joinedAt'] as Timestamp?)?.toDate(),
        'leftAt': (data['leftAt'] as Timestamp?)?.toDate(),
      });
    }

    return historyList;
  }

  Future<void> showContractHistoryDialog(BuildContext context, String residentId) async {
    final histories = await getContractHistoryWithApartmentNames(residentId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: Text(
          "Lịch sử thuê",
          style: TextStyle(
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 7.sp,
            color: Colors.blueAccent,
          ),
        ),),
        content: SizedBox(
          width: double.minPositive,
          child: histories.isEmpty
              ? Text("Không có dữ liệu lịch sử.")
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: histories.map((history) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Divider(),
                    buildInfoRow("Tên căn hộ:", history['apartmentName']),
                    buildInfoRow(
                      "Ngày vào:",
                      history['joinedAt'] != null
                          ? DateFormat('dd/MM/yyyy').format(history['joinedAt'])
                          : "Không rõ",
                    ),
                    buildInfoRow(
                      "Ngày rời:",
                      history['leftAt'] != null
                          ? DateFormat('dd/MM/yyyy').format(history['leftAt'])
                          : "Chưa có",
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size(80, 40),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Đóng",
              style: TextStyle(fontSize: 3.5.sp, color: Colors.white),
            ),
          ),

        ],
      ),
    );
  }

  Future<bool> sendUpdatedDetailEmailFromFlutter({
    required String uid,
    required String oldEmail,
    required String newEmail,
    required Map<String, String> updatedFields,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("https://sendupdateddetailemail-ttrkrlo35a-uc.a.run.app"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'oldEmail': oldEmail,
          'newEmail': newEmail,
          'updatedFields': updatedFields,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Cập nhật & gửi email thông báo thành công.");
        return true;
      } else {
        print("❌ Lỗi từ server: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception khi gọi Cloud Function: $e");
      return false;
    }
  }

  Future<void> showViewResidentDialog(BuildContext context, ResidentInfo resident, VoidCallback onRefresh) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(
            "Thông tin cư dân",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 7.sp,
              color: Colors.blueAccent,
            ),
          ),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 70.r,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: resident.imageUrl?.isNotEmpty == true
                          ? Image.network(
                        resident.imageUrl!,
                        width: 140.r,
                        height: 140.r,
                        fit: BoxFit.cover,
                      )
                          : SvgPicture.asset(
                        'assets/images/default_avatar.svg',
                        width: 70.r,
                        height: 70.r,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                ),
                SizedBox(height: 20.h),
                buildInfoRow("Họ và tên:", resident.fullName),
                buildInfoRow("Email:", resident.email),
                buildInfoRow("Giới tính:", resident.gender),
                buildInfoRow(
                  "Ngày sinh:",
                  resident.birthDate != null
                      ? DateFormat('dd/MM/yyyy').format(resident.birthDate!)
                      : "Chưa cập nhật",
                ),
                buildInfoRow("CCCD:", resident.cccd),
                buildInfoRow("Địa chỉ:", resident.address),
                buildInfoRow("Số điện thoại:", resident.phone),
                buildInfoRow(
                  "Lần sửa thông tin gần nhất: ",
                  resident.lastUpdated != null
                      ? DateFormat('dd/MM/yyyy – HH:mm')
                      .format(resident.lastUpdated!)
                      : "Chưa có",
                ),
                if (resident.isExit)
                  buildInfoRow(
                    "Ngày rời căn hộ:",
                    resident.leaveAt != null
                        ? DateFormat('dd/MM/yyyy – HH:mm')
                            .format(resident.leaveAt!)
                        : "Chưa có",
                  ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size(80, 40),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Đóng",
                style: TextStyle(fontSize: 3.5.sp, color: Colors.white),
              ),
            ),

          ],
        );
      },
    );
  }

  Future<void> showEditResident(BuildContext context, ResidentInfo resident, VoidCallback refresh) async {
    final apartmentSnapshot = await FirebaseFirestore.instance
        .collection('apartments')
        .doc(resident.apartmentId)
        .get();

    if (!apartmentSnapshot.exists) return;

    final apartment = apartmentSnapshot.data();
    final apartmentName = apartment?['apartmentName'] ?? 'Không có tên căn hộ';

    String birthDateFormatted = 'Không xác định';
    if (resident.birthDate != null) {
      birthDateFormatted = DateFormat('dd/MM/yyyy').format(resident.birthDate!);
    }

    // Controllers for inputs
    final nameController = TextEditingController(text: resident.fullName);
    final cccdController = TextEditingController(text: resident.cccd);
    final emailController = TextEditingController(text: resident.email);
    final birthDateController = TextEditingController(text: birthDateFormatted);
    final phoneController = TextEditingController(text: resident.phone);
    final addressController = TextEditingController(text: resident.address);
    String selectedGender = resident.gender;
    bool isEditing = false;

    // StreamControllers for error handling
    final StreamController<String?> nameErrorController =
        StreamController<String?>();
    final StreamController<String?> cccdErrorController =
        StreamController<String?>();
    final StreamController<String?> emailErrorController =
        StreamController<String?>();
    final StreamController<String?> birthDateErrorController =
        StreamController<String?>();
    final StreamController<String?> phoneErrorController =
        StreamController<String?>();
    final StreamController<String?> addressErrorController =
        StreamController<String?>();

    // Error state variables
    bool nameHasError = false;
    bool cccdHasError = false;
    bool emailHasError = false;
    bool birthDateHasError = false;
    bool phoneHasError = false;
    bool addressHasError = false;

    void validateFields() {
      // Name validation
      if (nameController.text.isEmpty) {
        nameErrorController.add('Họ và tên không được để trống.');
        nameHasError = true;
      } else {
        nameErrorController.add(null);
        nameHasError = false;
      }

      // CCCD validation
      if (!RegExp(r'^\d{12}$').hasMatch(cccdController.text)) {
        cccdErrorController.add('CCCD phải có đúng 12 số.');
        cccdHasError = true;
      } else {
        cccdErrorController.add(null);
        cccdHasError = false;
      }

      // Email validation
      if (!EmailValidator.validate(emailController.text)) {
        emailErrorController.add('Email không hợp lệ.');
        emailHasError = true;
      } else {
        emailErrorController.add(null);
        emailHasError = false;
      }

      // Birth date validation
      try {
        DateFormat('dd/MM/yyyy').parseStrict(birthDateController.text);
        birthDateErrorController.add(null);
        birthDateHasError = false;
      } catch (e) {
        birthDateErrorController
            .add('Ngày sinh phải đúng định dạng dd/MM/yyyy.');
        birthDateHasError = true;
      }

      // Phone number validation
      if (!RegExp(r'^\d{10}$').hasMatch(phoneController.text)) {
        phoneErrorController.add('Số điện thoại phải có đúng 10 số.');
        phoneHasError = true;
      } else {
        phoneErrorController.add(null);
        phoneHasError = false;
      }

      // Address validation
      if (addressController.text.isEmpty) {
        addressErrorController.add('Địa chỉ không được để trống.');
        addressHasError = true;
      } else {
        addressErrorController.add(null);
        addressHasError = false;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (_) => ResidentImageProvider(),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Consumer<ResidentImageProvider>(
                builder: (context, imageProvider, _) {
                  return AlertDialog(
                    title: Text(
                      "Thông tin cư dân",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.bold,
                        fontSize: 6.sp,
                        color: Colors.blueAccent,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(left: 5.w, right: 5.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 70.r,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 140.r,
                                      height: 140.r,
                                      child: imageProvider.webImageBytes != null
                                          ? Image.memory(
                                        imageProvider.webImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                          : imageProvider.selectedImageFile != null
                                          ? Image.file(
                                        imageProvider.selectedImageFile!,
                                        fit: BoxFit.cover,
                                      )
                                          : (resident.imageUrl != null &&
                                          resident.imageUrl!.isNotEmpty)
                                          ? Image.network(
                                        resident.imageUrl!,
                                        fit: BoxFit.cover,
                                      )
                                          : Center( // ✅ Center default avatar & make it smaller
                                        child: SvgPicture.asset(
                                          'assets/images/default_avatar.svg',
                                          fit: BoxFit.contain,
                                          width: 70.r, // Smaller size
                                          height: 70.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt, color: Colors.blueAccent),
                                      onPressed: () async {
                                        await imageProvider.pickImage();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(
                              height: 20.h,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ Tên căn hộ căn giữa
                                Center(
                                  child: Text(
                                    "Căn hộ: $apartmentName",
                                    style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 20.h),

                                // ✅ Row: Họ tên + Email
                                Row(
                                  children: [
                                    Expanded(
                                      child: StreamBuilder<String?>(
                                        stream: nameErrorController.stream,
                                        builder: (context, snapshot) {
                                          return TextField(
                                            controller: nameController,
                                            enabled: isEditing,
                                            style: TextStyle(fontSize: 4.sp),
                                            decoration: InputDecoration(
                                              labelText: 'Họ và tên',
                                              labelStyle: TextStyle(fontSize: 4.sp),
                                              errorText: snapshot.data,
                                            ),
                                            onChanged: (_) {
                                              if (isEditing) validateFields();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: StreamBuilder<String?>(
                                        stream: emailErrorController.stream,
                                        builder: (context, snapshot) {
                                          return TextField(
                                            controller: emailController,
                                            enabled: isEditing,
                                            style: TextStyle(fontSize: 4.sp),
                                            decoration: InputDecoration(
                                              labelText: 'Email',
                                              labelStyle: TextStyle(fontSize: 4.sp),
                                              errorText: snapshot.data,
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: (_) {
                                              if (isEditing) validateFields();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15.h),

                                // ✅ Row: Ngày sinh + CCCD
                                Row(
                                  children: [
                                    Expanded(
                                      child: StreamBuilder<String?>(
                                        stream: birthDateErrorController.stream,
                                        builder: (context, snapshot) {
                                          return GestureDetector(
                                            onTap: isEditing
                                                ? () async {
                                              final pickedDate = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime.now(),
                                              );
                                              if (pickedDate != null) {
                                                _authBloc.updateBirthDate(pickedDate);
                                                birthDateController.text =
                                                    DateFormat('dd/MM/yyyy').format(pickedDate);
                                              }
                                            }
                                                : null,
                                            child: AbsorbPointer(
                                              absorbing: !isEditing,
                                              child: TextField(
                                                controller: birthDateController,
                                                enabled: isEditing,
                                                style: TextStyle(fontSize: 4.sp),
                                                decoration: InputDecoration(
                                                  labelText: 'Ngày sinh',
                                                  labelStyle: TextStyle(fontSize: 4.sp),
                                                  errorText: snapshot.data,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: StreamBuilder<String?>(
                                        stream: cccdErrorController.stream,
                                        builder: (context, snapshot) {
                                          return TextField(
                                            controller: cccdController,
                                            enabled: isEditing,
                                            style: TextStyle(fontSize: 4.sp),
                                            decoration: InputDecoration(
                                              labelText: 'CCCD',
                                              labelStyle: TextStyle(fontSize: 4.sp),
                                              errorText: snapshot.data,
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) {
                                              if (isEditing) validateFields();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15.h),

                                // ✅ Row: Giới tính + Số điện thoại
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: selectedGender,
                                        decoration: InputDecoration(
                                          labelText: 'Giới tính',
                                          labelStyle: TextStyle(fontSize: 4.sp),
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['Nam', 'Nữ', 'Khác']
                                            .map((gender) => DropdownMenuItem<String>(
                                          value: gender,
                                          child: Text(gender, style: TextStyle(fontSize: 4.sp)),
                                        ))
                                            .toList(),
                                        onChanged: isEditing
                                            ? (value) {
                                          setState(() {
                                            selectedGender = value ?? "Khác";
                                          });
                                        }
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: StreamBuilder<String?>(
                                        stream: phoneErrorController.stream,
                                        builder: (context, snapshot) {
                                          return TextField(
                                            controller: phoneController,
                                            enabled: isEditing,
                                            style: TextStyle(fontSize: 4.sp),
                                            decoration: InputDecoration(
                                              labelText: 'Số điện thoại',
                                              labelStyle: TextStyle(fontSize: 4.sp),
                                              errorText: snapshot.data,
                                            ),
                                            onChanged: (_) {
                                              if (isEditing) validateFields();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15.h),

                                // ✅ Địa chỉ (cuối)
                                StreamBuilder<String?>(
                                  stream: addressErrorController.stream,
                                  builder: (context, snapshot) {
                                    return TextField(
                                      controller: addressController,
                                      enabled: isEditing,
                                      style: TextStyle(fontSize: 4.sp),
                                      decoration: InputDecoration(
                                        labelText: 'Địa chỉ',
                                        labelStyle: TextStyle(fontSize: 4.sp),
                                        errorText: snapshot.data,
                                      ),
                                      onChanged: (_) {
                                        if (isEditing) validateFields();
                                      },
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size(90, 40),
                        ),
                        onPressed: () async {
                          if (isEditing) {
                            validateFields();

                            if (nameHasError ||
                                cccdHasError ||
                                emailHasError ||
                                birthDateHasError ||
                                phoneHasError ||
                                addressHasError) return;

                            LoadingDialog.showLoadingDialog(context, "Đang tải...");
                            try {
                              String? newImageUrl;

                              if (imageProvider.webImageBytes != null) {
                                if (resident.imageUrl != null && resident.imageUrl!.isNotEmpty) {
                                  final storageRef =
                                  FirebaseStorage.instance.refFromURL(resident.imageUrl!);
                                  await storageRef.delete();
                                }

                                final uniqueFileName =
                                    "${DateTime.now().millisecondsSinceEpoch}_avatar.jpg";
                                newImageUrl = await imageProvider.uploadSelectedImageAndGetUrl(
                                    resident.residentId!, uniqueFileName);
                              }

                              final updatedFields = <String, String>{};
                              final updatedFieldLabels = <String, String>{};

                              void compareAndAdd(String key, String label, String newValue, String oldValue) {
                                if (newValue != oldValue) {
                                  updatedFields[key] = newValue;
                                  updatedFieldLabels[label] = newValue;
                                }
                              }

                              compareAndAdd("fullName", "Họ và tên", nameController.text.trim(), resident.fullName);
                              compareAndAdd("email", "Email", emailController.text.trim(), resident.email);
                              compareAndAdd("cccd", "CCCD", cccdController.text.trim(), resident.cccd);
                              compareAndAdd("birthDate", "Ngày sinh", birthDateController.text.trim(),
                                  resident.birthDate != null ? DateFormat('dd/MM/yyyy').format(resident.birthDate!) : "");
                              compareAndAdd("phone", "Số điện thoại", phoneController.text.trim(), resident.phone);
                              compareAndAdd("address", "Địa chỉ", addressController.text.trim(), resident.address);
                              compareAndAdd("gender", "Giới tính", selectedGender.trim(), resident.gender);

                              if (newImageUrl != null && newImageUrl != resident.imageUrl) {
                                updatedFields['imageUrl'] = newImageUrl;
                                updatedFieldLabels['Ảnh đại diện'] = '[Đã cập nhật ảnh mới]';
                              }

                              final updateData = {
                                'fullName': nameController.text.trim(),
                                'cccd': cccdController.text.trim(),
                                'birthDate': DateFormat('dd/MM/yyyy').parseStrict(birthDateController.text.trim()),
                                'email': emailController.text.trim(),
                                'phone': phoneController.text.trim(),
                                'address': addressController.text.trim(),
                                'gender': selectedGender.trim(),
                                'lastUpdated': FieldValue.serverTimestamp(),
                              };

                              if (newImageUrl != null) {
                                updateData['imageUrl'] = newImageUrl;
                              }

                              if (updatedFields.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('residents')
                                    .doc(resident.residentId)
                                    .update(updateData);

                                await sendUpdatedDetailEmailFromFlutter(
                                  uid: resident.residentId!,
                                  oldEmail: resident.email,
                                  newEmail: emailController.text.trim(),
                                  updatedFields: updatedFieldLabels,
                                );
                              }

                              Navigator.pop(context);
                              refresh();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Cập nhật thất bại: $e')),
                              );
                            } finally {
                              LoadingDialog.hideLoadingDialog(context);
                            }
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
                        },
                        child: Text(
                          isEditing ? 'Lưu' : 'Sửa',
                          style: TextStyle(fontSize: 3.5.sp, color: Colors.white),
                        ),
                      ),

                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size(90, 40),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Đóng', style: TextStyle(fontSize: 3.5.sp, color: Colors.white)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 4.sp),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 4.sp),
              softWrap: true,
              overflow: TextOverflow.ellipsis, // Hoặc .fade hoặc .clip nếu thích
              maxLines: 2, // Giới hạn số dòng nếu cần
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final floors =
        selectedBuilding != null ? getFloorsByBuilding(selectedBuilding!) : [];
    final rooms = (selectedBuilding != null && selectedFloor != null)
        ? getApartmentsByFloor(selectedBuilding!, selectedFloor!)
        : [];

    final matchedResidents = residents.where((r) {
      final apt = apartments.firstWhere(
            (a) => a.id == r.apartmentId,
        orElse: () => Apartment(
          id: '',
          apartmentName: '',
          building: '',
          area: 0,
          description: '',
          status: '',
          currentContractId: '',
          residents: [],
        ),
      );

      bool matchesApartment =
          selectedApartment == null || r.apartmentId == selectedApartment!.id;
      bool matchesBuilding =
          selectedBuilding == null || apt.building == selectedBuilding;
      bool matchesFloor = selectedFloor == null || apt.floor == selectedFloor;
      bool matchesSearch = _searchQuery.isEmpty ||
          r.fullName.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = true;
      if (selectedStatus == "Đang ở") {
        matchesStatus = r.isExit == false;
      } else if (selectedStatus == "Đã rời") {
        matchesStatus = r.isExit == true;
      } else if (selectedStatus == "Tất cả" || selectedStatus == null) {
        matchesStatus = true; // Không lọc gì cả
      }

      return matchesApartment &&
          matchesBuilding &&
          matchesFloor &&
          matchesSearch &&
          matchesStatus;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height),
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 3,
                            child: Text(
                              "Danh sách cư dân",
                              style: TextStyle(
                                fontFamily: "Oswald",
                                fontWeight: FontWeight.w700,
                                fontSize: 7.sp,
                              ),
                            ),
                          ),
                          Flexible(
                              flex: 2,
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Tìm kiếm cư dân",
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                ),
                                onChanged:
                                    _onSearchChanged, // Gọi hàm debounce khi nhập
                              )),
                          Flexible(
                            flex: 2,
                            child: SizedBox(height: 55.h,width: 40.w,child: ElevatedButton(
                              onPressed: () => exportResidentsToExcel(
                                  residents, matchedResidents, apartments),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload),
                                  SizedBox(
                                    width: 5.w,
                                  ),
                                  Text(
                                    'Xuất file',
                                    style: TextStyle(
                                        fontSize: 4.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  )
                                ],
                              ),
                            ),)
                          ),
                          SizedBox(width: 5.w,)
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: buildFilterDropdown<String>(
                              label: 'Chọn tòa nhà',
                              items: getBuildings(),
                              selectedValue: selectedBuilding,
                              onChanged: (val) {
                                setState(() {
                                  selectedBuilding = val;
                                  selectedFloor = null;
                                  selectedApartment = null;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: buildFilterDropdown<int>(
                              label: 'Chọn tầng',
                              items: floors.cast<int>(),
                              selectedValue: selectedFloor,
                              onChanged: (val) {
                                setState(() {
                                  selectedFloor = val;
                                  selectedApartment = null;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: buildFilterDropdown<Apartment>(
                              label: 'Chọn căn hộ',
                              items: rooms.cast<Apartment>(),
                              selectedValue: selectedApartment,
                              onChanged: (val) {
                                setState(() {
                                  selectedApartment = val;
                                });
                              },
                              itemLabelBuilder: (apt) => apt.apartmentName,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: buildFilterDropdown1<String>(
                              label: 'Trạng thái cư dân',
                              items: ['Tất cả','Đang ở','Đã rời'],
                              selectedValue: selectedStatus,
                              onChanged: (val) {
                                setState(() {
                                  selectedStatus = val;
                                });
                              },
                              hintText: 'Chọn trạng thái', // Thêm dòng này nếu bạn custom được
                            ),
                          ),
                          SizedBox(width: 20.w),


                        ],
                      ),
                      SizedBox(height: 10.h,),
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 360.h,
                        child: Row(
                          children: [
                            Expanded(
                              child: matchedResidents.isEmpty
                                  ? Center(
                                      child: Text("Không có cư dân",style: TextStyle(
                          fontSize: 4.sp, color: Colors.white
                        ),))
                                  : CustomPaginatedTable(
                                      columns: [
                                        DataColumn(
                                            label: Text("Họ và tên",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                        DataColumn(
                                            label: Text("Email",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                        DataColumn(
                                            label: Text("Giới tính",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                        DataColumn(
                                            label: Text("Số điện thoại",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                        DataColumn(
                                            label: Text("Địa chỉ",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                        DataColumn(
                                            label: Text("Căn hộ",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                        DataColumn(
                                            label: Text("Thao tác",
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                      ],
                                      rows: matchedResidents.map((resident) {
                                        final apartment = apartments.firstWhere(
                                          (apt) =>
                                              apt.id == resident.apartmentId,
                                          orElse: () => Apartment(
                                            id: '',
                                            apartmentName: '',
                                            building: '',
                                            area: 0,
                                            description: '',
                                            status: '',
                                            currentContractId: '',
                                            residents: [],
                                          ),
                                        );

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(resident.fullName,
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(resident.email,
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(resident.gender,
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(resident.phone,
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(resident.address,
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                            DataCell(Text(
                                                apartment.apartmentName,
                                                style:
                                                    TextStyle(fontSize: 4.sp))),
                                            DataCell(
                                              Row(children: [
                                                // Nút SỬA - vô hiệu hóa nếu isExit = true
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                                  tooltip: resident.isExit ? 'Không thể sửa cư dân đã rời' : 'Sửa thông tin',
                                                  onPressed: resident.isExit
                                                      ? null // Vô hiệu hóa
                                                      : () async {
                                                    if (_isEditDialogShowing) return;
                                                    _isEditDialogShowing = true;
                                                    try {
                                                      await showEditResident(context, resident, refresh);
                                                    } finally {
                                                      _isEditDialogShowing = false;
                                                    }
                                                  },
                                                ),

                                                // Nút XEM LỊCH SỬ thuê – vẫn cho phép xem
                                                IconButton(
                                                  icon: const Icon(Icons.access_time, color: Colors.green),
                                                  tooltip: 'Xem lịch sử thuê',
                                                  onPressed: () async {
                                                    if (_isHistoryDialogShowing) return;
                                                    _isHistoryDialogShowing = true;
                                                    try {
                                                      await showContractHistoryDialog(context, resident.residentId!);
                                                    } finally {
                                                      _isHistoryDialogShowing = false;
                                                    }
                                                  },
                                                ),

                                                // Nút XEM CHI TIẾT – vẫn cho phép xem
                                                IconButton(
                                                  icon: const Icon(Icons.info_outline, color: Colors.white),
                                                  tooltip: 'Xem chi tiết',
                                                  onPressed: () async {
                                                    if (_isViewDialogShowing) return;
                                                    _isViewDialogShowing = true;
                                                    try {
                                                      await showViewResidentDialog(context, resident, refresh);
                                                    } finally {
                                                      _isViewDialogShowing = false;
                                                    }
                                                  },
                                                ),
                                              ]),
                                            ),

                                          ],
                                        );
                                      }).toList(),
                                      rowsPerPage: 10,
                                    ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabelBuilder,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: Text(
              label,
              style: TextStyle(fontSize: 4.sp, color: Colors.white),
            ),
            items: items.map((item) {
              final displayText = itemLabelBuilder != null
                  ? itemLabelBuilder(item)
                  : item.toString();

              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 4.sp),
                ),
              );
            }).toList(),
            value: selectedValue,
            onChanged: onChanged,
            selectedItemBuilder: (context) {
              return items.map((item) {
                final displayText = itemLabelBuilder != null
                    ? itemLabelBuilder(item)
                    : item.toString();

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayText,
                    style: TextStyle(fontSize: 4.sp),
                  ),
                );
              }).toList();
            },
            buttonStyleData: ButtonStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                vertical: 2.h,
                horizontal: 10.w,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: const Color(0xe2707070)),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200.h,
              width: 67.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 4,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFilterDropdown1<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabelBuilder,
    String? hintText, // Thêm tham số hintText tùy chọn
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: Text(
              hintText ?? label, // Hiển thị hintText nếu có, nếu không thì label
              style: TextStyle(fontSize: 4.sp, color: Colors.white70), // Màu hơi mờ
            ),
            items: items.map((item) {
              final displayText = itemLabelBuilder != null
                  ? itemLabelBuilder(item)
                  : item.toString();

              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 4.sp),
                ),
              );
            }).toList(),
            value: selectedValue,
            onChanged: onChanged,
            selectedItemBuilder: (context) {
              return items.map((item) {
                final displayText = itemLabelBuilder != null
                    ? itemLabelBuilder(item)
                    : item.toString();

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayText,
                    style: TextStyle(fontSize: 4.sp),
                  ),
                );
              }).toList();
            },
            buttonStyleData: ButtonStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                vertical: 2.h,
                horizontal: 10.w,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: const Color(0xe2707070)),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200.h,
              width: 67.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 4,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
