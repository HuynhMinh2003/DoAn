import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis_auth/googleapis_auth.dart';

class FirebaseAuthService {
  static Future<String> getOAuthToken() async {
    try {
      // Đọc file JSON từ assets
      final String serviceAccount =
      await rootBundle.loadString('assets/service_account.json');

      // Chuyển đổi JSON thành ServiceAccountCredentials
      final credentials = ServiceAccountCredentials.fromJson(
          json.decode(serviceAccount));

      // Yêu cầu lấy OAuth Token
      final client = await auth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'], // Phạm vi đúng cho FCM
      );

      // Lấy token từ client
      final accessToken = client.credentials.accessToken.data;

      print('✅ OAuth Token: $accessToken');

      return accessToken;
    } catch (e) {
      print('❌ Lỗi lấy OAuth Token: $e');
      return '';
    }
  }
}
