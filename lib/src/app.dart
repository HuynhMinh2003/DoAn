import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:flutter/material.dart';

class MyApp extends InheritedWidget {
  AuthBloc authBloc;
  Widget child;

  MyApp(this.authBloc, this.child) : super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    // TODO: implement updateShouldNotify
    return false;
  }

  static MyApp of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyApp>()!;
  }
}

// import 'package:do_an/src/blocs/auth_bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:do_an/firebase_options.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:rxdart/rxdart.dart';
//
// // Stream controller để quản lý tin nhắn nhận được
// final _messageStreamController = BehaviorSubject<RemoteMessage>();
//
// class MyApp extends InheritedWidget {
//   AuthBloc authBloc;
//   Widget child;
//
//   MyApp(this.authBloc, this.child) : super(child: child);
//
//   @override
//   bool updateShouldNotify(covariant InheritedWidget oldWidget) {
//     return false; // Nếu bạn muốn cập nhật khi có thay đổi, trả về true
//   }
//
//   static MyApp of(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType<MyApp>()!;
//   }
// }
//
// // Widget để hiển thị tin nhắn cuối cùng nhận được
// class StatusWidget extends StatefulWidget {
//   @override
//   _StatusWidgetState createState() => _StatusWidgetState();
// }
//
// class _StatusWidgetState extends State<StatusWidget> {
//   String _lastMessage = "";
//
//   // Lắng nghe tin nhắn từ stream
//   _StatusWidgetState() {
//     _messageStreamController.listen((message) {
//       setState(() {
//         if (message.notification != null) {
//           _lastMessage = 'Nhận được tin nhắn thông báo:\nTiêu đề=${message.notification?.title},\nNội dung=${message.notification?.body},\nDữ liệu=${message.data}';
//         } else {
//           _lastMessage = 'Nhận được tin nhắn dữ liệu: ${message.data}';
//         }
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Ví dụ Firebase Messaging'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text('Tin nhắn cuối cùng từ Firebase Messaging:'),
//             Text(
//               _lastMessage,
//               style: Theme.of(context).textTheme.bodyLarge,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
