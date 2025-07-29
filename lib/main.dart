import 'dart:async';
import 'package:do_an/firebase_options.dart';
import 'package:do_an/src/fire_base/firebase_auth_service.dart';
import 'package:do_an/src/resources/provider/admin_image_provider.dart';
import 'package:do_an/src/resources/provider/company_image_provider.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:do_an/src/resources/provider/resident_image_provider.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:do_an/src/resources/provider/user__provider.dart';
import 'package:do_an/src/resources/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:do_an/src/app.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/provider/resident_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'constants.dart';
import 'controllers/menu_app_controller.dart';

// Cấu hình Firebase
const firebaseOptions = FirebaseOptions(
    apiKey: "REDACTED_FIREBASE_API_KEY_1",
    authDomain: "REDACTED_PROJECT_ID.firebaseapp.com",
    databaseURL: "https://REDACTED_PROJECT_ID-default-rtdb.firebaseio.com",
    projectId: "REDACTED_PROJECT_ID",
    storageBucket: "REDACTED_PROJECT_ID.firebasestorage.app",
    messagingSenderId: "REDACTED_MESSAGING_SENDER_ID",
    appId: "REDACTED_APP_ID",
    measurementId: "REDACTED_MEASUREMENT_ID"
);

// Tạo StreamController để quản lý luồng tin nhắn
final _messageStreamController = BehaviorSubject<RemoteMessage>();

// ✅ Plugin local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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

  // Chỉ load .env trên mobile (Web sẽ lỗi vì không có assets/.env)
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

  // Đặt màu thanh trạng thái
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Khóa ứng dụng ở chế độ dọc
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Đăng ký xử lý tin nhắn trong nền (chỉ mobile)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Yêu cầu quyền nhận thông báo
  await _requestNotificationPermissions();

  // Đăng ký và lấy mã thông báo FCM
  await _registerWithFCM();

  await _handleInitialMessage();

  // Đăng ký xử lý tin nhắn foreground
  _setupForegroundMessageHandler();

  String oauthToken = await FirebaseAuthService.getOAuthToken();
  print("OAuth Token: $oauthToken");

  // Khởi chạy ứng dụng
  runApp(
    ScreenUtilInit(
      designSize: const Size(384, 856.1777777777778),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          double screenWidth = MediaQuery.of(context).size.width;
          double screenHeight = MediaQuery.of(context).size.height;
          print("📱 Kích thước màn hình: width = $screenWidth, height = $screenHeight");
        });

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ResidentProvider()),
            ChangeNotifierProvider(create: (_) => UserDataProvider()),
            ChangeNotifierProvider(create: (_) => CompanyImageProvider()),
            ChangeNotifierProvider(create: (_) => StaffImageProvider()),
            ChangeNotifierProvider(create: (_) => ResidentImageProvider()),
            ChangeNotifierProvider(create: (_) => AdminImageProvider()),
            ChangeNotifierProvider(create: (_) => ContractNotifier()),
            ChangeNotifierProvider(create: (_) => MenuAppController()),
          ],
          child: MyApp(
            AuthBloc(),
            MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: kIsWeb
                  ? ThemeData.dark().copyWith(
                scaffoldBackgroundColor: bgColor,
                textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white),
                canvasColor: secondaryColor,
              )
                  : ThemeData(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: ResponsiveBreakpoints.builder(
                  child: child!,
                  breakpoints: [
                    const Breakpoint(start: 0, end: 899, name: MOBILE),
                    const Breakpoint(start: 900, end: 1279, name: TABLET),
                    const Breakpoint(start: 1280, end: 1919, name: DESKTOP),
                    const Breakpoint(start: 1920, end: double.infinity, name: '4K'),
                  ],
                ),
              ),
              home: SplashScreen(),
            ),
          ),
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

  // // Lưu token vào Firestore
  // if (token != null) {
  //   await _saveTokenToFirestore(token);
  // }

  // Gửi mã thông báo lên server (ví dụ minh họa)
  if (token != null) {
    print("Sending token to server...");
    // TODO: Thay thế bằng API gọi server của bạn
  }
}

Future<void> _handleInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('Notification caused app to open: ${initialMessage.notification?.title}');
  }
}

void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? "Thông báo";
    final body = message.notification?.body ?? "";

    flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'Thông báo hệ thống',
          channelDescription: 'Thông báo hiển thị khi app đang mở',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  });
}

// Đóng StreamController khi ứng dụng thoát
void disposeControllers() {
  _messageStreamController.close();
}

// GlobalKey để dùng ScaffoldMessenger trong ứng dụng
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
