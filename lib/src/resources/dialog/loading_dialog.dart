import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingDialog {
  static void showLoadingDialog(BuildContext context, String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Container(
            color: Colors.white,
            height: 100.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const CircularProgressIndicator(),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 2.h, 0, 0),
                  child: Text(
                    msg,
                    style: TextStyle(fontSize: 7.sp),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop(LoadingDialog);
  }
}
