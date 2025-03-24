import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ResidentProvider with ChangeNotifier {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> _residents = [];

  List<Map<String, dynamic>> get residents => _residents;

  ResidentProvider() {
    _fetchResidents();
  }

  // Hàm lấy danh sách cư dân từ Firebase
  void _fetchResidents() async {
    try {
      final event = await _databaseRef.once();
      final data = event.snapshot.value as Map?;

      if (data != null) {
        final filteredData = data.entries
            .where((entry) => (entry.value as Map)['role'] == 0)
            .map((entry) => {
          "id": entry.key,
          ...Map<String, dynamic>.from(entry.value),
        })
            .toList();

        _residents = filteredData;
        notifyListeners(); // Gọi notifyListeners để cập nhật UI
      }
    } catch (error) {
      print("Lỗi khi lấy dữ liệu từ Firebase: $error");
    }
  }

  // Hàm cập nhật thông tin cư dân trong Firebase và danh sách cục bộ
  Future<void> updateResident(String id, Map<String, dynamic> updatedData) async {
    try {
      await _databaseRef.child(id).update(updatedData); // Cập nhật vào Firebase

      // Tìm và cập nhật thông tin cư dân trong danh sách cục bộ
      final index = _residents.indexWhere((resident) => resident['id'] == id);
      if (index != -1) {
        _residents[index] = {
          ..._residents[index],
          ...updatedData,
        };
        notifyListeners(); // Cập nhật giao diện
      }
    } catch (error) {
      print("Lỗi khi cập nhật cư dân: $error");
    }
  }

  // Hàm xóa cư dân khỏi Firebase và danh sách cục bộ
  Future<void> deleteResident(String id) async {
    try {
      await _databaseRef.child(id).remove(); // Xóa trong Firebase
      _residents.removeWhere((resident) => resident['id'] == id); // Xóa trong danh sách cục bộ
      notifyListeners(); // Cập nhật giao diện
    } catch (error) {
      print("Lỗi khi xóa cư dân: $error");
      rethrow; // Để ném lại lỗi nếu cần xử lý thêm bên ngoài
    }
  }
}
