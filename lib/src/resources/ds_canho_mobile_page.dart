import 'package:do_an/src/models/apartment.dart';
import 'package:flutter/material.dart';

Future<void> importApartmentsFromExcel(BuildContext context) async {
  // Hiển thị thông báo rằng chức năng này không khả dụng trên mobile
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Chức năng này không hỗ trợ trên mobile.')),
  );
}

Future<void> exportApartmentsToExcel(List<Apartment> apartments) async {

    Text('Chức năng này không hỗ trợ trên mobile.');
}