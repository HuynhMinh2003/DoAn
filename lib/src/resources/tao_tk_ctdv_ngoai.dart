import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/back_button.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _describeCompanyController = TextEditingController();

  final AuthBloc _authBloc = AuthBloc();

  @override
  void dispose() {
    _nameCompanyController.dispose();
    _emailCompanyController.dispose();
    _phoneCompanyController.dispose();
    _typeCompanyController.dispose();
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
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset('assets/images/two_circle.png', width: 160),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 100.w, right: 100.w, top: 140.h),
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
                        _buildTextField(
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
                        ),
                        SizedBox(
                          height: 40.h,
                        ),
                        Row(
                          children: [
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
            Positioned(
              top: MediaQuery.of(context).size.height/2,
              left: 10.w,
              child: const BackButtonWidget(),
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
      _describeCompanyController.text,
    );

    if (!isValidCompany) return;

    LoadingDialog.showLoadingDialog(context, 'Đang tải ...');

    try {
      final url = Uri.parse("https://createcompanyaccount-ttrkrlo35a-uc.a.run.app");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nameCompany': _nameCompanyController.text.trim(),
          'email': _emailCompanyController.text.trim(),
          'phone': _phoneCompanyController.text.trim(),
          'type': _typeCompanyController.text.trim(),
          'description': _describeCompanyController.text.trim(),
        }),
      );

      LoadingDialog.hideLoadingDialog(context);

      if (response.statusCode == 200) {
        MsgDialog.showMsgDialog(context, "Tạo tài khoản thành công!", "Tài khoản công ty đã được tạo và email đã được gửi.");
      } else {
        MsgDialog.showMsgDialog(context, "Tạo tài khoản thất bại!", response.body);
      }
    } catch (e) {
      LoadingDialog.hideLoadingDialog(context);
      MsgDialog.showMsgDialog(context, "Lỗi hệ thống", "Không thể tạo tài khoản: $e");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Stream<String> stream,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
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

  /// Layout cho Desktop
// Widget _buildLandScapeLayout(BuildContext context){
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Left panel (filters)
//           Expanded(
//             flex: 1,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SearchBar(),
//                 SizedBox(height: 20.h),
//                 const FilterDropdown(label: 'Tòa nhà:'),
//                 const FilterDropdown(label: 'Diện tích:'),
//                 const FilterDropdown(label: 'Trạng thái:'),
//               ],
//             ),
//           ),
//           SizedBox(width: 24.w),
//
//           // Right panel (empty box)
//           Expanded(
//             flex: 1,
//             child: Column(
//               children: [
//                 Container(
//                   height: 330.h,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12.r),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 10.r,
//                         offset: const Offset(2, 2),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//
//       SizedBox(height: 40.h),
//
//       Center(
//         child:
//         SizedBox(
//           width: 100.w,
//           height: 60.h,
//           child: ElevatedButton(
//             onPressed: () {},
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF2D80F8),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30.r),
//               ),
//               elevation: 4,
//               shadowColor: Colors.black45,
//               padding: EdgeInsets.zero, // 👈 bỏ padding mặc định để dễ canh giữa
//             ),
//             child: Center(
//               child: Text(
//                 "Quay lại",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontFamily: "Oswald",
//                   fontWeight: FontWeight.w700,
//                   fontSize: 9.sp,
//                   color: Colors.white,
//                   height: 1.2, // 👈 thêm để tránh mất nét
//                 ),
//               ),
//             ),
//           ),
//         ),
//
//       )
//     ],
//   ) ;
// }

  /// Layout cho Mobile
// Widget _buildPortraitLayout(BuildContext context) {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const SearchBar(),
//       SizedBox(height: 20.h),
//       const FilterDropdown(label: 'Tòa nhà:'),
//       const FilterDropdown(label: 'Diện tích:'),
//       const FilterDropdown(label: 'Trạng thái:'),
//       Container(
//         height: 220.h,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12.r),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10.r,
//               offset: Offset(2.w, 2.h),
//             ),
//           ],
//         ),
//       ),
//       SizedBox(height: 25.h),
//       SizedBox(
//         width: double.infinity,
//         height: 60.h,
//         child: ElevatedButton(
//           onPressed: () {},
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF2D80F8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30.r),
//             ),
//             elevation: 4,
//             shadowColor: Colors.black45,
//           ),
//           child: Text(
//             "Quay lại",
//             style: TextStyle(
//               fontFamily: "Oswald",
//               fontWeight: FontWeight.w700,
//               fontSize: 30.sp,
//               color: Colors.white,
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }
}
