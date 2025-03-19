import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendNotification(String oauthToken, String fcmToken, String title, String body) async {
  final String fcmUrl = "https://fcm.googleapis.com/v1/projects/REDACTED_PROJECT_ID/messages:send";

  final Map<String, dynamic> data = {
    "message": {
      "token": fcmToken,  // Token của thiết bị nhận thông báo
      "notification": {
        "title": title,
        "body": body
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "type": "billing"
      }
    }
  };

  final response = await http.post(
    Uri.parse(fcmUrl),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $oauthToken",  // Sử dụng OAuth Token
    },
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    print("✅ Gửi thông báo thành công!");
  } else {
    print("❌ Lỗi khi gửi thông báo: ${response.body}");
  }
}
