import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MsgDialog {
  static void showMsgDialog(BuildContext context, String title, String msg) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r), // Góc bo tròn
        ),
        title: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.w700,
              fontSize: isLandscape? 7.sp: 25.sp,
            ),
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(fontSize: isLandscape? 4.sp: 13.sp),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(MsgDialog);
            },
            child: Text(
              "Đồng ý",
              style: TextStyle(fontSize: isLandscape? 3.5.sp:14.sp, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
