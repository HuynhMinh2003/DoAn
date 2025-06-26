import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/constants.dart';
import 'package:do_an/screens/dashboard/dashboard_screen.dart';
import 'package:do_an/src/resources/admin/ds_canho_page.dart';
import 'package:do_an/src/resources/admin/ds_congty_page.dart';
import 'package:do_an/src/resources/admin/ds_dangkixe_page.dart';
import 'package:do_an/src/resources/admin/ds_hopdong_canho_page.dart';
import 'package:do_an/src/resources/admin/ds_thongbao_page.dart';
import 'package:do_an/src/resources/admin/list_incident_page.dart';
import 'package:do_an/src/resources/admin/list_wait_update_service_page.dart';
import 'package:do_an/src/resources/admin/manage_incident_page.dart';
import 'package:do_an/src/resources/admin/resident_page.dart';
import 'package:do_an/src/resources/admin/send_notification_page.dart';
import 'package:do_an/src/resources/admin/tao_tk_ctdv_ngoai.dart';
import 'package:do_an/src/resources/admin/update_fee_page.dart';
import 'package:do_an/src/resources/admin/wait_update_service_page.dart';
import 'package:do_an/src/resources/admin/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/admin/tao_tk_nv.dart';
import 'package:do_an/src/resources/base_admin_screen_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../src/resources/admin/ds_ghichisonuoc_page.dart';
import '../../../src/resources/admin/ds_thanhtoan_page.dart';

class SideMenu extends StatefulWidget {
  final bool isMenuOpen; // Nhận trạng thái mở/đóng từ MainScreen
  final Function(Widget) onMenuItemPressed; // Callback để thay đổi màn hình

  const SideMenu({
    Key? key,
    required this.isMenuOpen,
    required this.onMenuItemPressed,
  }) : super(key: key);

  @override
  _SideMenuState createState() => _SideMenuState();

}

class _SideMenuState extends BaseAdminInfoScreen<SideMenu> {
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
              child: widget.isMenuOpen
                  ? SvgPicture.asset("assets/images/logo.svg") // Hiển thị logo khi mở
                  : SvgPicture.asset("assets/images/logo.svg"), // Chỉ icon khi đóng
            ),
            Expanded(
              child: ListView(
                children: [
                  DrawerListTile(
                    title: "Trang chủ",
                    svgSrc: "assets/icons/menu_dashboard.svg",
                    press: () {
                      widget.onMenuItemPressed(DashboardScreen()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: widget.isMenuOpen,
                  ),
                  ExpandableDrawerListTile(
                    title: "Quản lý danh sách",
                    svgSrc: "assets/icons/menu_apartment.svg",
                    isMenuOpen: widget.isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Danh sách căn hộ",
                        svgSrc: "assets/icons/menu_list_apartment.svg",
                        press: () {
                          widget.onMenuItemPressed(ApartmentListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách nhân viên",
                        svgSrc: "assets/icons/menu_list_staff.svg",
                        press: () {
                          widget.onMenuItemPressed(StaffListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách công ty",
                        svgSrc: "assets/icons/menu_list_company.svg",
                        press: () {
                          widget.onMenuItemPressed(CompanyListPage());
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách cư dân",
                        svgSrc: "assets/icons/person.svg",
                        press: () {
                          widget.onMenuItemPressed(ResidentPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách thông báo",
                        svgSrc: "assets/icons/notification.svg",
                        press: () {
                          widget.onMenuItemPressed(InfoListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách đăng ký xe",
                        svgSrc: "assets/icons/parking.svg",
                        press: () {
                          widget.onMenuItemPressed(RegistrationListPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Danh sách chỉ số nước",
                        svgSrc: "assets/icons/water.svg",
                        press: () {
                          widget.onMenuItemPressed(ReadCSNPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                    ],
                  ),
                  ExpandableDrawerListTile(
                    title: "Quản lý tạo tài khoản",
                    svgSrc: "assets/icons/menu_staff.svg",
                    isMenuOpen: widget.isMenuOpen,
                    children: [
                      DrawerListTile(
                        title: "Tạo tài khoản nhân viên",
                        svgSrc: "assets/icons/menu_add_staff.svg",
                        press: () {
                          widget.onMenuItemPressed(AddAccountStaffPage()); // Chuyển sang Dashboard
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                      DrawerListTile(
                        title: "Tạo tài khoản công ty",
                        svgSrc: "assets/icons/add_company.svg",
                        press: () {
                          widget.onMenuItemPressed(AddAccountCompanyPage());
                        },
                        isMenuOpen: widget.isMenuOpen,
                      ),
                    ],
                  ),
                  DrawerListTile(
                    title: "Quản lý hợp đồng dịch vụ",
                    svgSrc: "assets/icons/menu_hd_apartment.svg",
                    press: () {
                      widget.onMenuItemPressed(ContractListPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: widget.isMenuOpen,
                  ),
                  DrawerListTile(
                    title: "Quản lý thanh toán",
                    svgSrc: "assets/icons/wallet.svg",
                    press: () {
                    widget.onMenuItemPressed(PaymentPage()); // Chuyển sang Dashboard
                    },
                    isMenuOpen: widget.isMenuOpen,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('incidents')
                        .where('status', isEqualTo: 'Đang chờ xử lý')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      final unseenDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final seenBy = List<String>.from(data['seenBy'] ?? []);
                        return adminInfo?.uid != null && !seenBy.contains(adminInfo!.uid);
                      }).toList();

                      final count = unseenDocs.length;

                      return ExpandableDrawerListTile(
                        title: "Quản lý sự cố",
                        svgSrc: "assets/icons/warning.svg",
                        isMenuOpen: widget.isMenuOpen,
                        children: [
                          DrawerListTile1(
                            title: "Điều phối xử lý sự cố mới",
                            svgSrc: "assets/icons/new_error.svg",
                            badgeCount: count > 0 ? count : null,
                            press: () {
                              for (final doc in unseenDocs) {
                                doc.reference.update({
                                  'seenBy': FieldValue.arrayUnion([adminInfo!.uid]),
                                });
                              }
                              widget.onMenuItemPressed(ManagerIncidentPage());
                            },
                            isMenuOpen: widget.isMenuOpen,
                          ),
                          DrawerListTile(
                            title: "Danh sách sự cố",
                            svgSrc: "assets/icons/list_error.svg",
                            press: () {
                              widget.onMenuItemPressed(ListIncidentPage());
                            },
                            isMenuOpen: widget.isMenuOpen,
                          ),
                        ],
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('updateService')
                        .where('status', isEqualTo: 'Đang chờ duyệt')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      final unseenDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final seenBy = List<String>.from(data['seenBy'] ?? []);
                        return adminInfo?.uid != null && !seenBy.contains(adminInfo!.uid);
                      }).toList();

                      final count = unseenDocs.length;

                      return ExpandableDrawerListTile(
                        title: "Quản lý dịch vụ",
                        svgSrc: "assets/icons/customer_service.svg",
                        isMenuOpen: widget.isMenuOpen,
                        children: [
                          DrawerListTile(
                            title: "Danh sách yêu cầu cập nhật dịch vụ ngoài",
                            svgSrc: "assets/icons/wait_update_service.svg",
                            press: () {
                              widget.onMenuItemPressed(WaitUpdateServicePage());
                            },
                            isMenuOpen: widget.isMenuOpen,
                          ),
                          DrawerListTile1(
                            title: "Duyệt yêu cầu thông tin dịch vụ ngoài",
                            svgSrc: "assets/icons/service.svg",
                            badgeCount: count > 0 ? count : null,
                            press: () {
                              for (final doc in unseenDocs) {
                                doc.reference.update({
                                  'seenBy': FieldValue.arrayUnion([adminInfo!.uid]),
                                });
                              }
                              widget.onMenuItemPressed(ListWaitUpdateServicePage());
                            },
                            isMenuOpen: widget.isMenuOpen,
                          ),
                          DrawerListTile(
                            title: "Cập nhật giá dịch vụ đi kèm",
                            svgSrc: "assets/icons/edit_fee_service.svg",
                            press: () {
                              widget.onMenuItemPressed(UpdateFeeScreen());
                            },
                            isMenuOpen: widget.isMenuOpen,
                          ),
                        ],
                      );
                    },
                  ),
                  DrawerListTile(
                    title: "Đăng thông báo chung",
                    svgSrc: "assets/icons/post_notification.svg",
                    press: () {
                      widget.onMenuItemPressed(InfoPage());
                    },
                    isMenuOpen: widget.isMenuOpen,
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

class DrawerListTile1 extends StatefulWidget {
  final String title, svgSrc;
  final VoidCallback press;
  final bool isMenuOpen;
  final bool isChild; // để phân biệt item con
  final int? badgeCount; // thêm trường badgeCount, có thể null

  const DrawerListTile1({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
    required this.isMenuOpen,
    this.isChild = false,
    this.badgeCount,  // thêm tham số vào constructor
  }) : super(key: key);

  @override
  _DrawerListTileState1 createState() => _DrawerListTileState1();
}

class _DrawerListTileState1 extends State<DrawerListTile1> {
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
        contentPadding: widget.isMenuOpen
            ? EdgeInsets.symmetric(horizontal: widget.isChild ? 8.0 : 16.0) // giảm padding ngang
            : EdgeInsets.zero,
        horizontalTitleGap: 16.0, // giảm khoảng cách giữa leading và title (mặc định 16)
        minLeadingWidth: 24,      // giữ kích thước leading
        minVerticalPadding: 0,    // giảm khoảng cách dọc nếu cần
        title: widget.isMenuOpen
            ? Text(
          widget.title,
          style: TextStyle(
            color: isPressed ? Colors.white : Colors.white54,
            fontWeight: isPressed ? FontWeight.bold : FontWeight.normal,
          ),
        )
            : null,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: SvgPicture.asset(
            widget.svgSrc,
            colorFilter: const ColorFilter.mode(Colors.white54, BlendMode.srcIn),
          ),
        ),
        trailing: widget.badgeCount != null && widget.badgeCount! > 0
            ? Padding(
          padding: const EdgeInsets.only(left: 0), // giảm khoảng cách badge với title
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.badgeCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
            : null,
      )
    );
  }
}

class ExpandableDrawerListTile extends StatefulWidget {
  final String title, svgSrc;
  final bool isMenuOpen;
  final List<Widget> children;  // <-- Sửa đây

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



