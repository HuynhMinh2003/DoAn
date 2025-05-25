import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
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
        .where('status', isEqualTo: 'Đã giao')
        .where('assignedStaffId', isEqualTo: widget.staffId)
        .get();

    setState(() {
      _assignedIncidents = snapshot.docs;
    });
  }

  Future<void> _handleIncident(DocumentSnapshot incident) async {
    if (_proofImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh xử lý")),
      );
      return;
    }

    final imageUrl = await uploadProofImage(incident.id, _proofImageFile!);

    await FirebaseFirestore.instance.collection('incidents').doc(incident.id).update({
      'status': 'Đã xử lý',
      'handledAt': FieldValue.serverTimestamp(),
      'proofImageUrl': imageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã xác nhận xử lý")),
    );

    _loadAssignedIncidents();
  }

  Future<void> _rejectIncident(DocumentSnapshot incident) async {
    final reason = _rejectReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập lý do từ chối")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('incidents').doc(incident.id).update({
      'status': 'Từ chối xử lý',
      'rejectedReason': reason,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã từ chối xử lý")),
    );

    _rejectReasonController.clear();
    _loadAssignedIncidents();
  }

  Future<String> uploadProofImage(String incidentId, File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('incident_proofs')
        .child('$incidentId.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
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
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text("Chọn ảnh đã xử lý"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _handleIncident(incident),
                        child: const Text("Xác nhận xử lý"),
                      ),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: _rejectReasonController,
                    decoration: const InputDecoration(
                      hintText: "Lý do từ chối xử lý...",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _rejectIncident(incident),
                    child: const Text("Từ chối xử lý"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
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
