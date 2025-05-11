import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/models/resident_info.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

Future<void> exportResidentsToExcel(
    List<ResidentInfo> residents,
    List<ResidentInfo> matchedResidents,
    List<Apartment> apartments,
    ) async {
  // Use the filtered list if any filters are applied, otherwise use the full list
  final exportList = matchedResidents.isNotEmpty ? matchedResidents : residents;

  // Create a new Excel file
  final excel = ex.Excel.createExcel();
  final sheet = excel['DanhSachCuDan'];

  // Add the header row
  final headers = [
    ex.TextCellValue('Tên cư dân'),
    ex.TextCellValue('CCCD'),
    ex.TextCellValue('Ngày sinh'),
    ex.TextCellValue('Giới tính'),
    ex.TextCellValue('Email'),
    ex.TextCellValue('Số điện thoại'),
    ex.TextCellValue('Địa chỉ'),
    ex.TextCellValue('Tên phòng'),
  ];
  sheet.insertRowIterables(headers, 0);

  // Add the data rows
  for (int i = 0; i < exportList.length; i++) {
    final resident = exportList[i];

    // Find the resident's apartment
    final apartment = apartments.firstWhere(
          (a) => a.id == resident.apartmentId,
      orElse: () => Apartment(
        id: '',
        apartmentName: 'N/A',
        building: '',
        area: 0,
        rentPrice: 0,
        salePrice: 0,
        description: '',
        isRent: false,
        isSale: false,
        residents: [],
      ),
    );

    final row = [
      ex.TextCellValue(resident.fullName),
      ex.TextCellValue(resident.cccd),
      ex.TextCellValue(resident.birthDate != null
          ? resident.birthDate!.toString()
          : "N/A"), // Handle null birth date
      ex.TextCellValue(resident.gender),
      ex.TextCellValue(resident.email),
      ex.TextCellValue(resident.phone),
      ex.TextCellValue(resident.address),
      ex.TextCellValue(apartment.apartmentName), // Include apartment name
    ];
    sheet.insertRowIterables(row, i + 1);
  }

  // Encode the file and create a downloadable link
  final fileBytes = excel.encode();
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "DanhSachCuDan.xlsx")
    ..click();

  // Revoke the object URL to free up memory
  html.Url.revokeObjectUrl(url);
}