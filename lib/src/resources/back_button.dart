import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:html' as html;

class BackButtonWidget extends StatelessWidget {
  final Color iconColor;
  final Color backgroundColor;

  const BackButtonWidget({
    Key? key,
    this.iconColor = Colors.black,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Để ripple hiển thị đúng
      child: InkWell(
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            html.window.history.back(); // fallback for Flutter Web
          }
        },
        borderRadius: BorderRadius.circular(100.r), // bo tròn ripple
        splashColor: Colors.grey.withOpacity(0.3), // màu splash
        highlightColor: Colors.grey.withOpacity(0.15), // màu nhấn giữ
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(1.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Icon(Icons.arrow_back, size: 8.w, color: iconColor),
        ),
      ),
    );
  }
}
