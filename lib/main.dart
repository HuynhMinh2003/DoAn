import 'dart:async';
import 'package:do_an/firebase_options.dart';
import 'package:do_an/src/resources/provider/admin_image_provider.dart';
import 'package:do_an/src/resources/provider/company_image_provider.dart';
import 'package:do_an/src/resources/provider/contract_notifier_provider.dart';
import 'package:do_an/src/resources/provider/resident_image_provider.dart';
import 'package:do_an/src/resources/provider/staff_image_provider.dart';
import 'package:do_an/src/resources/provider/user_data_provider.dart';
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

FirebaseOptions getFirebaseOptions() {
  if (kIsWeb) {
    return const FirebaseOptions(
      apiKey: "REDACTED_FIREBASE_API_KEY_1",
      authDomain: "REDACTED_PROJECT_ID.firebaseapp.com",
      databaseURL: "https://REDACTED_PROJECT_ID-default-rtdb.firebaseio.com",
      projectId: "REDACTED_PROJECT_ID",
      storageBucket: "REDACTED_PROJECT_ID.firebasestorage.app",
      messagingSenderId: "REDACTED_MESSAGING_SENDER_ID",
      appId: "REDACTED_APP_ID",
      measurementId: "REDACTED_MEASUREMENT_ID",
    );
  } else {
    return FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      authDomain: dotenv.env['AUTH_DOMAIN'],
      databaseURL: dotenv.env['DATABASE_URL'],
      projectId: dotenv.env['PROJECT_ID']!,
      storageBucket: dotenv.env['STORAGE_BUCKET'],
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      appId: dotenv.env['APP_ID']!,
      measurementId: dotenv.env['MEASUREMENT_ID'],
    );
  }
}

// Create StreamController to manage message flow
final _messageStreamController = BehaviorSubject<RemoteMessage>();

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// GlobalKey to use ScaffoldMessenger in the application
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? "Notification";
    final body = message.notification?.body ?? "";

    flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel_id',
          'System Notifications',
          channelDescription: 'Notifications displayed when app is open',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  });
}

// Close StreamController when app exits
void disposeControllers() {
  _messageStreamController.close();
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// Function to request notification permissions
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
}

// Function to register FCM and get token
Future<void> _registerWithFCM() async {
  const vapidKey = "REDACTED_VAPID_KEY";
  final messaging = FirebaseMessaging.instance;

  String? token;

  // Get token for web with VAPID Key
  if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
    token = await messaging.getToken(vapidKey: vapidKey);
  } else {
    token = await messaging.getToken();
  }
}

Future<void> _handleInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
}

// Main function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only load .env on mobile (Web will error because there's no assets/.env)
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

  // Set status bar color
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  // Register background message handler (mobile only)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await _requestNotificationPermissions();

  // Register and get FCM token
  await _registerWithFCM();

  await _handleInitialMessage();

  // Register foreground message handler
  _setupForegroundMessageHandler();

  runApp(
    ScreenUtilInit(
      designSize: const Size(384, 856.1777777777778),
      minTextAdapt: true,
      splitScreenMode: true,

      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          double screenWidth = MediaQuery.of(context).size.width;
          double screenHeight = MediaQuery.of(context).size.height;
        });

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ResidentProvider()),
            ChangeNotifierProvider(create: (_) => UserDataProvider()),
            ChangeNotifierProvider(create: (_) => CompanyImageProvider()),
            ChangeNotifierProvider(create: (_) => StaffImageProvider()),
            ChangeNotifierProvider(create: (_) => ResidentImageProvider()),
            ChangeNotifierProvider(create: (_) => AdminImageProvider()),
            ChangeNotifierProvider(create: (_) => ContractNotifierProvider()),
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
