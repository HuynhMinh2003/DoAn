import 'package:do_an/src/models/company_info.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

Future<void> exportCompaniesToExcel(List<CompanyInfo> staffs) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachCongTy'];

  final headers = [
    ex.TextCellValue('Tên công ty'),
    ex.TextCellValue('Số điện thoại'),
    ex.TextCellValue('Địa chỉ'),
    ex.TextCellValue('Email'),
    ex.TextCellValue('Loại dịch vụ'),
    ex.TextCellValue('Mô tả'),
  ];
  sheet.insertRowIterables(headers, 0);

  for (int i = 0; i < staffs.length; i++) {
    final apt = staffs[i];
    final row = [
      ex.TextCellValue(apt.name),
      ex.TextCellValue(apt.phone),
      ex.TextCellValue(apt.address),
      ex.TextCellValue(apt.email),
      ex.TextCellValue(apt.type),
      ex.TextCellValue(apt.description),
    ];
    sheet.insertRowIterables(row, i + 1);
  }

  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachCongTy.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}
