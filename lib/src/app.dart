import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  final AuthBloc authBloc;
  final Widget child;

  const MyApp(this.authBloc, this.child, {Key? key}) : super(key: key);

  static MyAppState of(BuildContext context) {
    final state = context.findAncestorStateOfType<MyAppState>();
    assert(state != null, 'MyAppState not found in context');
    return state!;
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _safeShowDialog(message.notification?.title, message.notification?.body);
    });

    // When app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _safeShowDialog(message.notification?.title, message.notification?.body);
    });

    // When app launched from terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _safeShowDialog(message.notification?.title, message.notification?.body);
      }
    });
  }

  void _safeShowDialog(String? title, String? body) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Center(
              child: Text(
                title ?? 'Thông báo',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            content: Text(
              body ?? '',
              style: TextStyle(fontSize: 15.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(fontSize: 15.sp)),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  AuthBloc get authBloc => widget.authBloc;
}
