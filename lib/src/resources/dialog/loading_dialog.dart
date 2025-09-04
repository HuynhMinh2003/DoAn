import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingDialog {
  static void showLoadingDialog(BuildContext context, String msg) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            height: isLandscape ? 200.h:150.h,
            width: 80.w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const CircularProgressIndicator(),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 50.h, 0, 0),
                  child: Text(
                    msg,
                    style: TextStyle(fontSize: isLandscape? 5.sp: 20.sp),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
