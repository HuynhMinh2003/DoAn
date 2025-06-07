import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

final Map<String, String> _vehicleTypeMap = {
  'motorbike_roofed': 'Xe máy có mái',
  'motorbike_unroofed': 'Xe máy không mái',
  'bike_roofed': 'Xe đạp có mái',
  'bike_unroofed': 'Xe đạp không mái',
  'car_roofed': 'Ô tô có mái',
  'car_unroofed': 'Ô tô không mái',
};

String _formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return '';

  try {
    DateTime dt;

    if (timestamp is DateTime) {
      dt = timestamp;
    } else if (timestamp is Map<String, dynamic>) {
      // Trường hợp Timestamp được convert sang Map trong Web
      if (timestamp.containsKey('_seconds')) {
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
      } else {
        return '';
      }
    } else if (timestamp.toString().startsWith('Timestamp(')) {
      // Trường hợp Timestamp được stringify từ Firestore
      final match = RegExp(r'seconds=(\d+)').firstMatch(timestamp.toString());
      if (match != null) {
        final seconds = int.parse(match.group(1)!);
        dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } else {
        return '';
      }
    } else if (timestamp is String) {
      String s = timestamp.replaceAll(' at ', ' ');
      final utcRegex = RegExp(r'UTC([+-]?\d+)');
      s = s.replaceAllMapped(utcRegex, (match) {
        final hour = int.parse(match.group(1)!);
        final sign = hour >= 0 ? '+' : '-';
        final h = hour.abs().toString().padLeft(2, '0');
        return '$sign$h:00';
      });
      dt = DateTime.parse(s);
    } else {
      return '';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  } catch (e) {
    return '';
  }
}

Future<void> exportRegistrationsToExcel(List<Map<String, dynamic>> registrations) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachDangKyXe'];

  final headers = [
    ex.TextCellValue('Biển số xe'),
    ex.TextCellValue('Loại xe'),
    ex.TextCellValue('Thời gian đăng ký'),
    ex.TextCellValue('Trạng thái'),
  ];
  sheet.insertRowIterables(headers, 0);

  for (int i = 0; i < registrations.length; i++) {
    final reg = registrations[i];

    final licensePlate = reg['licensePlate'] ?? '';
    final vehicleTypeKey = reg['vehicleType'] ?? '';
    final vehicleTypeVN = _vehicleTypeMap[vehicleTypeKey] ?? vehicleTypeKey;

    final registeredAt = _formatTimestamp(reg['registeredAt']);
    final canceledAt = reg['canceledAt'];
    final status = (canceledAt != null && canceledAt.toString().isNotEmpty)
        ? 'Đã huỷ (${_formatTimestamp(canceledAt)})'
        : 'Chưa huỷ';

    final row = [
      ex.TextCellValue(licensePlate),
      ex.TextCellValue(vehicleTypeVN),
      ex.TextCellValue(registeredAt),
      ex.TextCellValue(status),
    ];

    sheet.insertRowIterables(row, i + 1);
  }

  final fileBytes = excel.encode();
  if (fileBytes == null) return;

  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachDangKyXe.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}
