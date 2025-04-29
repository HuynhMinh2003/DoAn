import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/contract_data.dart';
import 'package:do_an/src/resources/resident_info_page.dart';
import 'package:flutter/material.dart';

class ContractInfoPage extends StatefulWidget {
  final Apartment apartmentData;
  final String contractType;

  ContractInfoPage({required this.apartmentData, required this.contractType});


  @override
  _ContractInfoPageState createState() => _ContractInfoPageState();
}

class _ContractInfoPageState extends State<ContractInfoPage> {
  int selectedPeople = 1;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final area = widget.apartmentData.area;
    final rentPrice = widget.apartmentData.rentPrice;
    final salePrice = widget.apartmentData.salePrice;

    return Scaffold(
      appBar: AppBar(title: Text("Thông tin hợp đồng")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Căn hộ: ${widget.apartmentData.apartmentName}"),
            Text("Diện tích: $area m²"),
            Text("Giá: ${widget.contractType == 'rent' ? rentPrice : salePrice} VND"),

            DropdownButton<int>(
              value: selectedPeople,
              items: List.generate(10, (index) => index + 1)
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e người')))
                  .toList(),
              onChanged: (value) => setState(() => selectedPeople = value!),
            ),

            if (widget.contractType == 'rent')
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: now.add(Duration(days: 30)),
                    firstDate: now.add(Duration(days: 30)),
                    lastDate: now.add(Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => endDate = picked);
                },
                child: Text(endDate == null
                    ? "Chọn ngày kết thúc"
                    : "Đến: ${endDate!.toLocal().toString().split(' ')[0]}"),
              ),

            Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: Text("Quay lại")),
                ElevatedButton(
                  onPressed: () {
                    final contractData = ContractData(
                      apartmentName: widget.apartmentData.apartmentName,
                      building: widget.apartmentData.building,
                      area: area.toDouble(),
                      rentPrice: rentPrice,
                      salePrice: salePrice,
                      contractType: widget.contractType,
                      startDate: now,
                      endDate: endDate,
                      numberOfResidents: selectedPeople,
                      residents: [],
                    );
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ResidentInfoPage(contractData: contractData),
                    ));
                  },
                  child: Text("Tiếp tục"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
