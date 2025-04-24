import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MsgDialog {
  static void showMsgDialog(BuildContext context, String title, String msg) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Center(child: Text(title, style: TextStyle(
            fontFamily: "Oswald",
            fontWeight: FontWeight.w700,
            fontSize: 7.sp,
          ),)),
          content: Text(msg, style: TextStyle(fontSize: 4.sp),textAlign: TextAlign.center),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(MsgDialog);
              },
              child: Text("Đồng ý", style: TextStyle(fontSize: 3.sp),),
            ),
          ],
        ));
  }
}
