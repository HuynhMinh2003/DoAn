import 'package:do_an/constants.dart';
import 'package:do_an/screens/dashboard/dashboard_screen.dart';
import 'package:do_an/src/resources/ds_canho_page.dart';
import 'package:do_an/src/resources/ds_congty_page.dart';
import 'package:do_an/src/resources/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/resident_page.dart';
import 'package:do_an/src/resources/tao_tk_ctdv_ngoai.dart';
import 'package:do_an/src/resources/tao_tk_nv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../src/resources/ds_hopdong_canho_page.dart';
import '../../../src/resources/list_incident_page.dart';
import '../../../src/resources/manage_incident_page.dart';
import '../../../src/resources/send_notification_page.dart';
import '../../../src/resources/update_fee_page.dart';

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
                  ExpandableDrawerListTile(
                    title: "Quản lý căn hộ",
                    svgSrc: "assets/icons/menu_apartment.svg",
                    isMenuOpen: isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Hợp đồng dịch vụ",
                        svgSrc: "assets/icons/menu_hd_apartment.svg",
                        press: () {
                          onMenuItemPressed(ContractListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách căn hộ",
                        svgSrc: "assets/icons/menu_list_apartment.svg",
                        press: () {
                          onMenuItemPressed(ApartmentListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                    ],
                  ),
                  ExpandableDrawerListTile(
                    title: "Quản lý nhân viên",
                    svgSrc: "assets/icons/menu_staff.svg",
                    isMenuOpen: isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Tạo tài khoản nhân viên",
                        svgSrc: "assets/icons/menu_add_staff.svg",
                        press: () {
                          onMenuItemPressed(AddAccountStaffPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách nhân viên",
                        svgSrc: "assets/icons/menu_list_staff.svg",
                        press: () {
                          onMenuItemPressed(StaffListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                    ],
                  ),
                  DrawerListTile(
                    title: "Thông tin cư dân",
                    svgSrc: "assets/icons/menu_profile.svg",
                    press: () {
                      onMenuItemPressed(ResidentPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: isMenuOpen,
                  ),
                  ExpandableDrawerListTile(
                    title: "Quản lý công ty",
                    svgSrc: "assets/icons/menu_company.svg",
                    isMenuOpen: isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Tạo tài khoản công ty",
                        svgSrc: "assets/icons/menu_add_company.svg",
                        press: () {
                          onMenuItemPressed(AddAccountCompanyPage());
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách công ty",
                        svgSrc: "assets/icons/menu_list_company.svg",
                        press: () {
                          onMenuItemPressed(CompanyListPage());
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                    ],
                  ),
                  ExpandableDrawerListTile(
                    title: "Quản lý dịch vụ",
                    svgSrc: "assets/icons/service.svg",
                    isMenuOpen: isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Cập nhật giá dịch vụ",
                        svgSrc: "assets/icons/edit_fee_service.svg",
                        press: () {
                          onMenuItemPressed(UpdateFeeScreen());
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách dịch vụ",
                        svgSrc: "assets/icons/menu_profile.svg",
                        press: () {
                          onMenuItemPressed(CompanyListPage());
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                    ],
                  ),
                  ExpandableDrawerListTile(
                    title: "Quản lý thông báo",
                    svgSrc: "assets/icons/notification.svg",
                    isMenuOpen: isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Đăng thông báo chung",
                        svgSrc: "assets/icons/post_notification.svg",
                        press: () {
                          onMenuItemPressed(InfoPage());
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách thông báo",
                        svgSrc: "assets/icons/menu_profile.svg",
                        press: () {
                          onMenuItemPressed(CompanyListPage());
                        },
                        isMenuOpen: isMenuOpen,
                      ),
                    ],
                  ),
                  ExpandableDrawerListTile(title: 'Quản lý sự cố', svgSrc: "assets/icons/attention.svg", isMenuOpen: isMenuOpen, children: [
                    DrawerListTile(
                      title: "Sự cố mới",
                      svgSrc: "assets/icons/new_error.svg",
                      press: () {
                        onMenuItemPressed(ManagerIncidentPage()); // Chuyển sang Dashboard
                      },
                      isMenuOpen: isMenuOpen,
                    ),
                    DrawerListTile(
                      title: "Danh sách sự cố",
                      svgSrc: "assets/icons/list_error.svg",
                      press: () {
                        onMenuItemPressed(ListIncidentPage()); // Chuyển sang Dashboard
                      },
                      isMenuOpen: isMenuOpen,
                    ),
                  ])

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
  final bool isMenuOpen;
  final bool isChild; // để phân biệt item con

  const DrawerListTile({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
    required this.isMenuOpen,
    this.isChild = false,
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
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            isPressed = false;
          });
          widget.press();
        });
      },
      splashColor: Colors.white24,
      highlightColor: Colors.transparent,
      child: ListTile(
        horizontalTitleGap: widget.isMenuOpen
            ? (widget.isChild ? 8.0 : 16.0)
            : 0.0, // giảm gap nếu là mục con
        leading: SizedBox(
          width: 24,
          height: 24,
          child: SvgPicture.asset(
            widget.svgSrc,
            colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
          ),
        ),

        title: widget.isMenuOpen
            ? Text(
          widget.title,
          style: TextStyle(
            color: isPressed ? Colors.white : Colors.white54,
            fontWeight: isPressed ? FontWeight.bold : FontWeight.normal,
          ),
        )
            : null,
      ),
    );
  }
}

class ExpandableDrawerListTile extends StatefulWidget {
  final String title, svgSrc;
  final bool isMenuOpen;
  final List<DrawerListTile> children;

  const ExpandableDrawerListTile({
    super.key,
    required this.title,
    required this.svgSrc,
    required this.isMenuOpen,
    required this.children,
  });

  @override
  State<ExpandableDrawerListTile> createState() => _ExpandableDrawerListTileState();
}

class _ExpandableDrawerListTileState extends State<ExpandableDrawerListTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: ListTile(
            horizontalTitleGap: widget.isMenuOpen ? 16.0 : 0.0,
            leading: SvgPicture.asset(
              widget.svgSrc,
              colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
              height: 24,
            ),
            title: widget.isMenuOpen
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            )
                : null,
          ),
        ),
        if (_expanded)
          ...widget.children.map((child) {
            return Padding(
              padding: EdgeInsets.only(left: widget.isMenuOpen ? 6.0 : 0.0),
              child: child,
            );
          }).toList(),
      ],
    );
  }
}
