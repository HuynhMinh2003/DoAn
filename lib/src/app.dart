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

