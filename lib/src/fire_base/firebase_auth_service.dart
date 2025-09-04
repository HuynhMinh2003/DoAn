import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis_auth/googleapis_auth.dart';

class FirebaseAuthService {
  static Future<String> getOAuthToken() async {
    try {
      // Read JSON file from assets
      final String serviceAccount =
      await rootBundle.loadString('assets/service_account.json');

      // Convert JSON to ServiceAccountCredentials
      final credentials = ServiceAccountCredentials.fromJson(
          json.decode(serviceAccount));

      // Request to get OAuth Token
      final client = await auth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'], // Correct scope for FCM
      );

      // Get token from client
      final accessToken = client.credentials.accessToken.data;

      return accessToken;
    } catch (e) {
      return '';
    }
  }
}
