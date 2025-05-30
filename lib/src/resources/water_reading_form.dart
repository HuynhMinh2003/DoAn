import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class WaterReadingForm extends StatefulWidget {
  final String contractId;
  final String apartmentName;
  final String building;
  final String staffId;
  final String staffName;
  final String selectedMonth; // Example: "2025-05"

  const WaterReadingForm({
    required this.contractId,
    required this.apartmentName,
    required this.building,
    required this.staffId,
    required this.staffName,
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

  late TextEditingController oldController;
  late TextEditingController newController;

  late StreamController<String?> _oldReadingErrorController;
  late StreamController<String?> _newReadingErrorController;

  @override
  void initState() {
    super.initState();
    oldController = TextEditingController();
    newController = TextEditingController();
    _oldReadingErrorController = StreamController<String?>.broadcast();
    _newReadingErrorController = StreamController<String?>.broadcast();
    _loadExistingData();
  }

  @override
  void dispose() {
    oldController.dispose();
    newController.dispose();
    _oldReadingErrorController.close();
    _newReadingErrorController.close();
    super.dispose();
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
        oldController.text = oldReading?.toString() ?? '';
        newController.text = newReading?.toString() ?? '';
      });
    }
  }

  bool get canEdit {
    final selectedDate = DateTime.parse('${widget.selectedMonth}-01');
    final now = DateTime.now();

    // Chỉ cho ghi nếu:
    // - Tháng chọn là tháng hiện tại hoặc trước
    // - Chưa thanh toán
    // - Ngày hiện tại >= 25
    final isCurrentOrPastMonth = selectedDate.isBefore(DateTime(now.year, now.month + 1));
    final isAfter25 = now.day >= 25;

    return isCurrentOrPastMonth && !isPaid && isAfter25;
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

  Future<void> _saveReading() async {
    final oldText = oldController.text.trim();
    final newText = newController.text.trim();

    bool hasError = false;
    const int maxReading = 9999; // Giả sử đồng hồ max 9999

    // Kiểm tra chỉ số cũ
    final oldParsed = int.tryParse(oldText);
    if (oldText.isEmpty) {
      _oldReadingErrorController.add('Vui lòng nhập chỉ số cũ');
      hasError = true;
    } else if (oldParsed == null) {
      _oldReadingErrorController.add('Chỉ số cũ không hợp lệ');
      hasError = true;
    } else if (oldParsed < 0 || oldParsed > maxReading) {
      _oldReadingErrorController.add('Chỉ số cũ phải từ 0 đến $maxReading');
      hasError = true;
    } else {
      _oldReadingErrorController.add(null);
    }

    // Kiểm tra chỉ số mới
    final newParsed = int.tryParse(newText);
    if (newText.isEmpty) {
      _newReadingErrorController.add('Vui lòng nhập chỉ số mới');
      hasError = true;
    } else if (newParsed == null) {
      _newReadingErrorController.add('Chỉ số mới không hợp lệ');
      hasError = true;
    } else if (newParsed < 0 || newParsed > maxReading) {
      _newReadingErrorController.add('Chỉ số mới phải từ 0 đến $maxReading');
      hasError = true;
    } else {
      _newReadingErrorController.add(null);
    }

    if (hasError) return;

    final int oldReading = oldParsed!;
    final int newReading = newParsed!;

    // Nếu đồng hồ xoay vòng (newReading < oldReading), hỏi xác nhận
    if (newReading < oldReading) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đồng hồ quay vòng'),
          content: const Text(
              'Chỉ số mới nhỏ hơn chỉ số cũ, đồng nghĩa đồng hồ có thể đã quay vòng.\nBạn có chắc chắn muốn lưu?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        // Người dùng hủy thì không lưu, thoát hàm
        return;
      }
    }

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
      'staffId': widget.staffId,
      'staffName': widget.staffName,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('contracts')
        .doc(widget.contractId)
        .collection('waterReadings')
        .doc(widget.selectedMonth)
        .set(data, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('staffs')
        .doc(widget.staffId)
        .collection('waterReadings')
        .doc('${widget.contractId}_${widget.selectedMonth}')
        .set({
      'contractId': widget.contractId,
      'apartmentName': widget.apartmentName,
      'building': widget.building,
      'month': widget.selectedMonth,
      'oldReading': oldReading,
      'newReading': newReading,
      'timestamp': FieldValue.serverTimestamp(),
      'staffId': widget.staffId,
      'staffName': widget.staffName,
    }, SetOptions(merge: true));

    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lưu thành công'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Ẩn bàn phím khi tap ra ngoài
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(  // <-- Thêm SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "${widget.building} / Căn ${widget.apartmentName}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25.sp,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              StreamBuilder<String?>(
                stream: _oldReadingErrorController.stream,
                builder: (context, snapshot) {
                  return TextField(
                    controller: oldController,
                    decoration: InputDecoration(
                      labelText: "Chỉ số cũ",
                      labelStyle: TextStyle(fontSize: 15.sp),
                      errorText: snapshot.data,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: canEdit,
                  );
                },
              ),
              SizedBox(height: 10.h),
              _buildImagePicker(
                label: "Ảnh chỉ số cũ",
                imageFile: oldImageFile,
                imageUrl: oldImageUrl,
                onPick: canEdit ? () => _pickImage(true) : null,
              ),
              SizedBox(height: 10.h),
              StreamBuilder<String?>(
                stream: _newReadingErrorController.stream,
                builder: (context, snapshot) {
                  return TextField(
                    controller: newController,
                    decoration: InputDecoration(
                      labelText: "Chỉ số mới",
                      labelStyle: TextStyle(fontSize: 15.sp),
                      errorText: snapshot.data,
                    ),
                    keyboardType: TextInputType.number,
                    enabled: canEdit,
                  );
                },
              ),
              SizedBox(height: 10.h),
              _buildImagePicker(
                label: "Ảnh chỉ số mới",
                imageFile: newImageFile,
                imageUrl: newImageUrl,
                onPick: canEdit ? () => _pickImage(false) : null,
              ),
              SizedBox(height: 10.h),
              SwitchListTile(
                title: Text("Đã thanh toán", style: TextStyle(fontSize: 15.sp)),
                value: isPaid,
                onChanged: canEdit ? (val) => setState(() => isPaid = val) : null,
              ),
              if (canEdit)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saveReading,
                    label: Text("Lưu", style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              // Thêm SizedBox này giúp đẩy nội dung lên khi bàn phím hiện
            ],
          ),
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
