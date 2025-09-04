import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

import 'package:flutter/material.dart';

Future<void> importApartmentsFromExcel(BuildContext context) async {
  final uploadInput = html.FileUploadInputElement()..accept = '.xlsx';
  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final file = uploadInput.files!.first;
    final reader = html.FileReader();

    reader.readAsArrayBuffer(file);

    reader.onLoadEnd.listen((e) async {
      final bytes = reader.result as List<int>;
      final excel = ex.Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) return;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final apartmentData = {
          'apartmentName': row[0]?.value.toString() ?? '',
          'area': double.tryParse(row[1]?.value.toString() ?? '0') ?? 0.0,
          'building': row[2]?.value.toString() ?? '',
          'description': row[3]?.value.toString() ?? '',
          'status': 'Trống',
          'currentContractId': null,
          'isUpdate': null,
          'residents': [],
        };

        await FirebaseFirestore.instance.collection('apartments').add(apartmentData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm căn hộ thành công!')),
      );
    });
  });
}

Future<void> exportApartmentsToExcel(List<Apartment> apartments) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachCanHo'];

  final headers = [
    ex.TextCellValue('Tên căn hộ'),
    ex.TextCellValue('Diện tích'),
    ex.TextCellValue('Tòa nhà'),
    ex.TextCellValue('Mô tả'),
    ex.TextCellValue('Trạng thái'),
  ];
  sheet.insertRowIterables(headers, 0);

  for (int i = 0; i < apartments.length; i++) {
    final apt = apartments[i];
    final row = [
      ex.TextCellValue(apt.apartmentName),
      ex.DoubleCellValue(apt.area as double),
      ex.TextCellValue(apt.building),
      ex.TextCellValue(apt.description),
      ex.TextCellValue(apt.status),

    ];
    sheet.insertRowIterables(row, i + 1);
  }

  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachCanHo.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}