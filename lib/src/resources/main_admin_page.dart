import 'package:do_an/src/resources/chon_can_ho_page.dart';
import 'package:do_an/src/resources/ds_canho_page.dart';
import 'package:do_an/src/resources/ds_congty_page.dart';
import 'package:do_an/src/resources/ds_nhanvien_page.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/quan_li_web.dart';
import 'package:do_an/src/resources/tao_tk_nv.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Đăng xuất',
              style: TextStyle(
                  fontFamily: "Oswald",
                  fontWeight: FontWeight.bold,
                  fontSize: 25.sp),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: TextStyle(fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy', style: TextStyle(fontSize: 14.sp)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              child: Text('Đồng ý', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF7FEFF),
        elevation: 0, // Optional: Remove shadow for a cleaner look
        actions: [
          // Notification Icon
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: Colors.black87, // Color of the notification icon
            ),
            onPressed: () {
              // Handle notification icon tap
              print('Notification icon tapped');
            },
          ),
          SizedBox(width: 5.w,),
          // Circular Avatar
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: CircleAvatar(
              radius: 18.r,
              backgroundImage: AssetImage('assets/images/anh_nen.jpg'),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.black87, // Color of the notification icon
            ),
            onPressed: _logout,
          ),
          SizedBox(width: 5.w,)
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2B3A50)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Center-align the image and text vertically
                children: [
                  SizedBox(width:5.w),
                  // Circular Avatar for the Image
                  CircleAvatar(
                    radius: 45.r,
                    backgroundImage: AssetImage('assets/images/house.png'), // Path to the image
                  ),
                  SizedBox(width: 5.w), // Space between the image and text
                  // Text Section
                  Flexible(
                    child: Text(
                      'Quản lí \nchung cư',
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 6.sp, // Adjusted font size for better readability
                      ),
                    ),
                  ),
                ],
              ),
            ),            // Trang chủ
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

            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent, // ❌ Tắt gạch ngang mặc định
                splashColor: Colors.transparent, // ❌ Tắt ripple khi nhấn
                highlightColor:
                Colors.transparent, // ❌ Tắt highlight khi giữ lâu
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.business, color: Colors.black),
                title: Text(
                  '  Quản lí công ty dịch vụ',
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
                        const Icon(Icons.apartment, size: 20),
                      ],
                    ),
                    title: Text('  Tạo tài khoản công ty',
                        style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
                    onTap: () => _setPage(const AddAccountCompanyPage()),
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
                    title: Text('  Danh sách công ty',
                        style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
                    onTap: () => _setPage(const CompanyListPage()),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent, // Tắt line ngang mặc định
                splashColor: Colors.transparent, // Tắt hiệu ứng ripple khi nhấn
                highlightColor:
                Colors.transparent, // Tắt hiệu ứng highlight khi focus
              ),
              child: ExpansionTile(
                leading: const Icon(Icons.build, color: Colors.black),
                title: Text(
                  '  Quản lí dịch vụ ',
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
                        const Icon(Icons.price_check, size: 20),
                      ],
                    ),
                    title: Text(
                      ' Giá dịch vụ',
                      style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp),
                    ),
                    // onTap: () => _setPage(const ApartmentFilterPage()),
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
                        const Icon(Icons.plumbing, size: 20),
                      ],
                    ),
                    title: Text(' Các dịch vụ chung cư',
                        style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
                    // onTap: () => _setPage(const ApartmentListPage()),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            ListTile(
              leading: const Icon(Icons.notification_add),
              title: Text('  Quản lí thông báo chung',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
              // onTap: () => _setPage(const AdminWebPage()),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            ListTile(
              leading: const Icon(Icons.payments_sharp),
              title: Text('  Quản lí thanh toán',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
              // onTap: () => _setPage(const AdminWebPage()),
            ),

            const Divider(thickness: 0.5, color: Colors.grey),

            ListTile(
              leading: const Icon(Icons.warning),
              title: Text('  Quản lí sự cố',
                  style: TextStyle(fontFamily: "Oswald", fontSize: 5.sp)),
              // onTap: () => _setPage(const AdminWebPage()),
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
