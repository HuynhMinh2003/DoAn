import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';

Future<void> exportServicesToExcel(List<Map<String, dynamic>> services) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachDichVu'];

  final headers = [
    ex.TextCellValue('Tên công ty'),
    ex.TextCellValue('Loại dịch vụ'),
    ex.TextCellValue('Mô tả'),
    ex.TextCellValue('Giá'),
    ex.TextCellValue('Thời gian cập nhật'),
    ex.TextCellValue('Trạng thái'),
  ];
  sheet.insertRowIterables(headers, 0);

  // Định dạng thời gian
  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  for (int i = 0; i < services.length; i++) {
    final s = services[i];
    final row = [
      ex.TextCellValue(s['companyName'] ?? ''),
      ex.TextCellValue(s['companyType'] ?? ''),
      ex.TextCellValue(s['companyDescription'] ?? ''),
      ex.TextCellValue(s['price']?.toString() ?? ''),
      ex.TextCellValue(
          s['timestamp'] != null
              ? dateFormatter.format((s['timestamp'] as Timestamp).toDate())
              : ''
      ),
      ex.TextCellValue(s['status'] ?? ''),
    ];
    sheet.insertRowIterables(row, i + 1);
  }

  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachDichVu.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}
