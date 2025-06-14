import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/main.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';
import '../../../responsive.dart';
import '../../../src/resources/admin_info_page.dart';
import '../../../src/resources/base_admin_screen_page.dart';
import '../../../src/resources/dialog/loading_dialog.dart';
import '../../../src/resources/login_page.dart';
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
            style: TextStyle(fontSize: 7.sp,fontWeight: FontWeight.bold, fontFamily: "Oswald")
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
          value: 'editProfile',
          child: Text("Chỉnh sửa thông tin"),
        ),
        PopupMenuItem(
          value: 'changePassword',
          child: Text("Đổi mật khẩu"),
        ),
        PopupMenuItem(
          value: 'logOut',
          child: Text("Đăng xuất"),
        ),
      ],
    );

    if (selected != null) {
      _handleMenuSelection(selected);
    }
  }

  void showEditDialog(BuildContext context) {
    final phoneController = TextEditingController(text: adminInfo?.phone ?? '');
    final nameController = TextEditingController(text: adminInfo?.fullName ?? '');
    final emailController = TextEditingController(text: adminInfo?.email ?? '');
    final bloc = EditAdminBloc();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<AdminImageProvider>(
          builder: (context, imageProvider, _) {
            return AlertDialog(
              title: Center(
                child: Text(
                  'Chỉnh sửa thông tin',
                  style: TextStyle(
                    fontFamily: "Oswald",
                    fontSize: 6.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ảnh đại diện có thể bấm vào + icon camera
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () async => await imageProvider.pickImage(),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: imageProvider.webImageBytes != null
                                ? MemoryImage(imageProvider.webImageBytes!)
                                : imageProvider.selectedImageFile != null
                                ? FileImage(imageProvider.selectedImageFile!)
                                : (adminInfo?.imageUrl?.isNotEmpty ?? false)
                                ? NetworkImage(adminInfo!.imageUrl!)
                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: -3,
                          right: 2,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.blueAccent, size: 22),
                            onPressed: () async => await imageProvider.pickImage(),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.h),

                    // TextField - Họ và tên
                    StreamBuilder<String?>(
                      stream: bloc.nameStream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          onChanged: bloc.changeName,
                        );
                      },
                    ),

                    SizedBox(height: 4.h),

                    // TextField - Email
                    StreamBuilder<String?>(
                      stream: bloc.emailStream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: bloc.changeEmail,
                        );
                      },
                    ),

                    SizedBox(height: 4.h),

                    // TextField - Số điện thoại
                    StreamBuilder<String?>(
                      stream: bloc.phoneStream,
                      builder: (context, snapshot) {
                        return TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            labelStyle: TextStyle(fontSize: 4.sp),
                            errorText: snapshot.data,
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: bloc.changePhone,
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
                  child: Text(
                    'Hủy',
                    style: TextStyle(fontSize: 4.sp, color: Colors.white),
                  ),
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
                      LoadingDialog.showLoadingDialog(context, "Đang lưu...");

                      String? newUrl;

                      if (imageProvider.webImageBytes != null ||
                          imageProvider.selectedImageFile != null) {
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

                      await updateAdminInfo(
                        phoneController.text,
                        emailController.text,
                        nameController.text,
                      );

                      bloc.dispose();
                      Navigator.of(context, rootNavigator: true).pop(); // Close loading
                      Navigator.of(context).pop(); // Close dialog
                    } catch (e) {
                      Navigator.of(context, rootNavigator: true).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi khi lưu thông tin: $e")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('Lưu', style: TextStyle(fontSize: 4.sp, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showChangePasswordDialog(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Future<void> handleChangePassword() async {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        final user = _auth.currentUser;

        final oldPass = oldPasswordController.text;
        final newPass = newPasswordController.text;
        final confirmPass = confirmPasswordController.text;

        if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
          Navigator.of(context, rootNavigator: true).pop();
          MsgDialog.showMsgDialog(context, "Lỗi", 'Vui lòng điền đầy đủ thông tin.');
          return;
        }

        if (newPass.length < 6) {
          Navigator.of(context, rootNavigator: true).pop();
          MsgDialog.showMsgDialog(context, "Lỗi", 'Mật khẩu mới phải có ít nhất 6 ký tự.');
          return;
        }

        if (newPass != confirmPass) {
          Navigator.of(context, rootNavigator: true).pop();
          MsgDialog.showMsgDialog(context, "Lỗi", 'Mật khẩu mới và xác nhận không khớp.');
          return;
        }

        if (newPass == oldPass) {
          Navigator.of(context, rootNavigator: true).pop();
          MsgDialog.showMsgDialog(context, "Lỗi", 'Mật khẩu mới không được trùng mật khẩu cũ.');
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: oldPass,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);

        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        Navigator.of(context).pop(); // Close dialog
        MsgDialog.showMsgDialog(context, "Thành công", "Đổi mật khẩu thành công!");
      } on FirebaseAuthException catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        switch (e.code) {
          case 'wrong-password':
            MsgDialog.showMsgDialog(context, "Lỗi", "Mật khẩu cũ không đúng.");
            break;
          case 'weak-password':
            MsgDialog.showMsgDialog(context, "Lỗi", "Mật khẩu mới quá yếu.");
            break;
          case 'requires-recent-login':
            MsgDialog.showMsgDialog(context, "Lỗi", "Bạn cần đăng nhập lại.");
            break;
          case 'too-many-requests':
            MsgDialog.showMsgDialog(context, "Lỗi", "Quá nhiều yêu cầu, thử lại sau.");
            break;
          default:
            MsgDialog.showMsgDialog(context, "Lỗi", "Đổi mật khẩu thất bại.");
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        MsgDialog.showMsgDialog(context, "Lỗi", "Có lỗi xảy ra. Vui lòng thử lại.");
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text('Đổi mật khẩu', style: TextStyle(fontSize: 6.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold)),),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Mật khẩu cũ',labelStyle: TextStyle(fontSize: 4.sp)),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Mật khẩu mới',labelStyle: TextStyle(fontSize: 4.sp)),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Xác nhận mật khẩu mới',labelStyle: TextStyle(fontSize: 4.sp)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy',style: TextStyle(fontSize: 4.sp,color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: handleChangePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Đổi mật khẩu',style: TextStyle(fontSize: 4.sp,color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateAdminInfo(String phone, String email, String name) async {
    LoadingDialog.showLoadingDialog(context, "Đang cập nhật ...");
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Một email xác nhận đã được gửi đến $email. Vui lòng xác nhận để hoàn tất cập nhật.', style: TextStyle(fontSize: 4.sp))),
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
                      Text('Bạn cần xác thực lại tài khoản để thay đổi email.',style: TextStyle(fontSize: 4.sp),),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Mật khẩu',labelStyle: TextStyle(fontSize: 4.sp)),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Hủy',style: TextStyle(fontSize: 4.sp),),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(passwordController.text),
                      child: Text('Xác nhận',style: TextStyle(fontSize: 4.sp)),
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

      LoadingDialog.hideLoadingDialog(context);
      // Tải lại thông tin để cập nhật UI
      await getAdminInfo(uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);
      print('❌ Lỗi khi cập nhật thông tin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật thông tin.'),backgroundColor: Colors.red,
        ),
      );
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
        showChangePasswordDialog(context);
        break;
      case 'editProfile':
        showEditDialog(context);
        break;
      case 'logOut':
        logOut();
        break;
    }
  }

  void logOut() {
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
                  fontSize: 7.sp),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: TextStyle(fontSize: 4.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy', style: TextStyle(fontSize: 4.sp)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _removeFcmToken();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Đồng ý', style: TextStyle(fontSize: 4.sp,color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFcmToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print("⚠️ Không lấy được FCM Token");
        return;
      }

      DocumentReference userRef =
      FirebaseFirestore.instance.collection('admins').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        print("⚠️ User document không tồn tại trong Firestore!");
        return;
      }

      List<String> tokens = List<String>.from(userDoc['fcmTokens'] ?? []);

      if (tokens.contains(fcmToken)) {
        await userRef.update({
          'fcmTokens': FieldValue.arrayRemove([fcmToken]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print("✅ Đã xóa token FCM: $fcmToken");
      } else {
        print("⚠️ Token không tồn tại trong danh sách, không cần xóa.");
      }
    } catch (e) {
      print("❌ Lỗi khi xóa token FCM: $e");
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