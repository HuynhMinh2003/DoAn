import 'package:do_an/constants.dart';
import 'package:do_an/screens/dashboard/dashboard_screen.dart';
import 'package:do_an/src/resources/chon_can_ho_page.dart';
import 'package:do_an/src/resources/ds_canho_page.dart';
import 'package:do_an/src/resources/ds_congty_page.dart';
import 'package:do_an/src/resources/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/resident_page.dart';
import 'package:do_an/src/resources/tao_tk_ctdv_ngoai.dart';
import 'package:do_an/src/resources/tao_tk_nv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SideMenu extends StatelessWidget {
  final bool isMenuOpen; // Nhận trạng thái mở/đóng từ MainScreen
  final Function(Widget) onMenuItemPressed; // Callback để thay đổi màn hình

  const SideMenu({
    Key? key,
    required this.isMenuOpen,
    required this.onMenuItemPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16), // Góc bo tròn ở trên bên phải
        bottomRight: Radius.circular(16), // Góc bo tròn ở dưới bên phải
      ),
      child: Container(
        color: secondaryColor, // Màu nền của menu
        child: Column(
          children: [
            DrawerHeader(
              child: isMenuOpen
                  ? Image.asset("assets/images/logo.png") // Hiển thị logo khi mở
                  : Image.asset("assets/images/logo.png"), // Chỉ icon khi đóng
            ),
            Expanded(
              child: ListView(
                children: [
                  DrawerListTile(
                    title: "Trang chủ",
                    svgSrc: "assets/icons/menu_dashboard.svg",
                    press: () {
                      onMenuItemPressed(DashboardScreen()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Hợp đồng căn hộ",
                    svgSrc: "assets/icons/menu_tran.svg",
                    press: () {
                      onMenuItemPressed(ApartmentFilterPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Danh sách căn hộ",
                    svgSrc: "assets/icons/menu_task.svg",
                    press: () {
                      onMenuItemPressed(ApartmentListPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Tạo tài khoản nhân viên",
                    svgSrc: "assets/icons/menu_doc.svg",
                    press: () {
                      onMenuItemPressed(AddAccountStaffPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Danh sách nhân viên",
                    svgSrc: "assets/icons/menu_store.svg",
                    press: () {
                      onMenuItemPressed(StaffListPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Thông tin cư dân",
                    svgSrc: "assets/icons/menu_profile.svg",
                    press: () {
                      onMenuItemPressed(ResidentPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Tạo tài khoản công ty",
                    svgSrc: "assets/icons/menu_notification.svg",
                    press: () {
                      onMenuItemPressed(AddAccountCompanyPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Danh sách công ty",
                    svgSrc: "assets/icons/menu_profile.svg",
                    press: () {
                      onMenuItemPressed(CompanyListPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerListTile extends StatefulWidget {
  final String title, svgSrc;
  final VoidCallback press;
  final bool isMenuOpen; // Nhận trạng thái mở/đóng từ SideMenu

  const DrawerListTile({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
    required this.isMenuOpen,
  }) : super(key: key);

  @override
  _DrawerListTileState createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<DrawerListTile> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isPressed = true;
        });
        Future.delayed(Duration(milliseconds: 200), () {
          setState(() {
            isPressed = false;
          });
          widget.press(); // Gọi callback khi nhấn
        });
      },
      splashColor: Colors.white24, // Hiệu ứng "splash" khi nhấn vào
      highlightColor: Colors.transparent, // Không có màu nền sáng
      child: Container(
        child: ListTile(
          horizontalTitleGap: widget.isMenuOpen ? 16.0 : 0.0, // Khoảng cách giữa icon và chữ khi mở menu
          leading: SvgPicture.asset(
            widget.svgSrc,
            colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
            height: 24,
          ),
          title: widget.isMenuOpen
              ? Text(
            widget.title,
            style: TextStyle(
              color: isPressed ? Colors.white : Colors.white54, // Đổi màu chữ khi nhấn
              fontWeight: isPressed ? FontWeight.bold : FontWeight.normal, // Làm chữ in đậm khi nhấn
            ),
          )
              : null, // Không hiển thị tiêu đề khi menu đóng
        ),
      ),
    );
  }
}