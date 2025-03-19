import 'package:flutter/material.dart';

class WaitingForApprovalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chờ xét duyệt"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),  // Biểu tượng chờ
            const SizedBox(height: 20),
            const Text(
              "Tài khoản của bạn đang chờ xét duyệt, vui lòng đợi...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // Quay lại trang trước
              },
              child: const Text("Quay lại"),
            ),
          ],
        ),
      ),
    );
  }
}
