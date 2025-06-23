import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';
import 'dialog/loading_dialog.dart';

class StaffIncidentPage extends StatefulWidget {
  final String staffId;
  const StaffIncidentPage({super.key, required this.staffId});

  @override
  State<StaffIncidentPage> createState() => _StaffIncidentPageState();
}

class _StaffIncidentPageState extends State<StaffIncidentPage> {
  List<Incident> _assignedIncidents = [];
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
        .where('status', isEqualTo: 'Đang xử lý')
        .where('assignedStaffId', isEqualTo: widget.staffId)
        .get();

    final incidents = snapshot.docs
        .map((doc) => Incident.fromFirestore(doc))
        .toList();

    setState(() {
      _assignedIncidents = incidents;
    });
  }

  Future<String> uploadProofImage(String incidentId, File imageFile) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('incident_proofs')
        .child('$incidentId.jpg');

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _handleIncident(Incident incident) async {
    if (_proofImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh xử lý")),
      );
      return;
    }

    LoadingDialog.showLoadingDialog(context, "Đang gửi ... ");

    try {
      final imageUrl = await uploadProofImage(incident.id, _proofImageFile!);
      final incidentRef = FirebaseFirestore.instance.collection('incidents').doc(incident.id);
      final staffRef = FirebaseFirestore.instance.collection('staffs').doc(widget.staffId);

      // Dữ liệu đầy đủ cho handledHistory
      final fullData = {
        'staffId': widget.staffId,
        'staffName': incident.assignedStaffName,
        'accepted': true,
        'responseTime': FieldValue.serverTimestamp(),
        'note': 'Đã xử lý và đính kèm ảnh minh chứng.',
        'proofImageUrl': imageUrl,
        'rejectionReason': null,
        'incidentId': incident.id,
        'title': incident.title,
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

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xác nhận xử lý"),backgroundColor: Colors.green,),
      );

      setState(() {
        _proofImageFile = null;
      });

      _loadAssignedIncidents();
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xử lý: $e")),
      );
    }
  }

  Future<void> _rejectIncident(Incident incident) async {
    final reason = _rejectReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập lý do từ chối")),
      );
      return;
    }

    LoadingDialog.showLoadingDialog(context, "Đang gửi ... ");

    try {
      String? imageUrl;
      if (_proofImageFile != null) {
        imageUrl = await uploadProofImage(incident.id, _proofImageFile!);
      }

      final incidentRef = FirebaseFirestore.instance.collection('incidents').doc(incident.id);
      final staffRef = FirebaseFirestore.instance.collection('staffs').doc(widget.staffId);

      final fullData = {
        'staffId': widget.staffId,
        'staffName': incident.assignedStaffName,
        'accepted': false,
        'responseTime': FieldValue.serverTimestamp(),
        'note': 'Chưa xử lý được sự cố',
        'proofImageUrl': imageUrl,
        'rejectionReason': reason,
        'incidentId': incident.id,
        'title': incident.title,
      };

      final problemData = Map<String, dynamic>.from(fullData)
        ..remove('staffId')
        ..remove('staffName');

      await incidentRef.update({
        'status': 'Đang chờ xử lý (Trả lại)',
        'assignedStaffId': null,
        'assignedStaffName': null,
      });

      await incidentRef.collection('handledHistory').add(fullData);
      await staffRef.collection('problemHistory').add(problemData);
      await staffRef.update({'isFree': true});

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã từ chối xử lý"), backgroundColor: Colors.red,),
      );

      _rejectReasonController.clear();
      setState(() {
        _proofImageFile = null;
      });
      _loadAssignedIncidents();
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi từ chối xử lý: $e")),
      );
    }
  }

  Future<void> _showRejectDialog(Incident incident) async {
    final TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Center(child: Text("Từ chối xử lý",style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold,fontSize: 25.sp)),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: "Nhập lý do từ chối...",
                    hintStyle: TextStyle(fontSize: 15.sp),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() {
                        _proofImageFile = File(picked.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text("Chọn ảnh minh chứng",style: TextStyle(fontSize: 15.sp,color: Colors.black),),
                ),
                if (_proofImageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Image.file(
                      _proofImageFile!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _proofImageFile = null;
              },
              child: Text("Hủy",style: TextStyle(fontSize: 15.sp,color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Vui lòng nhập lý do từ chối",style: TextStyle(fontSize: 15.sp))),
                  );
                  return;
                }

                _rejectReasonController.text = reason;
                Navigator.pop(context);
                await _rejectIncident(incident);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text("Từ chối",style: TextStyle(fontSize: 15.sp,color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHandleDialog(Incident incident) async {
    File? selectedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Center(child: Text("Xác nhận đã xử lý",style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold,fontSize: 25.sp),),),
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
                  label: Text("Chọn ảnh minh chứng",style: TextStyle(fontSize: 15.sp,color: Colors.black)),
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
                child: Text("Hủy",style: TextStyle(fontSize: 15.sp,color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Vui lòng chọn ảnh xử lý",style: TextStyle(fontSize: 15.sp)),backgroundColor: Colors.green,),
                    );
                    return;
                  }

                  setState(() {
                    _proofImageFile = selectedImage;
                  });

                  Navigator.pop(context);
                  await _handleIncident(incident);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text("Xác nhận",style: TextStyle(fontSize: 15.sp, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sự cố được giao",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: const Color(0xFF3C4DFF),
        foregroundColor: Colors.white,
      ),
      body: _assignedIncidents.isEmpty
          ? Center(
        child: Text(
          "Chưa có sự cố nào",
          style: TextStyle(
            fontSize: 16.sp,
          ),
        ),
      )
          : ListView.builder(
        itemCount: _assignedIncidents.length,
        itemBuilder: (context, index) {
          final incident = _assignedIncidents[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white, // nền trong card
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,      // màu bóng
                  blurRadius: 8,             // độ mờ – càng cao thì bóng càng rộng
                  spreadRadius: 1,            // độ lan – tạo cảm giác bóng bao quanh
                  offset: Offset(0, 0),       // offset 0 để bóng đều các phía
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: (incident.imageUrl != null && incident.imageUrl!.isNotEmpty)
                                ? Image.network(
                              incident.imageUrl!,
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              'assets/default_avatar.png',
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("Tiêu đề", incident.title),
                            _infoRow("Mô tả", incident.description),
                            if (incident.managerNote != null && incident.managerNote!.isNotEmpty)
                              _infoRow("Ghi chú từ quản lý", incident.managerNote!),
                            _infoRow("Ngày báo", DateFormat('dd/MM/yyyy HH:mm').format(incident.createdAt!.toDate())),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _showHandleDialog(incident),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Center(
                          child: Text(
                            "Xác nhận xử lý",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _showRejectDialog(incident),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Center(
                          child: Text(
                            "Từ chối xử lý",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 13.sp)),
          Expanded(child: Text(value ?? "Không có", style: TextStyle(fontSize: 13.sp),)),
        ],
      ),
    );
  }

}
