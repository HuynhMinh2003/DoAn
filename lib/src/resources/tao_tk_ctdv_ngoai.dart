import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/provider/company_image_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class AddAccountCompanyPage extends StatefulWidget {
  const AddAccountCompanyPage({super.key});

  @override
  State<AddAccountCompanyPage> createState() => _AddAccountCompanyPageState();
}

class _AddAccountCompanyPageState extends State<AddAccountCompanyPage> {
  final TextEditingController _nameCompanyController = TextEditingController();
  final TextEditingController _emailCompanyController = TextEditingController();
  final TextEditingController _phoneCompanyController = TextEditingController();
  final TextEditingController _typeCompanyController = TextEditingController();
  final TextEditingController _addressCompanyController = TextEditingController();
  final TextEditingController _describeCompanyController = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    // Kiểm tra xem widget có còn mounted không trước khi gọi resetImage
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final avatarProvider = Provider.of<CompanyImageProvider>(context,listen: false);
        avatarProvider.resetImage();
      });
    }
  }

  @override
  void dispose() {
    _nameCompanyController.dispose();
    _emailCompanyController.dispose();
    _phoneCompanyController.dispose();
    _typeCompanyController.dispose();
    _addressCompanyController.dispose();
    _describeCompanyController.dispose();
    _authBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FEFF),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 50.w, right: 50.w, top: 40.h),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20.h,
                        ),
                        Text(
                          'Tài khoản mới cho dịch vụ ngoài',
                          style: TextStyle(
                            fontFamily: "Oswald",
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(
                          height: 30.h,
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 25.w,),
                          // Bên trái: ảnh
                          Center(
                            child: Consumer<CompanyImageProvider>(
                              builder: (context, avatarProvider, child) {
                                String? avatarUrl = avatarProvider.avatarUrl;
                                bool hasImage = avatarUrl != null ||
                                    avatarProvider.selectedImageFile != null ||
                                    avatarProvider.webImageBytes != null;

                                Widget _buildAvatarImage() {
                                  if (avatarProvider.webImageBytes != null) {
                                    return Image.memory(
                                      avatarProvider.webImageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    );
                                  } else if (avatarProvider.selectedImageFile != null) {
                                    return Image.file(
                                      avatarProvider.selectedImageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    );
                                  } else if (avatarUrl != null) {
                                    return Image.network(
                                      '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.error, color: Colors.red)),
                                    );
                                  } else {
                                    return Icon(Icons.add_a_photo, size: 20.sp, color: Colors.grey);
                                  }
                                }

                                double avatarSize = min(300.w, 300.h);

                                return SizedBox(
                                  width: avatarSize, // ➔ Chiều ngang avatar
                                  height: avatarSize + 40.h, // ➔ Chiều cao avatar + label
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: avatarSize,
                                        height: avatarSize,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.grey.shade300, width: 0.5.w),
                                          borderRadius: BorderRadius.circular(12.r), // Bo góc (điều chỉnh bán kính)
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              final provider = Provider.of<CompanyImageProvider>(context, listen: false);
                                              await provider.pickImage();
                                              await Future.delayed(const Duration(milliseconds: 300));

                                              if (kIsWeb) {
                                                print("🧾 Ảnh web đã chọn: ${provider.webImageBytes != null ? "Đã có dữ liệu bytes" : "null"}");
                                              } else {
                                                print("🧾 Ảnh file đã chọn: ${provider.selectedImageFile?.path ?? "null"}");
                                              }

                                              if (provider.selectedImageFile == null &&
                                                  provider.webImageBytes == null &&
                                                  avatarUrl == null) {
                                                MsgDialog.showMsgDialog(context, "Lỗi", "Chưa chọn ảnh hoặc không tải được ảnh ");
                                              }
                                            },
                                            splashColor: Colors.grey.withOpacity(0.1),
                                            highlightColor: Colors.transparent,
                                            borderRadius: BorderRadius.circular(12.r), // Bo góc cho hiệu ứng splash
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12.r), // Bo góc cho hình ảnh
                                              child: AnimatedSwitcher(
                                                duration: const Duration(milliseconds: 300),
                                                child: _buildAvatarImage(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),                                      Positioned(
                                        bottom: 0,
                                        child: Container(
                                          margin: EdgeInsets.only(top: 8.h),
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Text(
                                            hasImage ? 'Thay đổi' : 'Thêm ảnh',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 4.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 60.w,),
                          // Bên phải: form login
                          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [ _buildTextField(
                            controller: _nameCompanyController,
                            label: 'Tên công ty:',
                            stream: _authBloc.nameCompanyStream,
                          ),
                            _buildTextField(
                              controller: _emailCompanyController,
                              label: 'Email:',
                              stream: _authBloc.emailCompanyStream,
                            ),
                            _buildTextField(
                              controller: _addressCompanyController,
                              label: 'Địa chỉ:',
                              stream: _authBloc.addressCompanyStream,
                            ),
                            _buildTextField(
                              controller: _phoneCompanyController,
                              label: 'Số điện thoại:',
                              stream: _authBloc.phoneCompanyStream,
                            ),
                            _buildTextField(
                              controller: _typeCompanyController,
                              label: 'Loại dịch vụ:',
                              stream: _authBloc.typeCompanyStream,
                            ),
                            _buildTextField(
                              controller: _describeCompanyController,
                              label: 'Mô tả:',
                              stream: _authBloc.describeCompanyStream,
                            ),],)),

                        ],),
                        SizedBox(
                          height: 40.h,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Phân bố nút cách đều
                          children:[
                          SizedBox(width: 10.w), // Tùy chọn nếu bạn muốn có khoảng cách giữa các nút
                          Expanded(
                              child: SizedBox(
                                height: 60.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _onSignUpCompanyClicked();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF2D80F8),
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
                                    "Tạo tài khoản",
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 7.sp,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Khoảng cách giữa 2 nút
                            Expanded(
                              child: SizedBox(
                                height: 60.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _nameCompanyController.clear();
                                    _emailCompanyController.clear();
                                    _phoneCompanyController.clear();
                                    _typeCompanyController.clear();
                                    _addressCompanyController.clear();
                                    _describeCompanyController.clear();

                                    // Reset ảnh
                                    final avatarProvider = Provider.of<CompanyImageProvider>(context, listen: false);
                                    avatarProvider.resetImage();  // Reset ảnh

                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF2D80F8),
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
                                    "Hủy",
                                    style: TextStyle(
                                      fontFamily: "Oswald",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 7.sp,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onSignUpCompanyClicked() async {
    var isValidCompany = _authBloc.isValidCompanySignUp(
      _nameCompanyController.text,
      _emailCompanyController.text,
      _phoneCompanyController.text,
      _typeCompanyController.text,
      _addressCompanyController.text,
      _describeCompanyController.text,
    );

    if (!isValidCompany) return;

    final imageProvider = Provider.of<CompanyImageProvider>(context, listen: false);
    final hasImage = (kIsWeb && imageProvider.webImageBytes != null) ||
        (!kIsWeb && imageProvider.selectedImageFile != null);

    if (!hasImage) {
      MsgDialog.showMsgDialog(context, "Lỗi", "Bạn chưa chọn ảnh. Vui lòng chọn lại");
      return;
    }

    LoadingDialog.showLoadingDialog(context, 'Đang tải ...');

    try {
      final url = Uri.parse("https://createcompanyaccount-ttrkrlo35a-uc.a.run.app");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameCompanyController.text.trim(),
          'email': _emailCompanyController.text.trim(),
          'phone': _phoneCompanyController.text.trim(),
          'type': _typeCompanyController.text.trim(),
          'address': _addressCompanyController.text.trim(),
          'description': _describeCompanyController.text.trim(),
        }),
      );

      if (response.statusCode != 200) {
        LoadingDialog.hideLoadingDialog(context);
        MsgDialog.showMsgDialog(context, "Thất bại", "Không thể tạo tài khoản: ${response.body}");
        return;
      }

      // 2. Nếu thành công → lấy `uid` từ phản hồi
      final responseBody = jsonDecode(response.body);
      final userId = responseBody['uid']; // Lấy uid từ phản hồi
      final uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_avatar.jpg";

      final imageUrl = await imageProvider.uploadSelectedImageAndGetUrl(userId, uniqueFileName);

      _imageUrl = imageUrl;

      // 3. Cập nhật Firestore với imageUrl nếu cần
      await FirebaseFirestore.instance.collection("companies").doc(userId).set({
        "imageUrl": imageUrl,
        "email": _emailCompanyController.text.trim(),
        "name": _nameCompanyController.text.trim(),
        "phone": _phoneCompanyController.text.trim(),
        "type": _typeCompanyController.text.trim(),
        "address": _addressCompanyController.text.trim(),
        "description": _describeCompanyController.text.trim(),
      }, SetOptions(merge: true));

      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, "Thành công", "Tạo tài khoản công ty thành công.");
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, "Lỗi", "Không thể tạo tài khoản: $e");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: StreamBuilder<String>(
        stream: stream,
        builder: (context, snapshot) {
          return TextField(
            controller: controller,
            style: TextStyle(fontSize: 4.sp, color: Colors.black),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                  fontSize: 4.sp
              ),
              errorText: snapshot.hasError ? snapshot.error as String : null,
              contentPadding:
              EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xffCED0D2), width: 1.w),
                borderRadius: BorderRadius.all(Radius.circular(30.r)),
              ),
            ),
          );
        },
      ),
    );
  }
}
