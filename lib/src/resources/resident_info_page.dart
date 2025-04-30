import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:do_an/src/resources/contract_review_page.dart';
import 'package:flutter/material.dart';

class ResidentInfoPage extends StatefulWidget {
  final ContractData contractData;

  ResidentInfoPage({required this.contractData});

  @override
  _ResidentInfoPageState createState() => _ResidentInfoPageState();
}

class _ResidentInfoPageState extends State<ResidentInfoPage> {
  List<ResidentInfo> residents = [];
  int currentIndex = 0;

  final nameController = TextEditingController();
  final cccdController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  DateTime? birthDate;

  void nextResident() {
    residents.add(ResidentInfo(
      fullName: nameController.text,
      cccd: cccdController.text,
      phone: phoneController.text,
      email: emailController.text,
      birthDate: birthDate!,
    ));

    if (residents.length < widget.contractData.numberOfResidents) {
      setState(() {
        currentIndex++;
        nameController.clear();
        cccdController.clear();
        phoneController.clear();
        emailController.clear();
        birthDate = null;
      });
    } else {
      final updatedContract = widget.contractData.copyWith(residents: residents);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ContractReviewPage(contractData: updatedContract),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cư dân ${currentIndex + 1}")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Họ tên")),
            TextField(controller: cccdController, decoration: InputDecoration(labelText: "CCCD")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "SĐT")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),

            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => birthDate = picked);
              },
              child: Text(birthDate == null ? "Ngày sinh" : "${birthDate!.toLocal()}".split(' ')[0]),
            ),

            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        residents.removeLast();
                        currentIndex--;
                      });
                    },
                    child: Text("Quay lại"),
                  ),
                ElevatedButton(onPressed: nextResident, child: Text("Tiếp tục")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
