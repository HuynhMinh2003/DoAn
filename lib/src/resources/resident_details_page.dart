import 'package:do_an/src/resources/provider/resident_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Thêm import intl

class ResidentDetailsPage extends StatelessWidget {
  final String residentId;

  const ResidentDetailsPage({super.key, required this.residentId});

  @override
  Widget build(BuildContext context) {
    final residentProvider = Provider.of<ResidentProvider>(context);
    final resident = residentProvider.residents
        .firstWhere((element) => element['id'] == residentId);

    // Chuyển đổi birthDate
    String formatDate(String date) {
      try {
        final parsedDate = DateTime.parse(date); // Parse từ chuỗi ISO
        return DateFormat('dd-MM-yyyy').format(parsedDate); // Định dạng lại
      } catch (e) {
        return date; // Nếu lỗi, trả về giá trị ban đầu
      }
    }

    void updateResident() {
      final updatedData = {
        'isApproved': true,
      };

      residentProvider.updateResident(residentId, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công!')),
      );
      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cư dân'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên: ${resident['name']}'),
            const SizedBox(height: 8),
            Text('Ngày sinh: ${formatDate(resident['birthDate'])}'), // Sử dụng formatDate
            const SizedBox(height: 8),
            Text('Email: ${resident['email']}'),
            const SizedBox(height: 8),
            Text('Số CCCD: ${resident['cccd']}'),
            const SizedBox(height: 8),
            Text('SĐT: ${resident['phone']}'),
            const SizedBox(height: 8),
            Text('Tên căn hộ: ${resident['nameHouse']}'),
            const SizedBox(height: 8),
            Text('Diện tích căn hộ: ${resident['area']}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateResident,
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}
