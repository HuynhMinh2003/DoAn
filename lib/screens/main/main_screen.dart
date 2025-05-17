import 'package:do_an/controllers/menu_app_controller.dart';
import 'package:do_an/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isMenuOpen = false; // Trạng thái mở/đóng của SideMenu
  Widget _currentScreen = DashboardScreen(); // Màn hình hiện tại

  // Hàm để thay đổi màn hình
  void updateScreen(Widget newScreen) {
    setState(() {
      _currentScreen = newScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Image.asset("assets/images/logo.png"),
            ),
            ListTile(
              title: Text("Dashboard"),
              onTap: () {
                updateScreen(DashboardScreen());
                Navigator.pop(context); // Đóng Drawer sau khi chọn
              },
            ),
            ListTile(
              title: Text("Another Page"),
              onTap: () {
                updateScreen(Center(child: Text("Another Page"))); // Thay đổi nội dung
                Navigator.pop(context); // Đóng Drawer sau khi chọn
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SideMenu hiển thị với kích thước thay đổi dựa trên trạng thái isMenuOpen
            AnimatedContainer(
              duration: Duration(milliseconds: 300), // Hoạt ảnh mượt mà
              width: isMenuOpen ? 258 : 70, // 250 khi mở, 70 khi đóng
              child: SideMenu(
                isMenuOpen: isMenuOpen,
                onMenuItemPressed: updateScreen, // Truyền callback để thay đổi màn hình
              ),
            ),
            Expanded(
              // Nội dung chính
              child: _currentScreen, // Hiển thị màn hình hiện tại
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isMenuOpen = !isMenuOpen; // Thay đổi trạng thái mở/đóng menu
          });
        },
        child: Icon(isMenuOpen ? Icons.close : Icons.menu), // Thay đổi icon
      ),
    );
  }
}