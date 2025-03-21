import 'package:do_an/src/blocs/auth_bloc.dart';
import 'package:do_an/src/resources/dialog/loading_dialog.dart';
import 'package:do_an/src/resources/dialog/msg_dialog.dart';
import 'package:do_an/src/resources/login_page.dart';
import 'package:do_an/src/resources/waiting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  AuthBloc authBloc = AuthBloc();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cccdController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String? _selectedApartment; // Biến lưu trữ căn hộ được chọn
  double _apartmentArea = 0.0; // Biến lưu diện tích căn hộ
  bool isPressed2 =false;
  bool _isLoginPressed =false;

  // Map ánh xạ tên căn hộ với diện tích tương ứng
  final Map<String, double> _apartmentAreas = {
    '101': 42.0,
    '102': 35.5,
    '103': 48.0,
    '104': 39.0,
    '105': 44.5,
    '201': 28.0,
    '202': 32.5,
    '203': 41.0,
    '204': 36.0,
    '205': 47.0,
    '301': 23.5,
    '302': 26.0,
    '303': 31.5,
    '304': 38.0,
    '305': 45.0,
    '401': 20.0,
    '402': 22.5,
    '403': 27.0,
    '404': 33.5,
    '405': 40.0,
  };

  final List<String> _apartments = [
    '101', '102', '103', '104', '105',
    '201', '202', '203', '204', '205',
    '301', '302', '303', '304', '305',
    '401', '402', '403', '404', '405'
  ];

  DateTime _birthDate = DateTime.now(); // Khai báo DateTime mặc định

  @override
  void dispose() {
    authBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap:(){
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible){
                return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: isKeyboardVisible ? 210.h : 20.h),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/ic_signup.png',
                            fit: BoxFit.cover, // Đảm bảo ảnh nền phủ toàn bộ màn hình
                          ),
                        ),
                        Column(
                          children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(20.w, 80.h, 0.w, 1.h),
                                  child: Align( // Căn trái
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Sign up',
                                          style: GoogleFonts.pacifico(
                                            fontSize: 45.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Image.asset("assets/ic_pencil.png"),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 0.w, 0.h),
                                  child: Align( // Căn trái
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Create a new account with simple steps',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung theo chiều dọc
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(35.w, 85.h, 35.w, 1.h),
                                  child: StreamBuilder(
                                    stream: authBloc.nameStream,
                                    builder: (context, snapshot) => TextField(
                                      controller: _nameController,
                                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                                      decoration: InputDecoration(
                                        errorText: snapshot.hasError
                                            ? snapshot.error.toString()
                                            : null,
                                        labelText: 'Name',
                                        prefixIcon: Container(
                                          width: 50.w,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.person),
                                        ),),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(35.w, 5.h, 35.w, 5.h),
                                  child: StreamBuilder(
                                    stream: authBloc.cccdStream,
                                    builder: (context, snapshot) => TextField(
                                      controller: _cccdController,
                                      style: TextStyle(fontSize: 16.sp, color: Colors.black),
                                      decoration: InputDecoration(
                                        errorText: snapshot.hasError
                                            ? snapshot.error.toString()
                                            : null,
                                        labelText: 'CCCD',
                                        prefixIcon: Container(
                                          width: 50.w,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.credit_card),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.fromLTRB(35.w, 5.h, 35.w, 5.h),
                                    child:StreamBuilder(
                                      stream: authBloc.birthDateStream,
                                      builder: (context, snapshot) => TextField(
                                        controller: _birthDateController,
                                        style: TextStyle(fontSize: 18.sp, color: Colors.black),
                                        decoration: InputDecoration(
                                          errorText:
                                          snapshot.hasError ? snapshot.error.toString() : null,
                                          labelText: 'BirthDate',
                                          prefixIcon: Container(
                                            width: 50.w,
                                            alignment: Alignment.center,
                                            child: Icon(Icons.date_range_rounded),
                                          ),),
                                        onTap: _selectDate,
                                        // Mở DatePicker khi người dùng chọn
                                        readOnly:
                                        true, // Để không cho phép nhập trực tiếp vào trường này
                                      ),
                                    )),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(35.w, 5.h, 35.w, 5.h),
                                  child: StreamBuilder(
                                    stream: authBloc.emailStream,
                                    builder: (context, snapshot) => TextField(
                                      controller: _emailController,
                                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                                      decoration: InputDecoration(
                                        errorText: snapshot.hasError
                                            ? snapshot.error.toString()
                                            : null,
                                        labelText: 'Email',
                                        prefixIcon: Container(
                                          width: 50.w,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.mail),
                                        ),),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(35.w, 5.h, 35.w, 5.h),
                                  child: StreamBuilder(
                                    stream: authBloc.phoneStream,
                                    builder: (context, snapshot) => TextField(
                                      controller: _phoneController,
                                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                                      decoration: InputDecoration(
                                        errorText:
                                        snapshot.hasError ? snapshot.error.toString() : null,
                                        labelText: 'Phone',
                                        prefixIcon: Container(
                                          width: 50.w,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.phone),
                                        ),),
                                    ),
                                  ),),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(35.w, 5.h, 35.w, 2.h),
                                  child: StreamBuilder(
                                    stream: authBloc.nameHouseStream, // Luồng cho tên căn hộ
                                    builder: (context, snapshot) {
                                      return DropdownButtonFormField<String>(
                                        value: _selectedApartment,
                                        items: _apartments.map((apartment) {
                                          return DropdownMenuItem(
                                            value: apartment,
                                            child: Text(apartment),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedApartment = value;
                                            _apartmentArea = _apartmentAreas[value] ?? 0.0;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Apartment Name',
                                          prefixIcon:
                                          Container(width: 50.w, child: Icon(Icons.home)),
                                          errorText: snapshot.hasError
                                              ? snapshot.error.toString()
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(35.w, 1.h, 35.w, 10.h),
                                  child: StreamBuilder(
                                    stream: authBloc.passStream,
                                    builder: (context, snapshot) => TextField(
                                      controller: _passController,
                                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        errorText: snapshot.hasError
                                            ? snapshot.error.toString()
                                            : null,
                                        labelText: 'Password',
                                        prefixIcon: Container(
                                          width: 50.w,
                                          alignment: Alignment.center,
                                          child: Icon(Icons.lock),
                                        ),),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(40.w, 15.h, 40.w, 20.h),
                                  child: GestureDetector(
                                    onTap: _onSignUpClicked,
                                    onTapDown: (_) =>
                                        setState(() => isPressed2 = true),
                                    // Khi nhấn xuống
                                    onTapUp: (_) =>
                                        setState(() => isPressed2 = false),
                                    // Khi thả ra
                                    onTapCancel: () =>
                                        setState(() => isPressed2 = false),
                                    // Khi hủy nhấn
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 100),
                                      width: double.infinity,
                                      height: 52.h,
                                      transform: isPressed2
                                          ? Matrix4.translationValues(2.w, 2.h, 0)
                                          : Matrix4.identity(),
                                      // Hiệu ứng lún xuống
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30.r),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0D1F41),
                                            Color(0xFF2054B0),
                                            // Màu xanh chính
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: isPressed2
                                            ? [
                                          BoxShadow(
                                            color:
                                            Colors.black.withOpacity(0.2),
                                            // Bóng mờ hơn khi nhấn
                                            offset: Offset(2.w, 2.h),
                                            blurRadius: 3.r,
                                          ),
                                        ]
                                            : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                                0.7), // Bóng đậm phía dưới
                                            offset: Offset(4.w, 4.h),
                                            blurRadius: 5.r,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'SIGN UP',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.fromLTRB(30.w, 0.h, 30.w, 40.h),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already a user?',
                                      style:
                                      TextStyle(color: Color(0xff606470), fontSize: 16.sp),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: " Login now",
                                          style: TextStyle(
                                            color: Colors.blue.withOpacity(_isLoginPressed ? 0.6 : 1.0),
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTapDown = (_) {
                                              setState(() {
                                                _isLoginPressed = true;
                                              });
                                            }
                                            ..onTapUp = (_) {
                                              setState(() {
                                                _isLoginPressed = false;
                                              });

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => LoginPage()),
                                              );
                                            }
                                            ..onTapCancel = () {
                                              setState(() {
                                                _isLoginPressed = false;
                                              });
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // SizedBox(height: 200,),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                );
              }),
        ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: _birthDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        ) ??
        _birthDate;

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
        // Chuyển đổi DateTime thành chuỗi theo định dạng yyyy-MM-dd
        _birthDateController.text = "${_birthDate.toLocal()}".split(' ')[0];
      });
    }
  }

    _onSignUpClicked() {
  // Chuyển đổi chuỗi ngày sinh từ _birthDateController.text thành DateTime
  DateTime? birthDate = _birthDateController.text.isNotEmpty
      ? DateTime.tryParse(_birthDateController.text)
      : null;

  var isValid = authBloc.isValid(
    _nameController.text,
    _cccdController.text,
    birthDate, // Truyền DateTime vào
    _emailController.text,
    _phoneController.text,
    _selectedApartment,
    _passController.text,
    _apartmentArea,
  );

  if (isValid) {
    // loading dialog
    LoadingDialog.showLoadingDialog(context, 'Loading...');

    // create user
    authBloc.signUp(
      email: _emailController.text,
      pass: _passController.text,
      phone: _phoneController.text,
      name: _nameController.text,
      birthDate: birthDate,
      nameHouse: _selectedApartment ?? '',
      cccd: _cccdController.text,
      // Truyền DateTime trực tiếp
      apartmentArea: _apartmentArea,
      onSuccess: () {
        LoadingDialog.hideLoadingDialog(context);
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WaitingForApprovalPage()));
      },
      onRegisterError: (msg) {
        LoadingDialog.hideLoadingDialog(context);
        MsgDialog.showMsgDialog(context, "Registration Error", msg);
      },
    );
  }
}
}
