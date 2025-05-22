import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/resources/notification_detail_page.dart';
import 'package:flutter/material.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách thông báo"),
        backgroundColor: Theme.of(context).colorScheme.primary,),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("information")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có thông báo nào."));
          }

          var notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var data = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: data["imageUrl"] != null
                    ? Image.network(data["imageUrl"], width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.notifications, size: 50, color: Colors.grey),
                title: Text(data["title"], maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationDetailPage(notification: data),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}