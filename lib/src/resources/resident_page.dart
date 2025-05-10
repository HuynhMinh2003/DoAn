import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:do_an/src/resources/back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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

  void _showResidentDetails(BuildContext context, ResidentInfo resident) async {
    final apartmentSnapshot = await FirebaseFirestore.instance
        .collection('apartments')
        .doc(resident.apartmentId)
        .get();

    if (!apartmentSnapshot.exists) return;

    final apartment = apartmentSnapshot.data();
    final apartmentName = apartment?['apartmentName'] ?? 'Không có tên căn hộ';

    final residentSnapshot = await FirebaseFirestore.instance
        .collection('residents')
        .doc(resident.residentId)
        .get();

    String createdAt = 'Chưa có thông tin hợp đồng';
    if (residentSnapshot.exists) {
      final data = residentSnapshot.data();
      final ts = data?['createdAt'];
      if (ts is Timestamp) {
        createdAt = DateFormat('dd/MM/yyyy').format(ts.toDate());
      }
    }

    String birthDateFormatted = 'Không xác định';
    if (resident.birthDate != null) {
      birthDateFormatted = DateFormat('dd/MM/yyyy').format(resident.birthDate!);
    }

    // Đặt biến ở ngoài StatefulBuilder
    final nameController = TextEditingController(text: resident.fullName);
    final cccdController = TextEditingController(text: resident.cccd);
    final emailController = TextEditingController(text: resident.email);
    final birthDateController = TextEditingController(text: birthDateFormatted);
    final phoneController = TextEditingController(text: resident.phone);
    bool isEditing = false;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Chỉnh sửa thông tin cư dân' : 'Thông tin cá nhân',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Căn hộ: $apartmentName"),
                    SizedBox(height: 10),
                    isEditing
                        ? TextFormField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên"))
                        : Text("Họ tên: ${resident.fullName}"),
                    SizedBox(height: 10),
                    isEditing
                        ? TextFormField(controller: cccdController, decoration: InputDecoration(labelText: "CCCD"))
                        : Text("CCCD: ${resident.cccd}"),
                    SizedBox(height: 10),
                    isEditing
                        ? TextFormField(controller: emailController, decoration: InputDecoration(labelText: "Email"))
                        : Text("Email: ${resident.email}"),
                    SizedBox(height: 10),
                    isEditing
                        ? TextFormField(controller: birthDateController, decoration: InputDecoration(labelText: "Ngày sinh"))
                        : Text("Ngày sinh: $birthDateFormatted"),
                    SizedBox(height: 10),
                    isEditing
                        ? TextFormField(controller: phoneController, decoration: InputDecoration(labelText: "Số điện thoại"))
                        : Text("Số điện thoại: ${resident.phone}"),
                    SizedBox(height: 10),
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (isEditing) {
                      if (nameController.text.isEmpty ||
                          cccdController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          phoneController.text.isEmpty) {
                        setState(() {
                          errorMessage = 'Vui lòng điền đầy đủ thông tin.';
                        });
                        return;
                      }

                      try {
                        final updatedFullName = nameController.text;
                        final newEmail = emailController.text;
                        final oldEmail = resident.email;

                        final updatedFields = {
                          'Họ tên': updatedFullName,
                          'Số cccd': cccdController.text,
                          'Ngày sinh': birthDateController.text,
                          'Số điện thoại': phoneController.text,
                          'Email': newEmail,
                        };

                        // 1. Gửi email và đồng thời cập nhật email Auth nếu đổi email
                        final success = await sendUpdatedDetailEmailFromFlutter(
                          uid: resident.residentId!,
                          oldEmail: oldEmail,
                          newEmail: newEmail,
                          updatedFields: updatedFields,
                        );

                        if (!success) {
                          setState(() {
                            errorMessage = 'Cập nhật thông tin thất bại.';
                          });
                          return;
                        }

                        // 2. Cập nhật dữ liệu trong Firestore
                        await FirebaseFirestore.instance
                            .collection('residents')
                            .doc(resident.residentId)
                            .update({
                          'fullName': updatedFullName,
                          'cccd': cccdController.text,
                          'birthDate': DateFormat('dd/MM/yyyy').parse(birthDateController.text),
                          'email': newEmail,
                          'phone': phoneController.text,
                        });

                        // 3. Cập nhật fullName trong danh sách residents của apartment
                        final apartmentRef = FirebaseFirestore.instance
                            .collection('apartments')
                            .doc(resident.apartmentId);

                        final apartmentDoc = await apartmentRef.get();
                        final residentsList = List<Map<String, dynamic>>.from(apartmentDoc.data()?['residents'] ?? []);

                        final updatedResidents = residentsList.map((res) {
                          if (res['id'] == resident.residentId) {
                            return {
                              ...res,
                              'fullName': updatedFullName,
                            };
                          }
                          return res;
                        }).toList();

                        await apartmentRef.update({'residents': updatedResidents});

                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          loadData();
                        });
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Cập nhật thất bại: $e';
                        });
                      }
                    } else {
                      setState(() {
                        isEditing = true;
                      });
                    }

                  },
                  child: Text(isEditing ? 'Lưu' : 'Sửa'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Đóng'),
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
          rentPrice: 0,
          salePrice: 0,
          description: '',
          isRent: false,
          isSale: false,
          residents: [],
        ),
      );

      if (selectedApartment != null) {
        return r.apartmentId == selectedApartment!.id;
      } else if (selectedBuilding != null && selectedFloor != null) {
        return apt.building == selectedBuilding && apt.floor == selectedFloor;
      } else if (selectedBuilding != null) {
        return apt.building == selectedBuilding;
      }
      // Tìm kiếm theo tên cư dân
      if (_searchQuery.isNotEmpty) {
        return r.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return true; // chưa chọn gì thì hiển thị tất cả
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 70.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Danh sách cư dân",
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 360.h,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                              SizedBox(
                                width: double.infinity,
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Tìm kiếm cư dân",
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                  ),
                                  onChanged: _onSearchChanged, // Gọi hàm debounce khi nhập
                                ),
                              ),
                                SizedBox(height: 30.h,),
                                // Tòa nhà
                                buildFilterDropdown<String>(
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
                                const SizedBox(height: 12),

                                // Tầng
                                buildFilterDropdown<int>(
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
                                const SizedBox(height: 12),

                                // Căn hộ
                                buildFilterDropdown<Apartment>(
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Vertical Divider
                          VerticalDivider(
                            color: Colors.grey, // Màu của đường ngăn cách
                            thickness: 0.2.w, // Độ dày của đường ngăn cách
                            width: 40.w, // Chiều rộng tổng thể của vùng ngăn cách (bao gồm cả padding nếu có)
                          ),

                          Expanded(
                            child: matchedResidents.isEmpty
                                ? const Center(child: Text("Không có cư dân."))
                                : GridView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h), // Thêm padding để tạo khoảng trống
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Hiển thị 2 cột
                                mainAxisSpacing: 30.h, // Khoảng cách giữa các hàng
                                crossAxisSpacing: 5.w, // Khoảng cách giữa các cột
                                childAspectRatio: 6 / 2.5, // Tỉ lệ chiều rộng / chiều cao của mỗi phần tử
                              ),
                              itemCount: matchedResidents.length,
                              itemBuilder: (context, index) {
                                final resident = matchedResidents[index];
                                return GestureDetector(
                                  onTap: () => _showResidentDetails(context, resident), // Mở dialog chi tiết cư dân
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(1.w, 25.h, 1.w, 0.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 6.r,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(width: 5.w),
                                            Stack(
                                              children: [
                                                // Ảnh cư dân
                                                Container(
                                                  width: 17.w,
                                                  height: 80.h,
                                                  child: CircleAvatar(
                                                    radius: 8.r,
                                                    backgroundImage: (resident.imageUrl != null && resident.imageUrl!.isNotEmpty)
                                                        ? NetworkImage(resident.imageUrl!)
                                                        : null, // Chỉ sử dụng NetworkImage nếu imageUrl hợp lệ
                                                    child: (resident.imageUrl == null || resident.imageUrl!.isEmpty)
                                                        ? Icon(
                                                      Icons.person,
                                                      size: 8.r * 4, // Kích thước icon phù hợp với radius
                                                      color: Colors.grey, // Màu của biểu tượng
                                                    ) // Hiển thị icon nếu imageUrl không hợp lệ
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 5.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    resident.fullName,
                                                    style: TextStyle(
                                                      fontFamily: "Oswald",
                                                      fontSize: 4.5.sp,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 10.h),
                                                  Text(
                                                    "CCCD: ${resident.cccd}",
                                                    style: TextStyle(
                                                      fontSize: 3.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),                        ],
                      ),
                    )
                  ],
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
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

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
                color: Colors.black,
                fontSize: 4.sp,
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
                color: const Color(0xFFF7FEFF),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200.h,
              width: 139.w ,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                color: const Color(0xFFF7FEFF),
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
