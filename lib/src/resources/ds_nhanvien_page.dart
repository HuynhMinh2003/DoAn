import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  String? _selectedPosition;


  List<String> _positionItems = [];

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  void _fetchPositions() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("positions").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        _positionItems = ["Tất cả"]; // ✅ Thêm "Tất cả" vào đầu
        _positionItems.addAll(data.values.map((e) => e.toString()));
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showStaffDetails(BuildContext context, Map<String, dynamic> staff) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Thông tin cá nhân",
          style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: isLandscape? 5.sp : 20.sp, color: Colors.blueAccent),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (staff["imageUrl"] != null)
                Center(
                  child: CircleAvatar(
                    radius: 70.r,
                    backgroundImage: NetworkImage(staff["imageUrl"]),
                  ),
                ),
              SizedBox(height: 30.h),
              Text("Họ và tên: ${staff["name"]}", style: TextStyle(fontSize: isLandscape? 3.5.sp:15.sp)),
              SizedBox(height: 18.h),
              Text("Email: ${staff["email"]}", style: TextStyle(fontSize: isLandscape? 3.5.sp:15.sp)),
              SizedBox(height: 18.h),
              Text("SĐT: ${staff["phone"]}", style: TextStyle(fontSize: isLandscape? 3.5.sp:15.sp)),
              SizedBox(height: 18.h),
              Text("Vai trò: ${staff["position"]}", style: TextStyle(fontSize: isLandscape? 3.5.sp:15.sp)),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều các nút
            children: [
              TextButton(
                onPressed: staff["isFree"] == 1
                    ? () {
                  // Thực hiện hành động khi nhấn (ví dụ: kích hoạt một hành động nào đó)
                  print("Button nhấn được");
                }
                    : null, // Khi isFree != 1, nút sẽ bị vô hiệu hóa
                child: Text(
                  "Phân việc",
                  style: TextStyle(
                    fontSize: isLandscape? 4.sp : 15.sp,
                    color: staff["isFree"] == 1 ? Colors.blue : Colors.grey, // Thay đổi màu sắc khi vô hiệu hóa
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text("Đóng", style: TextStyle(fontSize: isLandscape? 4.sp : 15.sp)),
              ),
            ],
          )


        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset('assets/images/two_circle.png', width: 160),
              ),
              SingleChildScrollView(
                child: isLandscape ? _buildLandScapeLayout(context) : _buildPortraitLayout(context)
                ),
            ],
          )),
    );
  }

  Widget _buildLandScapeLayout(BuildContext context){
    return Padding(
      padding: EdgeInsets.only(left: 40.w, right: 40.w, top: 170.h),
      child: Column(
        children: [
          Text(
            'Danh sách nhân viên',
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFilterDropdown(
                label: "Lọc theo chức vụ",
                items: _positionItems,
                selectedValue: _selectedPosition,
                onChanged: (value) {
                  setState(() {
                    _selectedPosition = value;
                  });
                },
              ),
              SizedBox(height: 60.h,),
              SizedBox(
                height: 400,
                child:  StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("staffs")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Center(child: Text("Lỗi dữ liệu"));
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allStaffs = snapshot.data!.docs;

                    final staffs = (_selectedPosition == null || _selectedPosition == "Tất cả")
                        ? allStaffs
                        : allStaffs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data["position"] == _selectedPosition;
                    }).toList();

                    if (staffs.isEmpty)
                      return const Center(child: Text("Không có nhân viên nào"));

                    return ListView.separated(
                      itemCount: staffs.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey,
                        thickness: 0.2.w,
                        indent: 2.w,
                        endIndent: 2.w,
                      ),
                      itemBuilder: (context, index) {
                        final staff = staffs[index].data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => _showStaffDetails(context, staff),
                          child: Padding(
                            padding:  EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 4.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40.r,
                                      backgroundImage: staff["imageUrl"] != null
                                          ? NetworkImage(staff["imageUrl"])
                                          : null,
                                      child: staff["imageUrl"] == null
                                          ? Icon(Icons.person, size: 10.r)
                                          : null,
                                    ),
                                    SizedBox(width: 5.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff["name"] ?? "Không tên",
                                          style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontSize: 6.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(children: [
                                          Text(
                                            staff["position"] ?? "Không rõ vai trò",
                                            style: TextStyle(
                                                fontSize: 4.sp, color: Colors.grey),
                                          ),
                                          SizedBox(width: 5.w),
                                          Container(
                                            width: 5.w,
                                            height: 12.h,
                                            decoration: BoxDecoration(
                                              color: staff["isFree"] == 1
                                                  ? Colors.green
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          )

        ],
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context){
    return Padding(
      padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 170.h),
      child: Column(
        children: [
          Text(
            'Danh sách nhân viên',
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.w700,
              fontSize: 35.sp,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFilterDropdown(
                label: "Lọc theo chức vụ",
                items: _positionItems,
                selectedValue: _selectedPosition,
                onChanged: (value) {
                  setState(() {
                    _selectedPosition = value;
                  });
                },
              ),
              SizedBox(height: 30.h,),
              SizedBox(
                height: 400,
                child:  StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("staffs")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Center(child: Text("Lỗi dữ liệu"));
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allStaffs = snapshot.data!.docs;

                    final staffs = (_selectedPosition == null || _selectedPosition == "Tất cả")
                        ? allStaffs
                        : allStaffs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data["position"] == _selectedPosition;
                    }).toList();

                    if (staffs.isEmpty)
                      return const Center(child: Text("Không có nhân viên nào"));

                    return ListView.separated(
                      itemCount: staffs.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey,
                        thickness: 0.2.w,
                        indent: 2.w,
                        endIndent: 2.w,
                      ),
                      itemBuilder: (context, index) {
                        final staff = staffs[index].data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => _showStaffDetails(context, staff),
                          child: Padding(
                            padding:  EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 4.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30.r,
                                      backgroundImage: staff["imageUrl"] != null
                                          ? NetworkImage(staff["imageUrl"])
                                          : null,
                                      child: staff["imageUrl"] == null
                                          ? Icon(Icons.person, size: 10.r)
                                          : null,
                                    ),
                                    SizedBox(width: 25.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff["name"] ?? "Không tên",
                                          style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(children: [
                                          Text(
                                            staff["position"] ?? "Không rõ vai trò",
                                            style: TextStyle(
                                                fontSize: 13.sp, color: Colors.grey),
                                          ),
                                          SizedBox(width: 25.w),
                                          Container(
                                            width: 10.w,
                                            height: 12.h,
                                            decoration: BoxDecoration(
                                              color: staff["isFree"] == 1
                                                  ? Colors.green
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget buildFilterDropdown({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {

    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 30.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(color: Colors.black, fontSize: isLandscape? 5.sp : 15.sp),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item, style: TextStyle(fontSize: isLandscape? 5.sp : 15.sp),
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical:2.h,horizontal: isLandscape? 10.w : 25.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: isLandscape? 304.w : 324.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: isLandscape? 10.w : 27.w),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

