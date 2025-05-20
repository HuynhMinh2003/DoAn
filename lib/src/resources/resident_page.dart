import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../custom_paginated_table.dart';
import 'resident_mobile_page.dart' if (dart.library.html) 'resident_web_page.dart';

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

  String _searchQuery = ""; // Biến lưu trữ giá trị tìm kiếm
  Timer? _debounce; // Biến debounce

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
      apartments = results[0].docs.map((doc) => Apartment.fromFirestore(doc)).toList();
      residents = results[1].docs.map((doc) => ResidentInfo.fromFirestore(doc)).toList();
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

  Future<bool> sendUpdatedDetailEmailFromFlutter({
    required String uid,
    required String oldEmail,
    required String newEmail,
    required Map<String, String> updatedFields,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("https://sendupdateddetailemail-ttrkrlo35a-uc.a.run.app"), // <-- thay URL đúng của bạn
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

  void _showResidentDetails(BuildContext context, ResidentInfo resident, VoidCallback refresh) async {
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
    final StreamController<String?> nameErrorController = StreamController<String?>();
    final StreamController<String?> cccdErrorController = StreamController<String?>();
    final StreamController<String?> emailErrorController = StreamController<String?>();
    final StreamController<String?> birthDateErrorController = StreamController<String?>();
    final StreamController<String?> phoneErrorController = StreamController<String?>();
    final StreamController<String?> addressErrorController = StreamController<String?>();

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
        birthDateErrorController.add('Ngày sinh phải đúng định dạng dd/MM/yyyy.');
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
        return StatefulBuilder(
          builder: (context, setState) {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Căn hộ: $apartmentName", style: TextStyle(fontSize: 4.sp)),
                    SizedBox(height: 15.h),

                    // Name field
                    StreamBuilder<String?>(
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
                    SizedBox(height: 15.h),

                    // CCCD field
                    StreamBuilder<String?>(
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
                    SizedBox(height: 15.h),

                    // Email field
                    StreamBuilder<String?>(
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
                    SizedBox(height: 15.h),

                    // Email field
                    StreamBuilder<String?>(
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

                    SizedBox(height: 15.h),

                    // Email field
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
                    SizedBox(height: 15.h,),
                    // Gender dropdown
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Giới tính',
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (isEditing) {
                      validateFields();

                      if (nameHasError || cccdHasError || emailHasError || birthDateHasError || phoneHasError || addressHasError) return;

                      LoadingDialog.showLoadingDialog(context, "Đang tải...");
                      try {
                        // Prepare updated fields
                        final updatedFields = <String, String>{};

                        void compareAndAdd(String key, String newValue, String oldValue) {
                          if (newValue != oldValue) {
                            updatedFields[key] = newValue;
                          }
                        }

                        compareAndAdd("fullName", nameController.text.trim(), resident.fullName);
                        compareAndAdd("email", emailController.text.trim(), resident.email);
                        compareAndAdd("cccd", cccdController.text.trim(), resident.cccd);
                        compareAndAdd("birthDate", birthDateController.text.trim(), resident.birthDate != null
                            ? DateFormat('dd/MM/yyyy').format(resident.birthDate!)
                            : "");
                        compareAndAdd("phone", phoneController.text.trim(), resident.phone);
                        compareAndAdd("address", addressController.text.trim(), resident.address);
                        compareAndAdd("gender", selectedGender.trim(), resident.gender);

                        // Create updateData for Firestore
                        final updateData = {
                          'fullName': nameController.text.trim(),
                          'cccd': cccdController.text.trim(),
                          'birthDate': DateFormat('dd/MM/yyyy').parseStrict(birthDateController.text.trim()),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'address': addressController.text.trim(),
                          'gender': selectedGender.trim(),
                        };

                        // Update Firestore only if there are fields to update
                        if (updatedFields.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('residents')
                              .doc(resident.residentId)
                              .update(updateData);

                          // Send update email only if there are changes
                          await sendUpdatedDetailEmailFromFlutter(
                            uid: resident.residentId!,
                            oldEmail: resident.email,
                            newEmail: emailController.text.trim(),
                            updatedFields: updatedFields,
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
                    style: TextStyle(fontSize: 4.sp),
                  ),
                ),                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Đóng', style: TextStyle(fontSize: 4.sp)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final floors = selectedBuilding != null ? getFloorsByBuilding(selectedBuilding!) : [];
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

      bool matchesApartment = selectedApartment == null || r.apartmentId == selectedApartment!.id;
      bool matchesBuilding = selectedBuilding == null || apt.building == selectedBuilding;
      bool matchesFloor = selectedFloor == null || apt.floor == selectedFloor;
      bool matchesSearch = _searchQuery.isEmpty || r.fullName.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesApartment && matchesBuilding && matchesFloor && matchesSearch;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),child:Padding(
                padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(flex:3,child: Text(
                          "Danh sách cư dân",
                          style: TextStyle(
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),),
                        Flexible(flex:2, child: TextField(
                          decoration: InputDecoration(
                            labelText: "Tìm kiếm cư dân",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                          onChanged: _onSearchChanged, // Gọi hàm debounce khi nhập
                        )),
                        Flexible(flex:2,child: ElevatedButton(
                          onPressed: () => exportResidentsToExcel(residents, matchedResidents, apartments),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upload),
                              SizedBox(width: 5.w,),
                              Text('Xuất file', style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.bold, color: Colors.black),)
                            ],
                          ),
                        ),),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: buildFilterDropdown<String>(
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
                        ),),
                        SizedBox(width:20.w),
                        Expanded(child: buildFilterDropdown<int>(
                          label: 'Chọn tầng',
                          items: floors.cast<int>(),
                          selectedValue: selectedFloor,
                          onChanged: (val) {
                            setState(() {
                              selectedFloor = val;
                              selectedApartment = null;
                            });
                          },
                        ),),
                        SizedBox(width:20.w),
                        Expanded(child: buildFilterDropdown<Apartment>(
                          label: 'Chọn căn hộ',
                          items: rooms.cast<Apartment>(),
                          selectedValue: selectedApartment,
                          onChanged: (val) {
                            setState(() {
                              selectedApartment = val;
                            });
                          },
                          itemLabelBuilder: (apt) => apt.apartmentName,
                        ),)
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 360.h,
                      child: Row(
                        children: [
                          Expanded(
                            child: matchedResidents.isEmpty
                                ? const Center(child: Text("Không có cư dân."))
                                : CustomPaginatedTable(
                              columns: const [
                                DataColumn(label: Text('Họ tên')),
                                DataColumn(label: Text('CCCD')),
                                DataColumn(label: Text('Căn hộ')),
                              ],
                              rows: matchedResidents.map((resident) {
                                final apartment = apartments.firstWhere(
                                      (apt) => apt.id == resident.apartmentId,
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
                                    DataCell(Text(resident.fullName)),
                                    DataCell(Text(resident.cccd)),
                                    DataCell(Text(apartment.apartmentName)),
                                  ],
                                  onSelectChanged: (_) {
                                    _showResidentDetails(context, resident, refresh);
                                  },
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
              ),),
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
              style: TextStyle(
                fontSize: 4.sp,
                color: Colors.white
              ),
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
              width: 139.w ,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 4,
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40.h,
              padding: EdgeInsets.symmetric(
                horizontal: 10.w ,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

