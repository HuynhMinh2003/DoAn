import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StaffIncidentPage extends StatefulWidget {
  final String staffId;
  const StaffIncidentPage({super.key, required this.staffId});

  @override
  State<StaffIncidentPage> createState() => _StaffIncidentPageState();
}

class _StaffIncidentPageState extends State<StaffIncidentPage> {
  List<DocumentSnapshot> _assignedIncidents = [];
  File? _proofImageFile;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssignedIncidents();
  }

  Future<void> _loadAssignedIncidents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('incidents')
        .where('status', isEqualTo: 'Đang xử lí')
        .where('assignedStaffId', isEqualTo: widget.staffId)
        .get();

    setState(() {
      _assignedIncidents = snapshot.docs;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _proofImageFile = File(image.path);
      });
    }
  }

  Future<String> uploadProofImage(String incidentId, File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('incident_proofs')
        .child('$incidentId.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _handleIncident(DocumentSnapshot incident) async {
    if (_proofImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh xử lý")),
      );
      return;
    }

    try {
      final imageUrl = await uploadProofImage(incident.id, _proofImageFile!);
      final incidentRef = FirebaseFirestore.instance.collection('incidents').doc(incident.id);
      final staffRef = FirebaseFirestore.instance.collection('staffs').doc(widget.staffId);

      // Dữ liệu đầy đủ cho handledHistory
      final fullData = {
        'staffId': widget.staffId,
        'staffName': incident['assignedStaffName'],
        'accepted': true,
        'responseTime': FieldValue.serverTimestamp(),
        'note': 'Đã xử lý và đính kèm ảnh minh chứng.',
        'proofImageUrl': imageUrl,
        'rejectionReason': null,
        'incidentId': incident.id,
        'title': incident['title'],
      };

      // Dữ liệu rút gọn cho problemHistory
      final problemData = Map<String, dynamic>.from(fullData)
        ..remove('staffId')
        ..remove('staffName');

      await incidentRef.update({
        'status': 'Đã xử lý',
        'handledAt': FieldValue.serverTimestamp(),
      });

      await incidentRef.collection('handledHistory').add(fullData);
      await staffRef.collection('problemHistory').add(problemData);
      await staffRef.update({'isFree': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xác nhận xử lý")),
      );

      setState(() {
        _proofImageFile = null;
      });

      _loadAssignedIncidents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xử lý: $e")),
      );
    }
  }

  Future<void> _rejectIncident(DocumentSnapshot incident) async {
    final reason = _rejectReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập lý do từ chối")),
      );
      return;
    }

    try {
      final incidentRef = FirebaseFirestore.instance.collection('incidents').doc(incident.id);
      final staffRef = FirebaseFirestore.instance.collection('staffs').doc(widget.staffId);

      final fullData = {
        'staffId': widget.staffId,
        'staffName': incident['assignedStaffName'],
        'accepted': false,
        'responseTime': FieldValue.serverTimestamp(),
        'note': 'Chưa xử lí được sự cố',
        'proofImageUrl': null,
        'rejectionReason': reason,
        'incidentId': incident.id,
        'title': incident['title'],
      };

      final problemData = Map<String, dynamic>.from(fullData)
        ..remove('staffId')
        ..remove('staffName');

      await incidentRef.update({
        'status': 'Đang chờ xử lý',
        'assignedStaffId': null,
        'assignedStaffName': null,
      });

      await incidentRef.collection('handledHistory').add(fullData);
      await staffRef.collection('problemHistory').add(problemData);
      await staffRef.update({'isFree': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã từ chối xử lý")),
      );

      _rejectReasonController.clear();
      _loadAssignedIncidents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi từ chối xử lý: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sự cố được giao")),
      body: ListView.builder(
        itemCount: _assignedIncidents.length,
        itemBuilder: (context, index) {
          final incident = _assignedIncidents[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tiêu đề: ${incident['title']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Mô tả: ${incident['description']}"),
                  if (incident['imageUrl'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Image.network(incident['imageUrl'], height: 120),
                    ),
                  if (incident['managerNote'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Ghi chú từ quản lý: ${incident['managerNote']}"),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _showHandleDialog(incident),
                        child: const Text("Xác nhận xử lý"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _showRejectDialog(incident),
                        child: const Text("Từ chối xử lý"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Future<void> _showHandleDialog(DocumentSnapshot incident) async {
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Xác nhận đã xử lý"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImage = File(image.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text("Chọn ảnh minh chứng"),
                ),
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(selectedImage!, height: 120),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng chọn ảnh xử lý")),
                    );
                    return;
                  }

                  setState(() {
                    _proofImageFile = selectedImage;
                  });

                  Navigator.pop(context);
                  await _handleIncident(incident);
                },
                child: const Text("Xác nhận"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRejectDialog(DocumentSnapshot incident) async {
    final TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Từ chối xử lý"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: "Nhập lý do từ chối...",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập lý do từ chối")),
                );
                return;
              }

              _rejectReasonController.text = reason;
              Navigator.pop(context);
              await _rejectIncident(incident);
            },
            child: const Text("Từ chối"),
          ),
        ],
      ),
    );
  }

}
