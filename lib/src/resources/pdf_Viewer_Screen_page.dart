import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In ra URL để kiểm tra giá trị được truyền vào
    print('🚀 Đang mở PDF từ URL: $pdfUrl');

    print('🔗 Link PDF được truyền vào: $pdfUrl');

    // Kiểm tra URL rỗng
    if (pdfUrl.trim().isEmpty) {
      print('❌ Lỗi: URL PDF bị rỗng');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hợp đồng dịch vụ',
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontWeight: FontWeight.bold,
            fontSize: 25.sp,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: pdfUrl.trim().isEmpty
          ? Center(
        child: Text(
          'URL PDF không hợp lệ',
          style: TextStyle(fontSize: 16.sp, color: Colors.red),
        ),
      )
          : Builder(
        builder: (context) {
          try {
            return SfPdfViewer.network(
              pdfUrl,
              onDocumentLoadFailed: (details) {
                // In ra chi tiết lỗi nếu load thất bại
                print('❌ Lỗi khi load PDF: ${details.description}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể tải hợp đồng: ${details.description}')),
                );
              },
            );
          } catch (e, stackTrace) {
            print('❌ Exception khi khởi tạo PDF Viewer: $e');
            print('📄 StackTrace: $stackTrace');
            return Center(
              child: Text(
                'Đã xảy ra lỗi khi hiển thị PDF.',
                style: TextStyle(fontSize: 16.sp, color: Colors.red),
              ),
            );
          }
        },
      ),
    );
  }
}
