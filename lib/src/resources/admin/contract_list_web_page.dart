import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:html' as html;

Future<void> exportContractApartmentsToExcel(List<Apartment> apartments) async {
  try {
    final excel = ex.Excel.createExcel();
    final sheet = excel['DanhSachHopDongCanHo'];

    final Map<String, Map<String, dynamic>> contractDataMap = {};

    for (final apartment in apartments) {
      final doc = await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartment.id)
          .get();

      final contractId = doc.data()?['currentContractId'];
      if (contractId != null) {
        final contractDoc = await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .get();

        final contractData = contractDoc.data();
        if (contractData != null) {
          contractDataMap[apartment.id] = contractData;
        }
      }
    }

    final headers = [
      ex.TextCellValue('Tên căn hộ'),
      ex.TextCellValue('Diện tích'),
      ex.TextCellValue('Tòa nhà'),
      ex.TextCellValue('Mô tả'),
      ex.TextCellValue('Trạng thái'),
      ex.TextCellValue('Người đại diện'),
      ex.TextCellValue('Ngày bắt đầu'),
      ex.TextCellValue('Ngày kết thúc'),
      ex.TextCellValue('Ngày tạo hợp đồng'),
      ex.TextCellValue('Số cư dân'),
      ex.TextCellValue('Mục đích'),
    ];
    sheet.insertRowIterables(headers, 0);

    for (int i = 0; i < apartments.length; i++) {
      final apt = apartments[i];
      final contract = contractDataMap[apt.id];

      final representativeName = contract?['representative']?['fullName'] ?? 'Chưa có';
      final startDate = _formatTimestamp(contract?['startDate']);
      final endDate = _formatTimestamp(contract?['endDate']);
      final createdAt = _formatTimestamp(contract?['createdAt']);
      final numberOfResidents = contract?['numberOfResidents'] ?? 0;
      final purpose = contract?['purpose'] ?? 'Không rõ';

      final row = [
        ex.TextCellValue(apt.apartmentName),
        ex.DoubleCellValue(apt.area.toDouble()),
        ex.TextCellValue(apt.building),
        ex.TextCellValue(apt.description),
        ex.TextCellValue(apt.status),
        ex.TextCellValue(representativeName),
        ex.TextCellValue(startDate),
        ex.TextCellValue(endDate),
        ex.TextCellValue(createdAt),
        ex.IntCellValue(numberOfResidents),
        ex.TextCellValue(purpose),
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
  } catch (e) {
  }
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  return '---';
}
