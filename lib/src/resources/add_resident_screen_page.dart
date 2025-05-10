import 'dart:convert';
import 'package:do_an/src/resources/back_button.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddResidentsScreen extends StatefulWidget {
  final int count;
  final Apartment apartment;
  final ContractData contract;
  final VoidCallback onComplete;

  const AddResidentsScreen({
    super.key,
    required this.count,
    required this.apartment,
    required this.contract,
    required this.onComplete,
  });

  @override
  State<AddResidentsScreen> createState() => _AddResidentsScreenState();
}

class _AddResidentsScreenState extends State<AddResidentsScreen> {
  late List<AuthBloc> _authBloc;

  late List<GlobalKey<FormState>> formKeys;
  late List<ResidentInfo> residents;
  bool isLoading = false; // Trạng thái loading


  @override
  void initState() {
    super.initState();
    _authBloc = List.generate(widget.count, (_) => AuthBloc());
    formKeys = List.generate(widget.count, (_) => GlobalKey<FormState>());
    residents = List.generate(widget.count, (_) => ResidentInfo(
      fullName: '',
      cccd: '',
      address: '',
      phone: '',
      gender: '',
      email: '',
      birthDate: null, // Default birth date
    ));
  }

  @override
  void dispose(){
    for (final bloc in _authBloc) {
      bloc.dispose();
    }
    super.dispose();
  }

// Hàm xử lý submit
  Future<void> _submit() async {
    LoadingDialog.showLoadingDialog(context,"Đang tải ...");

    bool isValid = true;

    for (int i = 0; i < residents.length; i++) {
      final r = residents[i];
      final isCurrentValid = _authBloc[i].isValidResidentSignUp(
        r.fullName,
        r.email,
        r.phone,
        r.cccd,
        r.address,
        r.gender,
        r.birthDate,
      );
      if (!isCurrentValid) isValid = false;
    }

    if (!isValid) {
      setState(() {
        isLoading = false; // Tắt loading nếu không hợp lệ
      });
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    final residentCollection = FirebaseFirestore.instance.collection('residents');
    final apartmentRef = FirebaseFirestore.instance.collection("apartments").doc(widget.apartment.id);

    List<Map<String, dynamic>> newResidentObjects = [];
    List<String> newResidentNames = [];

    try {
      final apartmentSnapshot = await apartmentRef.get();
      final existingResidents = List<Map<String, dynamic>>.from(apartmentSnapshot.data()?['residents'] ?? []);

      for (final resident in residents) {
        final uid = await _createResidentAccount(
          resident.email,
          resident.fullName,
          resident.cccd,
          resident.address,
          resident.gender,
          resident.phone,
          resident.birthDate,
        );

        if (uid == null) {
          print("⚠️ Không thể lấy UID cho ${resident.fullName}, bỏ qua.");
          continue;
        }

        final docRef = residentCollection.doc(uid);
        batch.set(docRef, resident.copyWith(residentId: uid, apartmentId: widget.apartment.id).toMap());

        final residentObj = {
          'id': uid,
          'fullName': resident.fullName,
        };
        newResidentObjects.add(residentObj);
        newResidentNames.add(resident.fullName);
      }

      if (newResidentObjects.isNotEmpty) {
        final updatedResidents = List<Map<String, dynamic>>.from(existingResidents);
        for (final newR in newResidentObjects) {
          final alreadyExists = updatedResidents.any((r) => r['id'] == newR['id']);
          if (!alreadyExists) updatedResidents.add(newR);
        }

        batch.update(apartmentRef, {
          'residents': updatedResidents,
        });

        final logRef = apartmentRef.collection("updateHistory").doc();
        batch.set(logRef, {
          'action': 'Thêm cư dân',
          'performedBy': 'Admin',
          'residentNames': newResidentNames,
          'timestamp': Timestamp.now(),
        });

        final contractRef = apartmentRef
            .collection("contract")
            .doc(widget.contract.contractId);
        batch.update(contractRef, {
          'numberOfResidents': widget.contract.numberOfResidents + newResidentObjects.length,
        });
      }

      await batch.commit();

      widget.onComplete();

      LoadingDialog.hideLoadingDialog(context);

      // Hiển thị dialog thành công
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(child: Text("Thành công"),),
              content: const Text("Cư dân cập nhật thành công!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                    Navigator.pop(context); // Quay lại trang trước
                    Navigator.pop(context);
                  },
                  child: const Text("Đồng ý"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("❌ Lỗi khi commit batch: $e");
      LoadingDialog.hideLoadingDialog(context);

      // Hiển thị dialog thành công
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(child: Text("Thất bại"),),
              content: const Text("Cư dân cập nhật thất bại!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                    Navigator.pop(context); // Quay lại trang trước
                    Navigator.pop(context);
                  },
                  child: const Text("Đồng ý"),
                ),
              ],
            );
          },
        );
      }
    }
  }

// Hàm gọi Firebase Function để tạo tài khoản cư dân
  Future<String?> _createResidentAccount(String email, String fullName, String cccd, String address, String gender, String phone, DateTime? birthDate) async {
    final url = 'https://createresidentaccount-ttrkrlo35a-uc.a.run.app'; // Thay thế với URL Firebase function của bạn
    final headers = {'Content-Type': 'application/json'};

    // Chuyển birthDate thành chuỗi ISO 8601 nếu có
    String birthDateString = birthDate?.toIso8601String() ?? '';

    final body = json.encode({
      'email': email,
      'fullName': fullName,
      'cccd': cccd,
      'address': address,
      'gender': gender,
      'phone': phone,
      'birthDate': birthDateString, // Gửi birthDate dưới dạng chuỗi
      'apartmentId': widget.apartment.id,
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Tạo tài khoản cư dân thành công.');
        return responseData['residentId'];
      } else {
        throw Exception('Tạo tài khoản cư dân thất bại: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gọi Firebase function: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF7FEFF),
      body:SafeArea(child: Stack(
        children: [
          Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 70.h),
          child: Column(
            children: [
              Text(
                "Thêm ${widget.count} cư dân",
                style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 40.h),
              Expanded(child: ListView.builder(
                itemCount: widget.count,
                itemBuilder: (context, index) {
                  return Form(
                    key: formKeys[index],
                    child: Card(
                      margin: EdgeInsets.only(bottom: 30.h),
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        side: BorderSide(
                          color: Colors.black, // Màu viền bạn muốn
                          width: 0.1.w,         // Độ dày của viền
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(30.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cư dân ${index + 1}", style: TextStyle(fontFamily:"Oswald",fontWeight: FontWeight.bold,fontSize: 6.sp)),

                            // Họ tên
                            StreamBuilder<String>(
                              stream: _authBloc[index].nameResidentStream,
                              builder: (context, snapshot) => TextField(
                                decoration: InputDecoration(
                                  labelText: "Họ tên",
                                  labelStyle: TextStyle(fontSize: 5.sp),
                                  errorText: snapshot.hasError ? snapshot.error.toString() : null,
                                ),
                                onChanged: (val) {
                                  _authBloc[index].changeName(val);
                                  residents[index] = residents[index].copyWith(fullName: val);
                                },
                              ),
                            ),

                            // Giới tính
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              child: StreamBuilder<String>(
                                stream: _authBloc[index].genderResidentStream,
                                builder: (context, snapshot) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Giới tính", style: TextStyle(fontSize: 5.sp, fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Radio<String>(
                                          value: 'Nam',
                                          groupValue: residents[index].gender,
                                          onChanged: (val) {
                                            setState(() {
                                              residents[index] = residents[index].copyWith(gender: val!);
                                            });
                                            _authBloc[index].changeGender(val!); // BLoC cập nhật stream
                                          },
                                        ),
                                        Text('Nam', style: TextStyle(fontSize: 5.sp)),
                                        SizedBox(width: 16.w),
                                        Radio<String>(
                                          value: 'Nữ',
                                          groupValue: residents[index].gender,
                                          onChanged: (val) {
                                            setState(() {
                                              residents[index] = residents[index].copyWith(gender: val!);
                                            });
                                            _authBloc[index].changeGender(val!); // BLoC cập nhật stream
                                          },
                                        ),
                                        Text('Nữ', style: TextStyle(fontSize: 5.sp)),
                                        SizedBox(width: 16.w),
                                        Radio<String>(
                                          value: 'Khác',
                                          groupValue: residents[index].gender,
                                          onChanged: (val) {
                                            setState(() {
                                              residents[index] = residents[index].copyWith(gender: val!);
                                            });
                                            _authBloc[index].changeGender(val!); // BLoC cập nhật stream
                                          },
                                        ),
                                        Text('Khác', style: TextStyle(fontSize: 5.sp)),
                                      ],
                                    ),
                                    if (snapshot.hasError)
                                      Text(
                                        snapshot.error.toString(),
                                        style: TextStyle(color: Colors.red, fontSize: 4.sp),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // CCCD
                            StreamBuilder<String>(
                              stream: _authBloc[index].cccdResidentStream,
                              builder: (context, snapshot) => TextField(
                                decoration: InputDecoration(
                                  labelText: "CCCD",
                                  labelStyle: TextStyle(fontSize: 5.sp),
                                  errorText: snapshot.hasError ? snapshot.error.toString() : null,
                                ),
                                onChanged: (val) {
                                  _authBloc[index].changeCCCD(val);
                                  residents[index] = residents[index].copyWith(cccd: val);
                                },
                              ),
                            ),

                            // Email
                            StreamBuilder<String>(
                              stream: _authBloc[index].emailResidentStream,
                              builder: (context, snapshot) => TextField(
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  labelStyle: TextStyle(fontSize: 5.sp),
                                  errorText: snapshot.hasError ? snapshot.error.toString() : null,
                                ),
                                onChanged: (val) {
                                  _authBloc[index].changeEmail(val);
                                  residents[index] = residents[index].copyWith(email: val);
                                },
                              ),
                            ),

                            // SĐT
                            StreamBuilder<String>(
                              stream: _authBloc[index].phoneResidentStream,
                              builder: (context, snapshot) => TextField(
                                decoration: InputDecoration(
                                  labelText: "SĐT",
                                  labelStyle: TextStyle(fontSize: 5.sp),
                                  errorText: snapshot.hasError ? snapshot.error.toString() : null,
                                ),
                                onChanged: (val) {
                                  _authBloc[index].changePhone(val);
                                  residents[index] = residents[index].copyWith(phone: val);
                                },
                              ),
                            ),

                            StreamBuilder<String>(
                              stream: _authBloc[index].addressResidentStream,
                              builder: (context, snapshot) => TextField(
                                decoration: InputDecoration(
                                  labelText: 'Địa chỉ',
                                  labelStyle: TextStyle(fontSize: 5.sp),
                                  errorText: snapshot.hasError ? snapshot.error.toString() : null,
                                ),
                                onChanged: (val) {
                                  _authBloc[index].changeAddress(val);
                                  residents[index] = residents[index].copyWith(address: val);
                                },
                              ),
                            ),

                            StreamBuilder<DateTime?>(
                              stream: _authBloc[index].birthDateStream,
                              builder: (context, snapshot) {
                                final selectedDate = residents[index].birthDate;
                                final displayDate = selectedDate == DateTime.now()
                                    ? ""
                                    : "${selectedDate?.toLocal()}".split(' ')[0];

                                final controller = TextEditingController(text: displayDate);

                                return Padding(
                                  padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 15.h),
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: "Ngày sinh",
                                      labelStyle: TextStyle(fontSize: 5.5.sp),
                                      hintText: "Chưa chọn",
                                      errorText: snapshot.hasError ? snapshot.error.toString() : null,
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.calendar_today),
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate == DateTime.now() ? DateTime(2000) : selectedDate,
                                            firstDate: DateTime(1950),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              residents[index] =
                                                  residents[index].copyWith(birthDate: picked);
                                            });
                                            _authBloc[index].changeBirthDate(picked); // BLoC cập nhật stream
                                          }
                                        },
                                      ),
                                    ),
                                    readOnly: true,
                                  ),
                                );
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),),

              SizedBox(height: 20.h,),

              ElevatedButton(
                onPressed:() async {
                  await _submit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D80F8),
                  minimumSize: Size(60.w, 60.h), // ✅ Chiều rộng và cao mong muốn
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black45,
                  alignment: Alignment.center,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  "Xác nhận thêm",
                  style: TextStyle(
                    fontFamily: "Oswald",
                    fontWeight: FontWeight.w700,
                    fontSize: 7.sp,
                    color: Colors.white,
                    height: 1.h,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 40.h,),

            ],
          )
          ),
        ],
      ))

    );
  }

}
