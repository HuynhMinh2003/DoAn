// import 'package:do_an/src/models/apartment.dart';
// import 'package:do_an/src/models/contract_data.dart';
// import 'package:do_an/src/resources/resident_info_page.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:intl/intl.dart';
//
// class ContractInfoPage extends StatefulWidget {
//   final Apartment apartmentData;
//   final String contractType;
//   final String apartmentId;
//
//   ContractInfoPage({required this.apartmentData, required this.contractType, required this.apartmentId});
//
//
//   @override
//   _ContractInfoPageState createState() => _ContractInfoPageState();
// }
//
// class _ContractInfoPageState extends State<ContractInfoPage> {
//   int selectedPeople = 1;
//   DateTime? endDate;
//
//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final formattedDate = DateFormat('dd/MM/yyyy').format(now);
//
//     final area = widget.apartmentData.area;
//
//     final rentPrice = widget.apartmentData.rentPrice;
//     final formattedrentPrice = NumberFormat.currency(
//       locale: 'vi_VN',
//       symbol: '', // nếu muốn bỏ ký hiệu "₫"
//       decimalDigits: 0,
//     ).format(rentPrice);
//
//     final salePrice = widget.apartmentData.salePrice;
//     final formattedsalePrice = NumberFormat.currency(
//       locale: 'vi_VN',
//       symbol: '', // nếu muốn bỏ ký hiệu "₫"
//       decimalDigits: 0,
//     ).format(salePrice);
//
//     return Scaffold(
//       backgroundColor: Color(0xFFF7FEFF),
//       body: SafeArea(child: Stack(
//         children: [
//           SingleChildScrollView(
//             child: Padding(
//               padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 150.h),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start, // 👈 THÊM DÒNG NÀY
//                 children: [
//                   Expanded(
//                     child:
//                     Padding(
//                       padding: EdgeInsets.only(right: 10.w, top: 80.h),
//                       child: SvgPicture.asset(
//                         'assets/images/info_contract.svg',
//                         width: 70.w,
//                       ),
//                     ),
//                   ),
//                   Expanded(child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Center(child: Text('Thông tin hợp đồng', style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.w700, fontSize: 12.sp),),),
//                       SizedBox(height: 40.h),
//                       Text("Căn hộ: ${widget.apartmentData.apartmentName} ", style: TextStyle(fontSize: 5.sp),),
//                       SizedBox(height: 30.h),
//                       Text("Diện tích: $area m²", style: TextStyle(fontSize: 5.sp),),
//                       SizedBox(height: 30.h),
//                       Text("Loại hợp đồng: ${widget.contractType}", style: TextStyle(fontSize: 5.sp),),
//                       SizedBox(height: 30.h),
//                       Row(children: [Text("Số người ở: ", style: TextStyle(fontSize: 5.sp),), SizedBox(width: 10.w,),
//                         DropdownButtonHideUnderline(
//                           child: DropdownButton2<int>(
//                             isExpanded: true,
//                             hint: Text(
//                               'Chọn số người',
//                               style: TextStyle(fontSize: 5.sp, color: Colors.grey[600]),
//                             ),
//                             value: selectedPeople,
//                             items: List.generate(10, (index) => index + 1)
//                                 .map((e) => DropdownMenuItem<int>(
//                               value: e,
//                               child: Text('$e người', style: TextStyle(fontSize: 4.5.sp)),
//                             ))
//                                 .toList(),
//                             onChanged: (value) => setState(() => selectedPeople = value!),
//                             buttonStyleData: ButtonStyleData(
//                               height: 40.h,
//                               width: 40.w,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14.r),
//                                 color: Color(0xFFF7FEFF),
//                                 border: Border.all(
//                                   color: Colors.grey, // Màu viền
//                                   width: 0.1.w, // Độ dày viền
//                                 ),
//                               ),
//                               padding: EdgeInsets.symmetric(horizontal: 6.w),
//                             ),
//                             iconStyleData: IconStyleData(
//                               icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
//                               iconSize: 4.5.sp,
//                             ),
//                             dropdownStyleData: DropdownStyleData(
//                               maxHeight: 150.h,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14.r),
//                                 color: Color(0xFFF7FEFF),
//                               ),
//                             ),
//                             menuItemStyleData: MenuItemStyleData(
//                               height: 40.h,
//                               padding: EdgeInsets.symmetric(horizontal: 6.w),
//                             ),
//                           ),
//                         ),
//
//                       ]),
//                       SizedBox(height: 30.h),
//                       Text("Ngày bắt đầu: $formattedDate", style: TextStyle(fontSize: 5.sp),),
//                       SizedBox(height: 30.h),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Ngày hết hợp đồng:",
//                             style: TextStyle(fontSize: 5.sp, fontWeight: FontWeight.w500),
//                           ),
//                           SizedBox(width: 5.w),
//                           widget.contractType == 'thuê' ?
//                             ElevatedButton(
//                               onPressed: () async {
//                                 DateTime? picked = await showDatePicker(
//                                   context: context,
//                                   initialDate: now.add(Duration(days: 30)),
//                                   firstDate: now.add(Duration(days: 30)),
//                                   lastDate: now.add(Duration(days: 365 * 5)),
//                                 );
//                                 if (picked != null) setState(() => endDate = picked);
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFFF7FEFF),
//                                 elevation: 0,
//                                 padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12.r),
//                                   side: BorderSide(color: Colors.grey, width: 0.1.w),
//                                 ),
//                               ),
//                               child: Text(
//                                 endDate == null
//                                     ? "Chọn ngày kết thúc"
//                                     : "${endDate!.toLocal().toString().split(' ')[0]}",
//                                 style: TextStyle(fontSize: 4.5.sp, color: Colors.black87),
//                               ),
//                             ):
//                           Text("∞", style: TextStyle(fontSize: 4.5.sp),)
//                         ],
//                       ),
//                       SizedBox(height: 30.h),
//                       Text("${widget.contractType == 'thuê' ? "Giá thuê: $formattedrentPrice VNĐ /tháng" : "Giá mua: $formattedsalePrice VNĐ"}", style: TextStyle(fontSize: 5.sp),),
//                       SizedBox(height: 60.h),
//                       Row(
//                         children: [
//                           SizedBox(width: 20.w), // Khoảng cách bên trái
//
//                           // Nút "Quay lại"
//                           Expanded(
//                             child: SizedBox(
//                               height: 60.h,
//                               child: OutlinedButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 style: OutlinedButton.styleFrom(
//                                   side: BorderSide(color: Colors.grey),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(30.r),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   "Quay lại",
//                                   style: TextStyle(
//                                     fontFamily: "Oswald",
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 7.sp,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(width: 20.w), // Khoảng cách giữa hai nút
//
//                           // Nút "Tiếp tục"
//                           Expanded(
//                             child: SizedBox(
//                               height: 60.h,
//                               child: ElevatedButton(
//                                 onPressed: () {
//                                   if (widget.contractType == 'thuê' && endDate == null) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(content: Text("Vui lòng chọn ngày kết thúc hợp đồng")),
//                                     );
//                                     return;
//                                   }
//
//                                   final contractData = ContractData(
//                                     apartmentName: widget.apartmentData.apartmentName,
//                                     building: widget.apartmentData.building,
//                                     area: area.toDouble(),
//                                     rentPrice: rentPrice,
//                                     salePrice: salePrice,
//                                     contractType: widget.contractType,
//                                     startDate: now,
//                                     endDate: widget.contractType == 'thuê' ? endDate! : null,
//                                     numberOfResidents: selectedPeople,
//                                     residents: [],
//                                     apartmentDocId: widget.apartmentId,
//                                   );
//
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => ResidentInfoPage(contractData: contractData),
//                                     ),
//                                   );
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF2D80F8),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(30.r),
//                                   ),
//                                   elevation: 4,
//                                   shadowColor: Colors.black45,
//                                 ),
//                                 child: Text(
//                                   "Tiếp tục",
//                                   style: TextStyle(
//                                     fontFamily: "Oswald",
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 7.sp,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           SizedBox(width: 20.w), // Khoảng cách bên phải
//                         ],
//                       )
//                     ],
//                   ),)
//                 ],
//               )
//
//             ),
//           )
//         ],
//       )),
//     );
//   }
// }
//
