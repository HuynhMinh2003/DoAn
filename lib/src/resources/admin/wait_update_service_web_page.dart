import 'dart:html' as html;
import 'package:excel/excel.dart' as ex;

Future<void> exportServicesToExcel(List<Map<String, dynamic>> services) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachDichVu'];

  final headers = [
    ex.TextCellValue('Tên công ty'),
    ex.TextCellValue('Loại dịch vụ'),
    ex.TextCellValue('Mô tả'),
    ex.TextCellValue('Giá (VNĐ)'),
    ex.TextCellValue('Trạng thái'),
  ];
  sheet.insertRowIterables(headers, 0);

  for (int i = 0; i < services.length; i++) {
    final s = services[i];
    final row = [
      ex.TextCellValue(s['companyName'] ?? ''),
      ex.TextCellValue(s['companyType'] ?? ''),
      ex.TextCellValue(s['companyDescription'] ?? ''),
      ex.TextCellValue(s['price']?.toString() ?? ''),
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
