import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/firebase_options.dart';
import 'package:do_an/src/fire_base/firebase_auth_service.dart';
import 'package:do_an/src/fire_base/notification_service.dart';
import 'package:do_an/src/resources/home_page.dart';
import 'package:do_an/src/resources/provider/user__provider.dart';
import 'package:do_an/src/resources/provider/user_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:do_an/src/app.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/provider/resident_provider.dart';
import 'package:do_an/src/resources/provider/userinfo_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Cấu hình Firebase
const firebaseOptions = FirebaseOptions(
  apiKey: "REDACTED_FIREBASE_API_KEY_1",
  authDomain: "REDACTED_PROJECT_ID.firebaseapp.com",
  databaseURL: "https://REDACTED_PROJECT_ID-default-rtdb.firebaseio.com",
  projectId: "REDACTED_PROJECT_ID",
  storageBucket: "REDACTED_PROJECT_ID.firebasestorage.app",
  messagingSenderId: "REDACTED_MESSAGING_SENDER_ID",
  appId: "REDACTED_APP_ID",
  measurementId: "REDACTED_MEASUREMENT_ID",
);

// Tạo StreamController để quản lý luồng tin nhắn
final _messageStreamController = BehaviorSubject<RemoteMessage>();

// Trình xử lý tin nhắn nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
  print('Message notification: ${message.notification?.body}');
}

// Hàm chính
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // Khởi tạo SQLite cho các nền tảng non-mobile như desktop
  // if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
  //     defaultTargetPlatform == TargetPlatform.macOS ||
  //     defaultTargetPlatform == TargetPlatform.linux)) {
  //   sqfliteFfiInit();  // Khởi tạo FFI cho nền tảng không phải di động
  // }
// Khóa ứng dụng chỉ chạy ở chế độ dọc
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Khởi tạo Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  // Khởi tạo SQLite
  // initDatabase();

  // Đăng ký xử lý tin nhắn trong nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Yêu cầu quyền nhận thông báo
  await _requestNotificationPermissions();

  // Đăng ký và lấy mã thông báo FCM
  await _registerWithFCM();

  await _handleInitialMessage();

  // Đăng ký xử lý tin nhắn foreground
  _setupForegroundMessageHandler();

  String oauthToken = await FirebaseAuthService.getOAuthToken();
  print("OAuth Token: $oauthToken");
  sendNotification(
      oauthToken,
      "cAaBnkGPQIikyBN6rOm-i-:APA91bFZUkSL6ooRj4q6m1BeN6IeRe_wQRrOaeA-MpBvI6bEaLE8psWQcB83pDvALMmcC9nejQz8wA7rQwuK-VaeL0GR9OQCg7OXzW3vf9W4MQkL40_Tg2g", // FCM Token của thiết bị nhận
      "Thông báo tiền nước!",
      "Hóa đơn tháng này là 500,000 VND."
  );
  // Khởi chạy ứng dụng
  runApp(
    ScreenUtilInit(
      // designSize: const Size(384, 856.1777777777778),
      designSize: const Size(384, 784.0),
      minTextAdapt: true,
      splitScreenMode: true, // Hỗ trợ màn hình chia đôi
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          double screenWidth = MediaQuery.of(context).size.width;
          double screenHeight = MediaQuery.of(context).size.height;
          print("📱 Kích thước màn hình: width = $screenWidth, height = $screenHeight");
        });
        return FutureBuilder<Map<String, dynamic>?>(
          future: checkLoginState(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            } else {
              var userData = snapshot.data;
              bool isLoggedIn = userData != null;

              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => ResidentProvider()),
                  ChangeNotifierProvider(create: (_) => UserDataProvider()),
                  ChangeNotifierProvider(create: (_) => UserImageProvider()),
                ],
                child: MyApp(
                  AuthBloc(),
                  MaterialApp(
                    navigatorKey: navigatorKey,
                    home: isLoggedIn ? HomePage(userData: userData) : LoginPage(),
                    debugShowCheckedModeBanner: false,
                  ),
                ),
              );
            }
          },
        );
      },
    ),
  );
}

// Hàm yêu cầu quyền nhận thông báo
Future<void> _requestNotificationPermissions() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
  }
}

// Hàm lưu token FCM vào Firestore
Future<void> _saveTokenToFirestore(String token) async {
  final userId = FirebaseAuth.instance.currentUser?.uid; // Lấy userId hiện tại
  if (userId != null) {
    try {
      // Lưu token vào Firestore, nếu tài liệu không tồn tại sẽ tạo mới
      await FirebaseFirestore.instance
          .collection('users') // Chọn collection 'users'
          .doc(userId)
          .set({
        'fcmToken': token,  // Cập nhật hoặc tạo mới token vào trường 'fcmToken'
        'lastUpdated': FieldValue.serverTimestamp() // Lưu thời gian cập nhật
      }, SetOptions(merge: true)); // merge: true để không ghi đè toàn bộ tài liệu
      print("Token saved to Firestore successfully");
    } catch (e) {
      print("Error saving token to Firestore: $e");
    }
  }
}

// Hàm đăng ký FCM và lấy mã thông báo
Future<void> _registerWithFCM() async {
  const vapidKey = "REDACTED_VAPID_KEY";
  final messaging = FirebaseMessaging.instance;

  String? token;

  // Lấy mã thông báo cho web với VAPID Key
  if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
    token = await messaging.getToken(vapidKey: vapidKey);
  } else {
    token = await messaging.getToken();
  }

  if (kDebugMode) {
    print('Registration Token=$token');
  }

  // Lưu token vào Firestore
  if (token != null) {
    await _saveTokenToFirestore(token);
  }

  // Gửi mã thông báo lên server (ví dụ minh họa)
  if (token != null) {
    print("Sending token to server...");
    // TODO: Thay thế bằng API gọi server của bạn
  }
}

Future<Map<String, dynamic>?> checkLoginState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isLoggedIn && FirebaseAuth.instance.currentUser != null) {
    return {
      'uid': prefs.getString('uid'),
      'name': prefs.getString('name'),
      'email': prefs.getString('email'),
    };
  }
  return null;
}

Future<void> _handleInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('Notification caused app to open: ${initialMessage.notification?.title}');
  }
}

// Hàm xử lý tin nhắn foreground
void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('Foreground message received: ${message.notification!.title}, ${message.notification!.body}');

      if (navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            title: Text(message.notification!.title ?? "No Title"),
            content: Text(message.notification!.body ?? "No Body"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
            ],
          ),
        );
      }
    }
  });
}

// Đóng StreamController khi ứng dụng thoát
void disposeControllers() {
  _messageStreamController.close();
}

// GlobalKey để dùng ScaffoldMessenger trong ứng dụng
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
