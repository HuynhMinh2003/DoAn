import 'dart:html' as html;
import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';
import '../../models/incident.dart';

Future<void> exportIncidentsToExcel(List<Incident> incidents) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachSuCo'];

  final headers = [
    ex.TextCellValue('Căn hộ'),
    ex.TextCellValue('Tòa nhà'),
    ex.TextCellValue('Người báo'),
    ex.TextCellValue('Tiêu đề'),
    ex.TextCellValue('Mô tả'),
    ex.TextCellValue('Nhân viên xử lý'),
    ex.TextCellValue('Gửi vào'),
    ex.TextCellValue('Đã xử lý vào'),
    ex.TextCellValue('Ghi chú quản lý'),
    ex.TextCellValue('Trạng thái'),
  ];
  sheet.insertRowIterables(headers, 0);

  final formatter = DateFormat('dd/MM/yyyy HH:mm');

  for (int i = 0; i < incidents.length; i++) {
    final incident = incidents[i];

    final row = [
      ex.TextCellValue(incident.apartmentAddress),
      ex.TextCellValue(incident.building),
      ex.TextCellValue(incident.reporterName),
      ex.TextCellValue(incident.title),
      ex.TextCellValue(incident.description),
      ex.TextCellValue(incident.assignedStaffName ?? "Chưa cập nhật"),
      ex.TextCellValue(
          incident.createdAt != null ? formatter.format(incident.createdAt!.toDate()) : "Chưa cập nhật"
      ),
      ex.TextCellValue(
          incident.handledAt != null ? formatter.format(incident.handledAt!.toDate()) : "Chưa cập nhật"
      ),
      ex.TextCellValue(incident.managerNote ?? "Không có"),
      ex.TextCellValue(incident.status),
    ];

    sheet.insertRowIterables(row, i + 1);
  }

  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachSuCo.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}
