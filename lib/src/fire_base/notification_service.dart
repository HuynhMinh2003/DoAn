import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendNotification(String oauthToken, String fcmToken, String title, String body) async {
  final String fcmUrl = "https://fcm.googleapis.com/v1/projects/REDACTED_PROJECT_ID/messages:send";

  final Map<String, dynamic> data = {
    "message": {
      "token": fcmToken,  // Token of the device receiving the notification
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
      "Authorization": "Bearer $oauthToken",  // Using OAuth Token
    },
    body: jsonEncode(data),
  );
}
