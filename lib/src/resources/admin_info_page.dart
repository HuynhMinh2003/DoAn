import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/constants.dart';
import 'package:do_an/main.dart';
import 'package:do_an/src/resources/base_admin_screen_page.dart';
import 'package:do_an/src/resources/provider/admin_image_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import 'dialog/loading_dialog.dart';

class AdminInfoPage extends StatefulWidget {
  const AdminInfoPage({Key? key}) : super(key: key);

  @override
  _AdminInfoPageState createState() => _AdminInfoPageState();
}

class _AdminInfoPageState extends BaseAdminInfoScreen<AdminInfoPage> {
  double xPosition = 20;
  double yPosition = 600;

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

  Future<void> updateAdminInfo(String phone, String email) async {
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

      if (email != user.email) {
        try {
          // Gửi email xác nhận thay đổi email
          await user.verifyBeforeUpdateEmail(email);
          showSnackBar(
            'Một email xác nhận đã được gửi đến $email. Vui lòng xác nhận để hoàn tất cập nhật.',
          );

          // Cập nhật phone trước, email sẽ cập nhật sau khi user xác nhận email mới
          await updatePhone();

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

  @override
  Widget build(BuildContext context) {
    final avatarProvider = Provider.of<AdminImageProvider>(context);
    String? avatarUrl = avatarProvider.avatarUrl;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text('      Thông tin cá nhân', style: TextStyle(fontSize: 8.sp, fontFamily: "Oswald", fontWeight: FontWeight.bold),),backgroundColor: bgColor,),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminInfo == null
              ? const Center(child: Text("Không có thông tin quản lý."))
              : Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 20.w, right: 10.w, top: 10.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<AdminImageProvider>(
                        builder: (context, imageProvider, _) {
                          Widget avatarChild;

                          if (imageProvider.avatarUrl != null &&
                              imageProvider.avatarUrl!.isNotEmpty) {
                            avatarChild = Image.network(
                              imageProvider.avatarUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return SvgPicture.asset(
                                  'assets/images/default_avatar.svg',
                                  width: 60.r,
                                  height: 60.r,
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          } else {
                            avatarChild = SvgPicture.asset(
                              'assets/images/default_avatar.svg',
                              width: 60.r,
                              height: 60.r,
                              fit: BoxFit.cover,
                            );
                          }

                          return CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            child: ClipOval(child: avatarChild),
                          );
                        },
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding:
                        EdgeInsets.only(left: 20.w, right: 20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                              'Thông tin cá nhân',
                              style: TextStyle(
                                  fontFamily: "Oswald",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 6.sp),
                            ),),
                            SizedBox(height: 20.h,),
                            Align(
                              alignment: Alignment.center,
                              child:
                              Column(
                                children: [
                                  InfoRow(
                                    title: "Họ và tên",
                                    value: adminInfo?.fullName ?? "",
                                    titleColor: Colors.white,),
                                  InfoRow(
                                      title: "Số điện thoại",
                                      value: adminInfo?.phone ?? "",
                                      titleColor: Colors.white),
                                  InfoRow(
                                      title: "Email",
                                      value: adminInfo?.email ?? "",
                                      titleColor: Colors.white),
                                ],
                              ),),
                            SizedBox(height: 40.h,),
                            SizedBox(height: 60.h,width: 60.w,
                            child:
                            ElevatedButton(
                              onPressed: () {
                                showEditDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                secondaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(30.r),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black45,
                                alignment: Alignment.center,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                "Sửa thông tin",
                                style: TextStyle(
                                  color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 4.sp),
                              ),
                            ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showEditDialog(BuildContext context) {
    final phoneController =
    TextEditingController(text: adminInfo?.phone ?? '');
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

                    if (phoneError != null || emailError != null) {
                      bloc.changePhone(phoneController.text);
                      bloc.changeEmail(emailController.text);
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

                      await updateAdminInfo(phoneController.text, emailController.text);

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
}

class EditAdminBloc {
  final _phoneController = StreamController<String>.broadcast();
  final _nameController = StreamController<String>.broadcast();
  final _emailController = StreamController<String>.broadcast();

  Stream<String?> get phoneStream => _phoneController.stream.map(validatePhone);

  Stream<String?> get nameStream => _nameController.stream.map(validateName);

  Stream<String?> get emailStream => _emailController.stream.map(validateEmail);

  Function(String) get changePhone => _phoneController.sink.add;

  Function(String) get changeEmail => _emailController.sink.add;

  Function(String) get changeName => _nameController.sink.add;

  String? validatePhone(String value) {
    if (value.isEmpty) return 'Không được để trống';
    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? validateEmail(String value) {
    if (value.isEmpty) return 'Không được để trống';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? validateName(String value) {
    if (value.isEmpty) return 'Không được để trống';
    return null;
  }

  void dispose() {
    _phoneController.close();
    _emailController.close();
    _nameController.close();
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;

  const InfoRow({
    Key? key,
    required this.title,
    required this.value,
    this.titleColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120.w, // hoặc dùng .w nếu dùng flutter_screenutil
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: titleColor,
                fontSize: 5.sp
              ),
            ),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: 160.w,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                  fontSize: 5.sp
              ),
            ),
          ),
        ],
      ),
    );
  }
}
