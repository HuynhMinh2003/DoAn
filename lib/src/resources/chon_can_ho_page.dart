import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApartmentFilterPage extends StatefulWidget {
  const ApartmentFilterPage({super.key});

  @override
  State<ApartmentFilterPage> createState() => _ApartmentFilterPageState();
}

class _ApartmentFilterPageState extends State<ApartmentFilterPage> {
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
                padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 170.h),
                child: Column(
                  children: [
                    const Text(
                      'Chọn căn hộ',
                      style: TextStyle(
                        fontFamily: "Oswald",
                        fontWeight: FontWeight.w700,
                        fontSize: 50,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left panel (filters)
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SearchBar(),
                                  SizedBox(height: 20.h),
                                  const FilterDropdown(label: 'Tòa nhà:'),
                                  const FilterDropdown(label: 'Diện tích:'),
                                  const FilterDropdown(label: 'Trạng thái:'),
                                ],
                              ),
                            ),
                            SizedBox(width: 24.w),

                            // Right panel (empty box)
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Container(
                                    height: 330.h,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 10.r,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 40.h),

                        Center(
                          child:
                          SizedBox(
                            width: 100.w,
                            height: 60.h,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D80F8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black45,
                                padding: EdgeInsets.zero, // 👈 bỏ padding mặc định để dễ canh giữa
                              ),
                              child: Center(
                                child: Text(
                                  "Quay lại",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "Oswald",
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9.sp,
                                    color: Colors.white,
                                    height: 1.2, // 👈 thêm để tránh mất nét
                                  ),
                                ),
                              ),
                            ),
                          ),

                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout cho Desktop
  // Widget _buildLandScapeLayout(BuildContext context){
  //   return
  //     Column(
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
  //       _buildTextField('Tòa nhà:'),
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

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.search, size: 10.sp),
        SizedBox(width: 3.w),
        Text(
          'Tìm kiếm:',
          style: TextStyle(
            fontFamily: "Oswald",
            fontWeight: FontWeight.w700,
            fontSize: 8.sp ,
          ),
        ),
        SizedBox(width: 18.w ),
        Expanded(
          child: Container(
            height: 30.h,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black26),
              ),
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(
                fontSize: 8.sp,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                // có thể trigger search logic hoặc UI cập nhật ở đây
              },
            ),
          ),
        ),
      ],
    );
  }
}

class FilterDropdown extends StatefulWidget {
  final String label;
  const FilterDropdown({super.key, required this.label});

  @override
  State<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 50.h), //  padding thay đổi theo màn hình
      child: Row(
        children: [
          SizedBox(
            width: 50.w,
            child: Text(
              widget.label,
              style:  TextStyle(
                fontFamily: "Oswald",
                fontWeight: FontWeight.w700,
                fontSize: 8.sp,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: SizedBox(
              height: 40.h,
              child: Container(
                padding: EdgeInsets.only(left: 12.w),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Text(
                      'Chọn một mục',
                      style: TextStyle(fontSize: 5.sp),
                    ),
                    items: ['Option 1', 'Option 2']
                        .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(fontSize: 5.sp),
                      ),
                    ))
                        .toList(),
                    value: selectedValue,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.black12),
                        color: Colors.white,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200.h,
                      width: 92.w,
                      padding: null,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: Colors.white,
                      ),
                      elevation: 4,
                    ),
                    menuItemStyleData: MenuItemStyleData(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

