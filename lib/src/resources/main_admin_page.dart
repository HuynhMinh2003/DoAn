import 'package:do_an/src/resources/chon_can_ho_page.dart';
import 'package:do_an/src/resources/ds_canho_page.dart';
import 'package:do_an/src/resources/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/quan_li_web.dart';
import 'package:do_an/src/resources/tao_tk_nv.dart';
import 'package:flutter/material.dart';
import 'package:do_an/src/resources/resident_page.dart';
import 'package:do_an/src/resources/tao_tk_ctdv_ngoai.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainAdminPage extends StatefulWidget {
  const MainAdminPage({super.key});

  @override
  State<MainAdminPage> createState() => _MainAdminPageState();
}

class _MainAdminPageState extends State<MainAdminPage> {
  Widget _currentPage = AdminWebPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF7FEFF),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                decoration: BoxDecoration(color: Colors.blueAccent),
                child: Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Text('Xin chào, \nBan quản lí',
                      style: TextStyle(
                          fontFamily: "Oswald",
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 8.sp)),
                )),

            // Trang chủ
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text('  Trang chủ',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
              onTap: () => _setPage(const AdminWebPage()),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            // Quản lý căn hộ
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent, // Tắt line ngang mặc định
                splashColor: Colors.transparent, // Tắt hiệu ứng ripple khi nhấn
                highlightColor:
                    Colors.transparent, // Tắt hiệu ứng highlight khi focus
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.home, color: Colors.black),
                title: Text(
                  '  Quản lí căn hộ',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp),
                ),
                children: [
                  ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12, // Độ dài gạch ngang
                          height: 1,
                          color: Colors.black, // Màu mờ
                          margin: const EdgeInsets.only(
                              right: 8), // Khoảng cách với icon
                        ),
                        const Icon(Icons.article_outlined, size: 20),
                      ],
                    ),
                    title: Text(
                      '  Hợp đồng',
                      style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp),
                    ),
                    onTap: () => _setPage(const ApartmentFilterPage()),
                  ),
                  ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12, // Độ dài gạch ngang
                          height: 1,
                          color: Colors.black, // Màu mờ
                          margin: const EdgeInsets.only(
                              right: 8), // Khoảng cách với icon
                        ),
                        const Icon(Icons.meeting_room_outlined, size: 20),
                      ],
                    ),
                    title: Text('  Danh sách phòng',
                        style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
                    onTap: () => _setPage(const ApartmentListPage()),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent, // ❌ Tắt gạch ngang mặc định
                splashColor: Colors.transparent, // ❌ Tắt ripple khi nhấn
                highlightColor:
                    Colors.transparent, // ❌ Tắt highlight khi giữ lâu
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.people, color: Colors.black),
                title: Text(
                  '  Quản lí nhân viên',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp),
                ),
                children: [
                  ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12, // Độ dài gạch ngang
                          height: 1,
                          color: Colors.black, // Màu mờ
                          margin: const EdgeInsets.only(
                              right: 8), // Khoảng cách với icon
                        ),
                        const Icon(Icons.person_add_alt_1, size: 20),
                      ],
                    ),
                    title: Text('  Tạo tài khoản nhân viên',
                        style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
                    onTap: () => _setPage(const AddAccountStaffPage()),
                  ),
                  ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12, // Độ dài gạch ngang
                          height: 1,
                          color: Colors.black, // Màu mờ
                          margin: const EdgeInsets.only(
                              right: 8), // Khoảng cách với icon
                        ),
                        const Icon(Icons.list_alt_outlined, size: 20),
                      ],
                    ),
                    title: Text('  Danh sách nhân viên',
                        style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
                    onTap: () => _setPage(const StaffListPage()),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            // Quản lý cư dân
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text('  Quản lí cư dân',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
              onTap: () => _setPage(ResidentPage()),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            // Công ty dịch vụ ngoài
            ListTile(
              leading: const Icon(Icons.business),
              title: Text('  Quản lí dịch vụ ngoài',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
              onTap: () => _setPage(const AddAccountCompanyPage()),
            ),
          ],
        ),
      ),
      body: _currentPage,
    );
  }

  void _setPage(Widget page) {
    setState(() {
      _currentPage = page;
    });
    Navigator.pop(context); // Đóng drawer sau khi chọn
  }
}
