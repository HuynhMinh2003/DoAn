// file_info_card.dart
import 'package:do_an/src/models/my_files.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants.dart';

class FileInfoCard extends StatelessWidget {
  const FileInfoCard({super.key, required this.info});

  final CloudStorageInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon thu gọn và đặt giữa
          SizedBox(
            height: 50,
            width: 50,
            child: SvgPicture.asset(info.svgSrc ?? '', fit: BoxFit.contain),
          ),

          const SizedBox(height: defaultPadding*0.8),

          // Tiêu đề
          Text(
            info.category,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.bold,
              fontSize: 4.sp,
            ),
          ),

          const SizedBox(height: defaultPadding*0.8),

          // Hai cột: Đang làm - Đã nghỉ
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      info.labelWorking,
                      style: TextStyle(fontSize: 3.sp, color: Colors.green),
                    ),
                    Text(
                      '${info.working}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 6.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: defaultPadding*1.5,),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      info.labelResigned,
                      style: TextStyle(fontSize: 3.sp, color: Colors.red),
                    ),
                    Text(
                      '${info.resigned}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 6.sp,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
