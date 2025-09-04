import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ResidentProvider with ChangeNotifier {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> _residents = [];

  List<Map<String, dynamic>> get residents => _residents;

  ResidentProvider() {
    _fetchResidents();
  }

  void _fetchResidents() async {
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
      notifyListeners();
    }
  }

  Future<void> updateResident(String id, Map<String, dynamic> updatedData) async {
    await _databaseRef.child(id).update(updatedData);

    final index = _residents.indexWhere((resident) => resident['id'] == id);
    if (index != -1) {
      _residents[index] = {
        ..._residents[index],
        ...updatedData,
      };
      notifyListeners();
    }
  }

  Future<void> deleteResident(String id) async {
    try {
      await _databaseRef.child(id).remove();
      _residents.removeWhere((resident) => resident['id'] == id);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
