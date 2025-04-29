import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContractReviewPage extends StatelessWidget {
  final ContractData contractData;

  ContractReviewPage({required this.contractData});

  @override
  Widget build(BuildContext context) {
    final representativeNames = contractData.residents.map((r) => r.fullName).toList();
    String? selectedRep = representativeNames.first;

    return Scaffold(
      appBar: AppBar(title: Text("Xác nhận hợp đồng")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Căn hộ: ${contractData.apartmentName}"),
            Text("Diện tích: ${contractData.area} m²"),
            Text("Loại hợp đồng: ${contractData.contractType}"),
            Text("Thời gian: ${contractData.startDate} - ${contractData.endDate}"),
            Text("Số người ở: ${contractData.numberOfResidents}"),
            DropdownButton<String>(
              value: selectedRep,
              items: representativeNames.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) => selectedRep = value,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: Text("Quay lại")),
                ElevatedButton(
                  onPressed: () async {
                    await saveToFirestore(contractData, selectedRep!);
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
    // Tạo hợp đồng
    final contractDoc = FirebaseFirestore.instance.collection("contracts").doc();
    await contractDoc.set({
      "apartmentName": contract.apartmentName,
      "building": contract.building,
      "area": contract.area,
      "price": contract.contractType == "rent" ? contract.rentPrice : contract.salePrice,
      "type": contract.contractType,
      "startDate": contract.startDate,
      "endDate": contract.endDate,
      "representative": representative,
      "numberOfResidents": contract.numberOfResidents,
    });

    // Lưu từng cư dân
    for (final resident in contract.residents) {
      await contractDoc.collection("residents").add({
        "name": resident.fullName,
        "cccd": resident.cccd,
        "phone": resident.phone,
        "birthDate": resident.birthDate,
        "email": resident.email,
      });
    }

    // Cập nhật trạng thái thuê hoặc bán của căn hộ
    final apartmentRef = FirebaseFirestore.instance
        .collection("apartments")
        .doc(contract.apartmentName); // Đây là collection đúng

    await apartmentRef.update({
      contract.contractType == "rent" ? "isRent" : "isSale": true,
    });
  }
}
