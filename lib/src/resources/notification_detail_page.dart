import 'package:flutter/material.dart';
import 'package:do_an/src/models/information.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class NotificationDetailPage extends StatelessWidget {
  final Information notification;

  const NotificationDetailPage({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chi tiết thông báo",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Oswald",
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(formattedDate, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (notification.imageUrl != null)
              Center(
                child: Image.network(notification.imageUrl!, height: 200),
              ),
            const SizedBox(height: 16),
            Text(notification.message, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
