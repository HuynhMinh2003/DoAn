import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/firebase_options.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/main_admin_page.dart';
import 'package:do_an/src/resources/provider/company_image_provider.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:do_an/src/resources/provider/user__provider.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// Cấu hình Firebase
const firebaseOptions = FirebaseOptions(
  apiKey: "***REMOVED***Cu8AtVjmtcku_HRp29c6zc164qUysESfs",
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

  //Đặt màu thanh trạng thái ở đây
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // hoặc đặt màu chính bạn muốn
      statusBarIconBrightness: Brightness.dark, // icon trắng cho nền tối
    ),
  );

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

  // // Đăng ký xử lý tin nhắn trong nền
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //
  // // Yêu cầu quyền nhận thông báo
  // await _requestNotificationPermissions();
  //
  // // Đăng ký và lấy mã thông báo FCM
  // await _registerWithFCM();
  //
  // await _handleInitialMessage();
  //
  // // Đăng ký xử lý tin nhắn foreground
  // _setupForegroundMessageHandler();
  //
  // String oauthToken = await FirebaseAuthService.getOAuthToken();
  // print("OAuth Token: $oauthToken");
  // sendNotification(
  //     oauthToken,
  //     "djX1z-KOTUKUF1U4z-p87i:APA91bGAuVs1QIv0oQj8g3ELK-tpd2BpAu2do9yLLq6_HOAVPgc_VwjUOcfnT6bf5hMA9IiQjsoYiXCTltyJedIL3wXuoPslW4CcEU1eFO6h3lGNlOzM2Js", // FCM Token của thiết bị nhận
  //     "Thông báo tiền nước!",
  //     "Hóa đơn tháng này là 500,000 VND."
  // );
  //
  // //Thêm lắng nghe sự kiện khi token thay đổi
  // FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async{
  //   print("FCM Token refreshed: $newToken");
  //   await _saveTokenToFirestore(newToken);
  // });

  // Khởi chạy ứng dụng
  runApp(
    ScreenUtilInit(
      // designSize: const Size(384, 856.1777777777778),
      designSize: const Size(384, 856.1777777777778),
      minTextAdapt: true,
      splitScreenMode: true, // Hỗ trợ màn hình chia đôi
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
            ChangeNotifierProvider(create: (_) => StaffImageProvider()),
            ChangeNotifierProvider(create: (_) => CompanyImageProvider()),
            ChangeNotifierProvider(create: (_) => ContractNotifier()),
          ],
          child: MyApp(
            AuthBloc(),
            MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: 'Montserrat',
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: ResponsiveBreakpoints.builder(
                  child: child!,
                  breakpoints: [
                    const Breakpoint(start: 0, end: 899, name: MOBILE),             // Điện thoại nhỏ & vừa (iPhone, Android phổ biến)
                    const Breakpoint(start: 900, end: 1279, name: TABLET),          // Tablet (iPad, Galaxy Tab, điện thoại gập ngang)
                    const Breakpoint(start: 1280, end: 1919, name: DESKTOP),        // Laptop cơ bản (13"–14")
                    const Breakpoint(start: 1920, end: double.infinity, name: '4K'), // Màn hình 2K, 4K, ultrawide
                  ],
                ),
              ),
              home: LoginPage(), // hoặc AuthWrapper()
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

// Hàm lưu token FCM vào Firestore
Future<void> _saveTokenToFirestore(String newToken) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return; // Không có userId thì thoát luôn

  try {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot userDoc = await userRef.get();

    if (userDoc.exists) {
      List<String> tokens = List<String>.from(userDoc['fcmTokens'] ?? []);

      if (!tokens.contains(newToken)) {
        // Nếu token chưa tồn tại thì thêm vào danh sách
        await userRef.update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } else {
      // Nếu user chưa có tài liệu, tạo mới với danh sách token
      await userRef.set({
        'fcmTokens': [newToken],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
    print("FCM Token saved successfully!");
  } catch (e) {
    print("Error saving FCM Token: $e");
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
