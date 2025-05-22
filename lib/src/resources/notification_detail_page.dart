import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(notification["title"])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification["imageUrl"] != null)
              Center(
                child: Image.network(
                  notification["imageUrl"],
                  width: 300, // Giới hạn chiều rộng
                  height: 200, // Giới hạn chiều cao
                  fit: BoxFit.contain, // Hiển thị đầy đủ ảnh mà không bị cắt
                ),
              ),
            const SizedBox(height: 16),
            Text(
              notification["message"],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
