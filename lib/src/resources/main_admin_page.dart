import 'package:do_an/src/resources/apartment_page.dart';
import 'package:do_an/src/resources/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/resident_page.dart';
import 'package:do_an/src/resources/staff_page.dart';
import 'package:do_an/src/resources/tao_tk_ctdv_ngoai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainAdminPage extends StatefulWidget {
  const MainAdminPage({super.key});

  @override
  State<MainAdminPage> createState() => _MainAdminPageState();
}

class _MainAdminPageState extends State<MainAdminPage> {
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
                padding: EdgeInsets.fromLTRB(60.w, 170.h, 60.w, 0.h),
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 6.h,
                  crossAxisSpacing: 6.w,
                  shrinkWrap: true,
                  children: [
                    _buildCard(context, 'Quản lí căn hộ', 'assets/images/image_room.svg', const ApartmentPage()),
                    _buildCard(context, ' Quản lí nhân viên', 'assets/images/image_staff.svg', const StaffPage()),
                    _buildCard(context, ' Quản lí cư dân', 'assets/images/image_resident.svg', ResidentPage()),
                    _buildCard(context, ' Quản lí công ty\n  dịch vụ ngoài', 'assets/images/image_company.svg', const AddAccountCompanyPage()),
                    // Thêm các card khác nếu cần
                  ],
                ),
              ),
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


