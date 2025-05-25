import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../models/staffs.dart';

class ManagerIncidentPage extends StatefulWidget {
  const ManagerIncidentPage({super.key});

  @override
  State<ManagerIncidentPage> createState() => _ManagerIncidentPageState();
}

class _ManagerIncidentPageState extends State<ManagerIncidentPage> {
  List<Incident> _pendingIncidents = [];
  String? _selectedPriority;
  Staff? _selectedStaff;
  List<Staff> _allStaffs = [];

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _loadStaffs();
  }

  Future<void> _loadIncidents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('incidents')
        .where('status', isEqualTo: 'Đang chờ xử lý')
        .get();

    setState(() {
      _pendingIncidents =
          snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
    });
  }

  Future<void> _loadStaffs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('staffs')
        .where('role', isEqualTo: 2) // Lọc đúng role
        .get();

    setState(() {
      _allStaffs =
          snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList();
    });
  }

  void _openAssignDialog(Incident incident) {
    final _noteController = TextEditingController();
    _selectedPriority = incident.priority ?? 'Trung bình';
    _selectedStaff = null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Giao sự cố cho nhân viên'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Priority
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration:
                    const InputDecoration(labelText: 'Mức độ ưu tiên'),
                    items: ['Cao', 'Trung bình', 'Thấp']
                        .map((level) => DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Staff dropdown (hiển thị toàn bộ role = 2, nhưng chỉ cho chọn isFree == true)
                  DropdownButtonFormField<Staff>(
                    value: _selectedStaff,
                    decoration:
                    const InputDecoration(labelText: 'Chọn nhân viên'),
                    items: _allStaffs.map((staff) {
                      return DropdownMenuItem<Staff>(
                        value: staff,
                        enabled: staff.isFree,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: staff.isFree ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(staff.fullName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (staff) {
                      if (staff?.isFree == true) {
                        setState(() {
                          _selectedStaff = staff;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                        labelText: 'Ghi chú cho nhân viên (nếu có)'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _selectedStaff == null
                ? null
                : () async {
              Navigator.pop(context);
              await _assignToStaff(
                incident,
                _noteController.text.trim(),
                _selectedStaff!,
                _selectedPriority ?? 'Trung bình',
              );
            },
            child: const Text('Xác nhận giao'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignToStaff(
      Incident incident,
      String managerNote,
      Staff staff,
      String priority,
      ) async {
    final batch = FirebaseFirestore.instance.batch();

    final incidentRef =
    FirebaseFirestore.instance.collection('incidents').doc(incident.id);
    batch.update(incidentRef, {
      'assignedStaffId': staff.uid,
      'assignedStaffName': staff.fullName,
      'status': 'Đã giao',
      'priority': priority,
      'managerNote': managerNote,
    });

    final staffRef =
    FirebaseFirestore.instance.collection('staffs').doc(staff.uid);
    batch.update(staffRef, {'isFree': false});

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã giao cho ${staff.fullName}')),
    );

    _loadIncidents();
    _loadStaffs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sự cố cư dân')),
      body: _pendingIncidents.isEmpty
          ? const Center(child: Text('Không có sự cố nào chờ xử lý'))
          : ListView.builder(
        itemCount: _pendingIncidents.length,
        itemBuilder: (context, index) {
          final incident = _pendingIncidents[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tiêu đề: ${incident.title}",
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Người báo: ${incident.reporterName}"),
                  Text(
                      "Căn hộ: ${incident.apartmentAddress}, Toà: ${incident.building}"),
                  Text("Mô tả: ${incident.description}"),
                  if (incident.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network(incident.imageUrl!,
                          height: 150),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      child: const Text("Giao xử lý"),
                      onPressed: () => _openAssignDialog(incident),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
