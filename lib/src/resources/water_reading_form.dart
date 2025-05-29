import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WaterReadingForm extends StatefulWidget {
  final String contractId;
  final String apartmentName;
  final String building;
  final String selectedMonth; // Example: "2025-05"

  const WaterReadingForm({
    required this.contractId,
    required this.apartmentName,
    required this.building,
    required this.selectedMonth,
    super.key,
  });

  @override
  State<WaterReadingForm> createState() => _WaterReadingFormState();
}

class _WaterReadingFormState extends State<WaterReadingForm> {
  final _picker = ImagePicker();
  int? oldReading;
  int? newReading;
  File? oldImageFile;
  File? newImageFile;
  String? oldImageUrl;
  String? newImageUrl;
  bool isPaid = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('contracts')
        .doc(widget.contractId)
        .collection('waterReadings')
        .doc(widget.selectedMonth)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        oldReading = data['oldReading'];
        newReading = data['newReading'];
        isPaid = data['isPaid'] ?? false;
        oldImageUrl = data['oldImageUrl'];
        newImageUrl = data['newImageUrl'];
      });
    }
  }

  bool get canEdit {
    final selectedDate = DateTime.parse('${widget.selectedMonth}-01');
    final now = DateTime.now();
    return selectedDate.isBefore(DateTime(now.year, now.month)) && !isPaid;
  }

  Future<String?> _uploadImage(File image, String type) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('water_readings')
        .child(widget.contractId)
        .child(widget.selectedMonth)
        .child('$type.jpg');

    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> _saveReading() async {
    if (oldReading == null || newReading == null) return;
    setState(() => loading = true);

    if (oldImageFile != null) {
      oldImageUrl = await _uploadImage(oldImageFile!, 'old');
    }
    if (newImageFile != null) {
      newImageUrl = await _uploadImage(newImageFile!, 'new');
    }

    final data = {
      'oldReading': oldReading,
      'newReading': newReading,
      'isPaid': isPaid,
      'oldImageUrl': oldImageUrl,
      'newImageUrl': newImageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('contracts')
        .doc(widget.contractId)
        .collection('waterReadings')
        .doc(widget.selectedMonth)
        .set(data, SetOptions(merge: true));

    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lưu thành công')));
  }

  Future<void> _pickImage(bool isOld) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isOld) {
          oldImageFile = File(picked.path);
        } else {
          newImageFile = File(picked.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${widget.apartmentName} - ${widget.building}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: oldReading?.toString(),
              decoration: InputDecoration(labelText: "Chỉ số cũ"),
              keyboardType: TextInputType.number,
              enabled: canEdit,
              onChanged: (val) => oldReading = int.tryParse(val),
            ),
            const SizedBox(height: 8),
            _buildImagePicker(
                label: "Ảnh chỉ số cũ",
                imageFile: oldImageFile,
                imageUrl: oldImageUrl,
                onPick: canEdit ? () => _pickImage(true) : null),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: newReading?.toString(),
              decoration: InputDecoration(labelText: "Chỉ số mới"),
              keyboardType: TextInputType.number,
              enabled: canEdit,
              onChanged: (val) => newReading = int.tryParse(val),
            ),
            const SizedBox(height: 8),
            _buildImagePicker(
                label: "Ảnh chỉ số mới",
                imageFile: newImageFile,
                imageUrl: newImageUrl,
                onPick: canEdit ? () => _pickImage(false) : null),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text("Đã thanh toán"),
              value: isPaid,
              onChanged: canEdit ? (val) => setState(() => isPaid = val) : null,
            ),
            if (canEdit)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saveReading,
                  icon: Icon(Icons.save),
                  label: Text("Lưu"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required String? imageUrl,
    required VoidCallback? onPick,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        if (onPick != null)
          IconButton(
            icon: Icon(Icons.photo_library),
            onPressed: onPick,
          ),
        if (imageFile != null)
          Image.file(imageFile, width: 50, height: 50, fit: BoxFit.cover),
        if (imageFile == null && imageUrl != null)
          Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
      ],
    );
  }
}