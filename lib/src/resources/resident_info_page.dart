import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/main.dart';
import 'package:do_an/src/resources/base_resident_info.dart';
import 'package:do_an/src/resources/provider/resident_image_provider.dart';
import 'package:do_an/src/resources/reset_pass_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'dialog/loading_dialog.dart';

class ResidentInfoPage extends StatefulWidget {
  const ResidentInfoPage({Key? key}) : super(key: key);

  @override
  _ResidentInfoPageState createState() => _ResidentInfoPageState();
}

class _ResidentInfoPageState extends BaseResidentInfoScreen<ResidentInfoPage> {
  double xPosition = 20;
  double yPosition = 600;

  @override
  void initState() {
    super.initState();

    final residentId =
        FirebaseAuth.instance.currentUser?.uid; // UID người dùng đăng nhập
    if (residentId != null) {
      Future.microtask(() {
        // Tải ảnh người dùng (nếu có)
        Provider.of<ResidentImageProvider>(context, listen: false)
            .loadImageByResidentId(residentId);

        // Lấy thông tin cư dân + apartmentName luôn
        getResidentInfo(residentId);
      });
    }
  }

  Future<void> updateResidentInfo(String phone, String email) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (uid == null || user == null) return;

      final updatePhone = () async {
        await FirebaseFirestore.instance
            .collection('residents')
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
            .collection('residents')
            .doc(uid)
            .update({
          'phone': phone,
          'email': email,
        });
      }

      // Tải lại thông tin để cập nhật UI
      await getResidentInfo(uid);
      showSnackBar('Cập nhật thông tin thành công');
    } catch (e) {
      print('❌ Lỗi khi cập nhật thông tin: $e');
      showSnackBar('Không thể cập nhật thông tin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = Provider.of<ResidentImageProvider>(context);
    String? avatarUrl = avatarProvider.avatarUrl;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Center(
              child: Text(
                'Thông tin cá nhân',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Oswald",
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : residentInfo == null
                  ? const Center(child: Text("Không có thông tin cư dân."))
                  : Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(top: 20.h),
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 20.w, right: 10.w, top: 10.h),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Consumer<ResidentImageProvider>(
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
                                      EdgeInsets.only(left: 20.w, right: 10.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                        height: 10.h,
                                        indent: 0.w,
                                        endIndent: 20.w,
                                      ),
                                      Text(
                                        'Thông tin căn hộ',
                                        style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.sp),
                                      ),
                                      InfoRow(
                                          title: "Căn hộ",
                                          value:
                                              apartmentName ?? "Đang tải..."),
                                      InfoRow(
                                          title: "Diện tích",
                                          value: area != null
                                              ? "$area m²"
                                              : "Đang tải..."),
                                      InfoRow(
                                          title: "Tòa",
                                          value: building ?? "Đang tải..."),
                                      Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                        height: 10.h,
                                        indent: 0.w,
                                        endIndent: 20.w,
                                      ),
                                      Text(
                                        'Thông tin cá nhân',
                                        style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20.sp),
                                      ),
                                      InfoRow(
                                          title: "Họ và tên",
                                          value: residentInfo?.fullName ?? ""),
                                      InfoRow(
                                          title: "Giới tính",
                                          value: residentInfo?.gender ?? ""),
                                      InfoRow(
                                          title: "Địa chỉ",
                                          value: residentInfo?.address ?? ""),
                                      InfoRow(
                                          title: "Số CCCD",
                                          value: residentInfo?.cccd ?? ""),
                                      InfoRow(
                                        title: "Ngày sinh",
                                        value: residentInfo?.birthDate != null
                                            ? DateFormat('dd/MM/yyyy').format(
                                                residentInfo!.birthDate!)
                                            : "Chưa có",
                                      ),
                                      InfoRow(
                                          title: "Số điện thoại",
                                          value: residentInfo?.phone ?? ""),
                                      InfoRow(
                                          title: "Email",
                                          value: residentInfo?.email ?? ""),
                                      InfoRow(
                                        title: "Ngày tạo hồ sơ",
                                        value: residentInfo?.createdAt != null
                                            ? DateFormat('dd/MM/yyyy – HH:mm')
                                                .format(
                                                    residentInfo!.createdAt!)
                                            : "Không rõ",
                                      ),
                                      Divider(
                                        color: Colors.grey,
                                        thickness: 1,
                                        height: 10.h,
                                        indent: 0.w,
                                        endIndent: 20.w,
                                      ),
                                      SizedBox(
                                        height: 10.h,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        ChangePasswordPage()),
                                              );
                                            },
                                            child: Text(
                                              "Đổi mật khẩu",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15.sp),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              showEditDialog(context);
                                            },
                                            child: Text(
                                              "Sửa thông tin",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15.sp),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 4.w,
                                          ),
                                        ],
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
        TextEditingController(text: residentInfo?.phone ?? '');
    final emailController =
        TextEditingController(text: residentInfo?.email ?? '');
    final bloc = EditResidentBloc();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<ResidentImageProvider>(
          builder: (context, imageProvider, _) {
            return AlertDialog(
              title: Center(
                  child: Text('Chỉnh sửa thông tin',
                      style: TextStyle(
                          fontFamily: "Osward",
                          fontSize: 20.sp,
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
                              : (residentInfo?.imageUrl?.isNotEmpty ?? false)
                              ? Image.network(
                            residentInfo!.imageUrl!,
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
                          style: TextStyle(fontSize: 15.sp)),
                      onPressed: () async => await imageProvider.pickImage(),
                    ),
                    const SizedBox(height: 15),

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

                    const SizedBox(height: 15),

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
                          residentInfo!.residentId!,
                          uniqueFileName,
                          oldImageUrl: residentInfo!.imageUrl,
                        );

                        if (newUrl != null) {
                          await FirebaseFirestore.instance
                              .collection('residents')
                              .doc(residentInfo!.residentId!)
                              .update({'imageUrl': newUrl});
                        }
                      }

                      await updateResidentInfo(phoneController.text, emailController.text);

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
                  child: Text('Lưu', style: TextStyle(fontSize: 15.sp,color: Colors.white)),
                ),

              ],
            );
          },
        );
      },
    );
  }
}

class EditResidentBloc {
  final _phoneController = StreamController<String>.broadcast();
  final _emailController = StreamController<String>.broadcast();

  Stream<String?> get phoneStream => _phoneController.stream.map(validatePhone);

  Stream<String?> get emailStream => _emailController.stream.map(validateEmail);

  Function(String) get changePhone => _phoneController.sink.add;

  Function(String) get changeEmail => _emailController.sink.add;

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

  void dispose() {
    _phoneController.close();
    _emailController.close();
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const InfoRow({
    Key? key,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h), // Khoảng cách giữa các dòng
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
