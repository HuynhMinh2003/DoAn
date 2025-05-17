import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddServiceForm extends StatefulWidget {
  @override
  _AddServiceFormState createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<AddServiceForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dropdown options for serviceType
  String _serviceType = 'fixed_per_month';
  bool _isAvailable = true;

  // Required fields (dynamic based on serviceType)
  List<String> _requiredFields = [];
  final Map<String, List<String>> serviceTypeRequiredFields = {
    'fixed_per_month': ['apartmentID'],
    'per_unit': ['licensePlate'],
    'per_hour': ['address', 'time'],
    'per_usage': ['residentID'],
  };

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm Dịch Vụ Mới"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tên dịch vụ
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên dịch vụ'),
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập tên dịch vụ' : null,
              ),

              // Giá dịch vụ
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Giá dịch vụ'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập giá dịch vụ' : null,
              ),

              // Đơn vị
              if (_serviceType != 'custom_form')
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(labelText: 'Đơn vị'),
                  validator: (value) => value!.isEmpty
                      ? 'Vui lòng nhập đơn vị (ví dụ: tháng, lượt)'
                      : null,
                ),

              // Mô tả dịch vụ
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả dịch vụ'),
                maxLines: 3,
              ),

              // Loại dịch vụ
              DropdownButtonFormField<String>(
                value: _serviceType,
                items: [
                  DropdownMenuItem(
                    value: 'fixed_per_month',
                    child: Text('Cố định hàng tháng'),
                  ),
                  DropdownMenuItem(
                    value: 'per_unit',
                    child: Text('Theo số lượng'),
                  ),
                  DropdownMenuItem(
                    value: 'per_hour',
                    child: Text('Theo giờ'),
                  ),
                  DropdownMenuItem(
                    value: 'per_usage',
                    child: Text('Theo lượt sử dụng'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _serviceType = value!;
                    _requiredFields =
                        serviceTypeRequiredFields[_serviceType] ?? [];
                  });
                },
                decoration: InputDecoration(labelText: 'Loại dịch vụ'),
              ),

              // Trạng thái dịch vụ
              SwitchListTile(
                title: Text('Dịch vụ khả dụng'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),

              SizedBox(height: 20),

              // Nút lưu
              ElevatedButton(
                onPressed: _saveService,
                child: Text('Lưu dịch vụ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      final newService = {
        "id": _firestore.collection('services').doc().id,
        "name": _nameController.text,
        "type": "fixed", // Có thể thêm logic phân loại "fixed" hoặc "external" nếu cần
        "serviceType": _serviceType,
        "price": int.parse(_priceController.text),
        "unit": _unitController.text,
        "requiredFields": _requiredFields,
        "description": _descriptionController.text,
        "isAvailable": _isAvailable,
        "createdAt": FieldValue.serverTimestamp(),
      };

      try {
        await _firestore.collection('services').add(newService);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dịch vụ đã được thêm thành công!')),
        );
        Navigator.pop(context); // Quay lại màn hình trước
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    }
  }
}
