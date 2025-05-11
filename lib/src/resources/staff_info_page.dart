// import 'package:do_an/base_staff_info.dart';
// import 'package:do_an/src/resources/provider/staff_image_provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// class StaffInfoPage extends StatefulWidget {
//   const StaffInfoPage({Key? key}) : super(key: key);
//
//   @override
//   _StaffInfoPageState createState() => _StaffInfoPageState();
// }
//
// class _StaffInfoPageState extends BaseStaffInfoScreen<StaffInfoPage> {
//   @override
//   void initState() {
//     super.initState();
//
//     final staffId = FirebaseAuth.instance.currentUser?.uid;  // Lấy UID người dùng đã đăng nhập
//     if (staffId != null) {
//       Future.microtask(() {
//         // Tải ảnh của người dùng
//         Provider.of<UserImageProvider>(context, listen: false).loadImageByStaffId(staffId);
//         // Lấy thông tin nhân viên từ Firestore
//         getStaffInfo(staffId);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final avatarProvider = Provider.of<UserImageProvider>(context);
//     String? avatarUrl = avatarProvider.avatarUrl;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Center(child: Text('Thông tin cá nhân',style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),),
//         backgroundColor: Colors.blue,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : staffInfo == null
//           ? const Center(child: Text("Không có thông tin nhân viên."))
//           : Align(
//         alignment: Alignment.topCenter,
//         child: SingleChildScrollView(
//           physics: const NeverScrollableScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.only(top: 50.0),
//             child:
//             SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: 70,
//                     backgroundImage: avatarUrl != null
//                         ? NetworkImage(avatarUrl)
//                         : null, // backgroundImage phải là một ImageProvider, không phải là icon
//                     child: avatarUrl == null
//                         ? const Icon(Icons.person, size: 50) // Hiển thị icon khi không có avatar
//                         : null, // Nếu có ảnh thì không cần icon
//                   ),
//
//                   const SizedBox(height: 30),
//                   Text("Họ và tên: ${staffInfo?["name"]}", style: TextStyle(fontSize: 15)),
//                   Text("Số điện thoại: ${staffInfo?["phone"]}", style: TextStyle(fontSize: 15)),
//                   Text("Chức vụ: ${staffInfo?["position"]}", style: TextStyle(fontSize: 15)),
//
//                 ],
//               ),
//             )
//
//           ),
//         ),
//       ),
//     );
//   }
// }
