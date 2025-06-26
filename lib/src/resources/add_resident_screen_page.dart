import 'dart:convert';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pool/pool.dart';

import '../../constants.dart';

class AddResidentsScreen extends StatefulWidget {
  final int count;
  final Apartment apartment;
  final Contract contract;
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

// Hàm xử lý submit
  Future<void> _submit() async {
    LoadingDialog.showLoadingDialog(context, "Đang tải ...");

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
      if (mounted) {
        LoadingDialog.hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vui lòng kiểm tra lại thông tin cư dân.")),
        );
      }
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    final residentCollection = FirebaseFirestore.instance.collection('residents');
    final apartmentRef = FirebaseFirestore.instance.collection("apartments").doc(widget.apartment.id);

    List<Map<String, dynamic>> newResidentObjects = [];
    List<String> newResidentNames = [];
    List<ResidentInfo> failedResidents = [];
    List<ResidentInfo> successfulResidents = [];

    try {
      final apartmentSnapshot = await apartmentRef.get();
      final existingResidents = List<Map<String, dynamic>>.from(apartmentSnapshot.data()?['residents'] ?? []);

      final pool = Pool(3);

      for (final resident in residents) {
        await pool.withResource(() async {
          int retryCount = 0;
          const maxRetries = 3;
          bool success = false;

          while (retryCount < maxRetries && !success) {
            try {
              final existingData = await checkExistingResident(resident.cccd, resident.email);

              if (existingData != null) {
                final shouldProceed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Center(child: Text("Cư dân đã tồn tại", style: TextStyle(fontSize: 5.sp))),
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
                          child: Text("Hủy", style: TextStyle(fontSize: 3.5.sp, color: Colors.white)),
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
                  failedResidents.add(resident);
                  return;
                }
              }

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
                  'apartmentId': widget.apartment.id,
                  'contractId': widget.contract.contractId,
                  if (existingData != null) ...{
                    'residentId': existingData['residentId'],
                    'imageUrl': existingData['imageUrl'],
                  },
                }),
              );

              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                final newResidentId = data['residentId'];

                final docRef = residentCollection.doc(newResidentId);

                batch.set(
                  docRef,
                  resident.copyWith(
                    residentId: newResidentId,
                    apartmentId: widget.apartment.id,
                  ).toMap(),
                  SetOptions(merge: true),
                );

                newResidentObjects.add({'id': newResidentId, 'fullName': resident.fullName});
                newResidentNames.add(resident.fullName);
                successfulResidents.add(resident);
                success = true;
              } else {
                failedResidents.add(resident);
                break;
              }
            } catch (e) {
              print("❌ Lỗi xử lý ${resident.fullName}: $e");
              retryCount++;
              if (retryCount >= maxRetries) {
                failedResidents.add(resident);
              }
            }
          }
        });
      }

      if (newResidentObjects.isNotEmpty) {
        final updatedResidents = [...existingResidents];

        for (final newR in newResidentObjects) {
          if (!updatedResidents.any((r) => r['id'] == newR['id'])) {
            updatedResidents.add(newR);
          }
        }

        batch.update(apartmentRef, {
          'residents': updatedResidents,
        });

        final apartmentDoc = await apartmentRef.get();
        final currentContractId = apartmentDoc.data()?['currentContractId'];

        if (currentContractId != null) {
          final contractRef = FirebaseFirestore.instance.collection("contracts").doc(currentContractId);
          final contractSnap = await contractRef.get();
          final currentCount = contractSnap.data()?['numberOfResidents'] ?? 0;

          final logRef = contractRef.collection("contractHistory").doc();
          batch.set(logRef, {
            'action': 'Thêm cư dân',
            'performedBy': 'Admin',
            'residents': newResidentNames,
            'timestamp': Timestamp.now(),
          });

          batch.update(contractRef, {
            'numberOfResidents': currentCount + successfulResidents.length,
          });
        }
      }

      await batch.commit();

      if (mounted) {
        LoadingDialog.hideLoadingDialog(context);
        widget.onComplete();

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Center(child: Text("Thành công")),
              content: Text(
                failedResidents.isEmpty
                    ? "Cư dân cập nhật thành công!"
                    : "Một số cư dân đã bị bỏ qua:\n${failedResidents.map((r) => r.fullName).join(', ')}",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back
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
      if (mounted) {
        LoadingDialog.hideLoadingDialog(context);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Center(child: Text("Thất bại")),
              content: const Text("Cư dân cập nhật thất bại!"),
              actions: [
                TextButton(
                  onPressed: () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('      Nhập thông tin cư dân', style: TextStyle(fontSize: 8.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),),backgroundColor: bgColor,),
      body:SafeArea(
          child: Stack(
        children: [
          Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 20.h),
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
              SizedBox(height: 20.h),
              Expanded(child: ListView.builder(
                itemCount: widget.count,
                itemBuilder: (context, index) {
                  return Form(
                    key: formKeys[index],
                    child: Card(
                      margin: EdgeInsets.only(bottom: 30.h),
                      elevation: 2,
                      color: secondaryColor,
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
                                    Text("Giới tính", style: TextStyle(fontSize: 5.sp)),
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

              SizedBox(
                height: 50.h,
                width: 50.w,
                child: ElevatedButton(
                  onPressed:() async {
                    await _submit();
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
