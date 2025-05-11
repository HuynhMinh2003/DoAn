import 'package:do_an/src/models/staffs.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

Future<void> exportStaffsToExcel(List<Staff> staffs) async {
  final excel = ex.Excel.createExcel(); // tạo file mới
  final sheet = excel['DanhSachNhanVien']; // tạo sheet

  // Dòng tiêu đề (Header)
  final headers = [
    ex.TextCellValue('Tên nhân viên'),
    ex.TextCellValue('Số điện thoại'),
    ex.TextCellValue('Địa chỉ'),
    ex.TextCellValue('Giới tính'),
    ex.TextCellValue('Số CCCD'),
    ex.TextCellValue('Chức vụ'),
    ex.TextCellValue('Email'),
  ];
  sheet.insertRowIterables(headers, 0); // Ghi dòng đầu tiên

  // Ghi từng dòng dữ liệu
  for (int i = 0; i < staffs.length; i++) {
    final apt = staffs[i];
    final row = [
      ex.TextCellValue(apt.fullName),
      ex.TextCellValue(apt.phone),
      ex.TextCellValue(apt.address),
      ex.TextCellValue(apt.gender),
      ex.TextCellValue(apt.cccd),
      ex.TextCellValue(apt.position),
      ex.TextCellValue(apt.email),
    ];
    sheet.insertRowIterables(row, i + 1);
  }

  // Xuất file
  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachNhanVien.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}
