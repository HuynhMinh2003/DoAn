import 'package:do_an/src/resources/back_button.dart';
import 'package:do_an/src/resources/chon_can_ho_page.dart';
import 'package:do_an/src/resources/ds_canho_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ApartmentPage extends StatelessWidget {
  const ApartmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset('assets/images/two_circle.png', width: 160),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(100.w, 280.h, 100.w, 0.h),
                child:
                GridView.count(
                  crossAxisCount: 2, // hiển thị 2 cột
                  mainAxisSpacing: 6.h,
                  crossAxisSpacing: 60.w,
                  shrinkWrap: true,
                  children: [
                    _buildCard(context, 'Hợp đồng ', 'assets/images/image_manage_contract.svg', ApartmentFilterPage()),
                    _buildCard(context, 'Danh sách phòng', 'assets/images/image_list_room.svg', ApartmentListPage()),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/2,
              left: 10.w,
              child: const BackButtonWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String label, String svgPath, Widget destinationPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinationPage),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        color: Colors.white,
        elevation: 4,
        child: SingleChildScrollView(child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50.h),
                SvgPicture.asset(svgPath, width: 100.w, height: 100.h),
                SizedBox(height: 30.h),
                Text(label, style: TextStyle(fontFamily:"Oswald",fontSize: 6.sp, fontWeight: FontWeight.w700)),
              ],
            )
        ),
      ),
    );
  }
}
