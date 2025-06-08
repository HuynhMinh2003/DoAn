import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../responsive.dart';
import '../../../src/resources/admin_info_page.dart';
import '../../../src/resources/base_admin_screen_page.dart';
import '../../../src/resources/dialog/loading_dialog.dart';
import '../../../src/resources/provider/admin_image_provider.dart';
import '../../../src/resources/reset_pass_page.dart';

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ví dụ thêm menu icon như đoạn 2
        if (!Responsive.isDesktop(context))
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Your menu logic
            },
          ),
        if (!Responsive.isMobile(context))
          Text(
            "Trang chủ",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        if (!Responsive.isMobile(context))
          Spacer(flex: Responsive.isDesktop(context) ? 2 : 1),
        ProfileCardWithPopup(),
      ],
    );
  }
}

class ProfileCardWithPopup extends StatefulWidget {
  const ProfileCardWithPopup({Key? key}) : super(key: key);

  @override
  State<ProfileCardWithPopup> createState() => _ProfileCardWithPopupState();
}

class _ProfileCardWithPopupState extends BaseAdminInfoScreen<ProfileCardWithPopup> {
  final GlobalKey _profileKey = GlobalKey();

  Future<void> _showPopupMenu() async {
    final RenderBox renderBox = _profileKey.currentContext?.findRenderObject() as RenderBox;
    if (renderBox == null) return; // tránh lỗi nếu chưa layout xong

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      color: secondaryColor,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'changePassword',
          child: Text("Đổi mật khẩu"),
        ),
        PopupMenuItem(
          value: 'editProfile',
          child: Text("Chỉnh sửa thông tin"),
        ),
      ],
    );

    if (selected != null) {
      _handleMenuSelection(selected);
    }
  }

  void showEditDialog(BuildContext context) {
    final phoneController =
    TextEditingController(text: adminInfo?.phone ?? '');
    final nameController =
    TextEditingController(text: adminInfo?.fullName ?? '');
    final emailController =
    TextEditingController(text: adminInfo?.email ?? '');
    final bloc = EditAdminBloc();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<AdminImageProvider>(
          builder: (context, imageProvider, _) {
            return AlertDialog(
              title: Center(
                  child: Text('Chỉnh sửa thông tin',
                      style: TextStyle(
                          fontFamily: "Osward",
                          fontSize: 6.sp,
                          fontWeight: FontWeight.bold))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ảnh đại diện
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.white, // Nền trắng cho khung tròn
                          alignment: Alignment.center,
                          child: imageProvider.webImageBytes != null
                              ? Image.memory(
                            imageProvider.webImageBytes!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                              : imageProvider.selectedImageFile != null
                              ? Image.file(
                            imageProvider.selectedImageFile!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                              : (adminInfo?.imageUrl?.isNotEmpty ?? false)
                              ? Image.network(
                            adminInfo!.imageUrl!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, _, __) => SvgPicture.asset(
                              'assets/images/default_avatar.svg',
                              width: 60, // giảm kích thước ảnh mặc định
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          )
                              : SvgPicture.asset(
                            'assets/images/default_avatar.svg',
                            width: 60, // giảm kích thước ảnh mặc định
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text('Đổi ảnh đại diện',
                          style: TextStyle(fontSize: 4.sp)),
                      onPressed: () async => await imageProvider.pickImage(),
                    ),
                    const SizedBox(height: 4),

                    /// ✅ TextField with StreamBuilder (Email)
                    StreamBuilder<String?>(
                      stream: bloc.emailStream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            errorText: snapshot.data,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: bloc.changeEmail,
                        );
                      },
                    ),

                    const SizedBox(height: 4),

                    /// ✅ TextField with StreamBuilder (Phone)
                    StreamBuilder<String?>(
                      stream: bloc.phoneStream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            errorText: snapshot.data,
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: bloc.changePhone,
                        );
                      },
                    ),
                    const SizedBox(height: 4),

                    /// ✅ TextField with StreamBuilder (Phone)
                    StreamBuilder<String?>(
                      stream: bloc.nameStream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            errorText: snapshot.data,
                          ),
                          onChanged: bloc.changeName,
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    bloc.dispose();
                    imageProvider.deleteImage();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final phoneError = bloc.validatePhone(phoneController.text);
                    final emailError = bloc.validateEmail(emailController.text);
                    final nameError = bloc.validateName(nameController.text);

                    if (phoneError != null || emailError != null || nameError != null) {
                      bloc.changePhone(phoneController.text);
                      bloc.changeEmail(emailController.text);
                      bloc.changeName(nameController.text);
                      return;
                    }

                    try {
                      // Hiện loading dialog
                      LoadingDialog.showLoadingDialog(context, "Đang lưu...");

                      String? newUrl;

                      if (imageProvider.webImageBytes != null || imageProvider.selectedImageFile != null) {
                        final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_avatar.jpg';

                        newUrl = await imageProvider.uploadSelectedImageAndGetUrl1(
                          adminInfo!.uid!,
                          uniqueFileName,
                          oldImageUrl: adminInfo!.imageUrl,
                        );

                        if (newUrl != null) {
                          await FirebaseFirestore.instance
                              .collection('admins')
                              .doc(adminInfo!.uid!)
                              .update({'imageUrl': newUrl});
                        }
                      }

                      await updateAdminInfo(phoneController.text, emailController.text, nameController.text);

                      bloc.dispose();
                      Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog loading
                      Navigator.of(context).pop(); // Đóng màn hình hiện tại
                    } catch (e) {
                      Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog loading nếu có lỗi

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi khi lưu thông tin: $e")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Lưu', style: TextStyle(fontSize: 4.sp,color: Colors.white)),
                ),

              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateAdminInfo(String phone, String email, String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (uid == null || user == null) return;

      final updatePhone = () async {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .update({'phone': phone});
      };

      final updateName = () async {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .update({'fullName': name});
      };

      if (email != user.email) {
        try {
          // Gửi email xác nhận thay đổi email
          await user.verifyBeforeUpdateEmail(email);
          showSnackBar(
            'Một email xác nhận đã được gửi đến $email. Vui lòng xác nhận để hoàn tất cập nhật.',
          );

          // Cập nhật phone trước, email sẽ cập nhật sau khi user xác nhận email mới
          await updatePhone();

          await updateName();

          // Không update email trong Firestore ngay lúc này
          // Bạn cần update email trong Firestore ở lần reload user tiếp theo

          return;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            // Hiển thị dialog yêu cầu user đăng nhập lại
            final reauthPassword = await showDialog<String>(
              context: navigatorKey.currentContext!,
              builder: (context) {
                final passwordController = TextEditingController();
                return AlertDialog(
                  title: const Text('Xác thực lại'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Bạn cần xác thực lại tài khoản để thay đổi email.'),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Mật khẩu'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(passwordController.text),
                      child: const Text('Xác nhận'),
                    ),
                  ],
                );
              },
            );

            if (reauthPassword != null && reauthPassword.isNotEmpty) {
              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: reauthPassword,
                );

                await user.reauthenticateWithCredential(credential);

                // Gửi email xác nhận sau khi xác thực thành công
                await user.verifyBeforeUpdateEmail(email);
                showSnackBar('Email xác nhận đã được gửi đến $email. Vui lòng xác nhận.');

                await updatePhone(); // Cập nhật phone
                return;
              } on FirebaseAuthException catch (e) {
                showSnackBar('Xác thực lại thất bại: ${e.message}');
                return;
              }
            } else {
              showSnackBar('Đã hủy xác thực lại. Không thể cập nhật email.');
              return;
            }
          } else {
            showSnackBar('Không thể cập nhật email: ${e.message}');
            return;
          }
        }
      } else {
        // Email không đổi thì cập nhật phone + email Firestore luôn cho đồng bộ
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .update({
          'phone': phone,
          'fullName': name,
          'email': email,
        });
      }

      // Tải lại thông tin để cập nhật UI
      await getAdminInfo(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Lỗi khi cập nhật thông tin: $e');
      showSnackBar('Không thể cập nhật thông tin.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật thông tin.'),backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuSelection(String choice) {
    switch (choice) {
      case 'changePassword':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChangePasswordPage()),
        );        break;
      case 'editProfile':
        showEditDialog(context);
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    final adminId =
        FirebaseAuth.instance.currentUser?.uid; // UID người dùng đăng nhập
    if (adminId != null) {
      Future.microtask(() {
        // Tải ảnh người dùng (nếu có)
        Provider.of<AdminImageProvider>(context, listen: false)
            .loadImageByAdminId(adminId);

        // Lấy thông tin cư dân + apartmentName luôn
        getAdminInfo(adminId);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final avatarProvider = Provider.of<AdminImageProvider>(context);
    String? avatarUrl = avatarProvider.avatarUrl;

    return Container(
      margin: const EdgeInsets.only(left: defaultPadding),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        key: _profileKey, // ✅ Đặt key vào InkWell
        onTap: _showPopupMenu,
        child: Row(
          children: [
            Consumer<AdminImageProvider>(
              builder: (context, imageProvider, _) {
                Widget avatarChild;

                if (imageProvider.avatarUrl != null &&
                    imageProvider.avatarUrl!.isNotEmpty) {
                  avatarChild = Image.network(
                    imageProvider.avatarUrl!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return SvgPicture.asset(
                        'assets/images/default_avatar.svg',
                        width: 14.r,
                        height: 14.r,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                } else {
                  avatarChild = SvgPicture.asset(
                    'assets/images/default_avatar.svg',
                    width: 14.r,
                    height: 14.r,
                    fit: BoxFit.cover,
                  );
                }

                return CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(child: avatarChild),
                );
              },
            ),

            if (!Responsive.isMobile(context))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
                child: Text(
                  adminInfo?.fullName?.isNotEmpty == true ? adminInfo!.fullName :"Chưa rõ tên",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

              ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}