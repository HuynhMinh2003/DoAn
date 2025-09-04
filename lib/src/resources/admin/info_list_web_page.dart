import 'package:do_an/src/models/information.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;
import 'package:intl/intl.dart';

Future<void> exportInfoToExcel(List<Information> informations) async {
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachThongBao'];

  final headers = [
    ex.TextCellValue('Tiêu đề'),
    ex.TextCellValue('Nội dung'),
    ex.TextCellValue('Lần chỉnh sửa gần nhất'),
    ex.TextCellValue('Thời gian đăng'),
  ];
  sheet.insertRowIterables(headers, 0);

  final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  for (int i = 0; i < informations.length; i++) {
    final info = informations[i];
    final row = [
      ex.TextCellValue(info.title),
      ex.TextCellValue(info.message),
      ex.TextCellValue(info.lastEdited != null
          ? dateFormatter.format(info.lastEdited!)
          : '-'),
      ex.TextCellValue(dateFormatter.format(info.timestamp!)),
    ];
    sheet.insertRowIterables(row, i + 1);
  }

  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachThongBao.xlsx")
    ..click();
  html.Url.revokeObjectUrl(url);
}

