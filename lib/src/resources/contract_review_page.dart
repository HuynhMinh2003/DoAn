import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text("Xác nhận hợp đồng")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Căn hộ: ${widget.contractData.apartmentName}"),
            Text("Diện tích: ${widget.contractData.area} m²"),
            Text("Loại hợp đồng: ${widget.contractData.contractType}"),
            Text("Thời gian: ${widget.contractData.startDate} - ${widget.contractData.endDate}"),
            Text("Số người ở: ${widget.contractData.numberOfResidents}"),
            DropdownButton<String>(
              value: selectedRep,
              items: representativeNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => setState(() {
                selectedRep = value;
              }),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: Text("Quay lại")),
                ElevatedButton(
                  onPressed: () async {
                    await saveToFirestore(widget.contractData, selectedRep!);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text("Tạo hợp đồng"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> saveToFirestore(ContractData contract, String representative) async {
    final apartmentRef = FirebaseFirestore.instance.collection("apartments").doc(contract.apartmentDocId);

    // Tạo document hợp đồng trong subcollection "contracts" của căn hộ
    final contractDoc = apartmentRef.collection("contracts").doc();

    // Lưu thông tin hợp đồng
    await contractDoc.set({
      "apartmentDocId": contract.apartmentDocId,
      "apartmentName": contract.apartmentName,
      "building": contract.building,
      "area": contract.area,
      "price": contract.contractType == "rent" ? contract.rentPrice : contract.salePrice,
      "type": contract.contractType,
      "startDate": contract.startDate,
      "endDate": contract.endDate,
      "representative": representative,
      "numberOfResidents": contract.numberOfResidents,
      "createdAt": Timestamp.now(),
    });

    // Lưu từng cư dân vào subcollection "residents" trong hợp đồng và tạo tài khoản
    for (final resident in contract.residents) {
      final password = await generateRandomPassword();

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: resident.email, password: password);

        final uid = userCredential.user!.uid;

        await contractDoc.collection("residents").doc(uid).set({
          "name": resident.fullName,
          "cccd": resident.cccd,
          "phone": resident.phone,
          "birthDate": resident.birthDate,
          "email": resident.email,
          "role": 3,
          "fcmTokens": [],
          "createdAt": Timestamp.now(),
        });

        print("Tạo tài khoản cho ${resident.fullName} - Mật khẩu: $password");

        // TODO: Gửi email qua Cloud Function nếu cần

      } catch (e) {
        print("Lỗi khi tạo user cho ${resident.fullName}: $e");
      }
    }

    // Cập nhật danh sách cư dân cho căn hộ
    final residentNames = contract.residents.map((r) => r.fullName).toList();

    await apartmentRef.update({
      contract.contractType == "rent" ? "isRent" : "isSale": true,
      "residents": residentNames,
    });

    // Tạo hóa đơn nước đầu tiên trong subcollection "billWater"
    final billRef = apartmentRef.collection("billWater").doc(); // Tạo bill mới

    await billRef.set({
      "month": DateFormat("yyyy-MM").format(DateTime.now()), // Ví dụ: "2025-04"
      "oldMeterReading": 0,
      "newMeterReading": 0,
      "totalAmount": 0,
      "photoURL": "",
      "createdAt": Timestamp.now(),
    });
  }
}
