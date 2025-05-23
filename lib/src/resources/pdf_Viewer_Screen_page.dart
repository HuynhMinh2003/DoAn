import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hợp đồng dịch vụ',style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp),),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
