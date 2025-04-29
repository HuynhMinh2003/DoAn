import 'package:do_an/src/models/staffs.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  String? _selectedPosition;
  List<String> _positionItems = [];
  List<Staff> _staffList = [];
  List<Staff> _allStaffList = []; // Lưu danh sách đầy đủ của nhân viên

  @override
  void initState() {
    super.initState();
    _fetchPositions();
    _fetchStaff();
  }

  void _fetchPositions() async {
    final snapshot = await FirebaseDatabase.instance.ref().child("positions").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _positionItems = ["Tất cả"];
        _positionItems.addAll(data.values.map((e) => e.toString()));
      });
    }
  }

  void _fetchStaff() async {
    final snapshot = await FirebaseFirestore.instance.collection('staffs').get();
    final staffList = snapshot.docs.map((doc) => Staff.fromFirestore(doc)).toList();
    setState(() {
      _allStaffList = staffList;  // Lưu danh sách đầy đủ
      _staffList = staffList;     // Hiển thị tất cả nhân viên ban đầu
    });
  }

  void _filterStaffByPosition(String? position) {
    if (position == "Tất cả" || position == null) {
      _staffList = _allStaffList; // Hiển thị tất cả nhân viên
    } else {
      _staffList = _allStaffList.where((staff) => staff.position == position).toList();
    }
  }

  void _showStaffDetails(BuildContext context, Staff staff) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Thông tin cá nhân",
          style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: isLandscape ? 5.sp : 20.sp, color: Colors.blueAccent),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (staff.imageUrl.isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 70.r,
                    backgroundImage: NetworkImage(staff.imageUrl),
                  ),
                ),
              SizedBox(height: 30.h),
              Text("Họ và tên: ${staff.name}", style: TextStyle(fontSize: isLandscape ? 3.5.sp : 15.sp)),
              SizedBox(height: 18.h),
              Text("Email: ${staff.email}", style: TextStyle(fontSize: isLandscape ? 3.5.sp : 15.sp)),
              SizedBox(height: 18.h),
              Text("SĐT: ${staff.phone}", style: TextStyle(fontSize: isLandscape ? 3.5.sp : 15.sp)),
              SizedBox(height: 18.h),
              Text("Vị trí: ${staff.position}", style: TextStyle(fontSize: isLandscape ? 3.5.sp : 15.sp)),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: staff.isFree
                    ? () {
                  print("Button nhấn được");
                }
                    : null,
                child: Text(
                  "Phân việc",
                  style: TextStyle(
                    fontSize: isLandscape ? 4.sp : 15.sp,
                    color: staff.isFree ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text("Đóng", style: TextStyle(fontSize: isLandscape ? 4.sp : 15.sp)),
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
              child: isLandscape ? _buildLandScapeLayout(context) : _buildPortraitLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandScapeLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 170.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Danh sách nhân viên',
            style: TextStyle(
              fontFamily: "Oswald",
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Column(
              children: [
                Container(
                  width: 200.w,
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FEFF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFilterDropdown(
                          label: "Lọc theo chức vụ",
                          items: _positionItems,
                          selectedValue: _selectedPosition,
                          onChanged: (value) {
                            setState(() {
                              _selectedPosition = value;
                              _filterStaffByPosition(value); // Lọc lại khi thay đổi
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                Flexible(
                  child: _staffList.isEmpty
                      ? const Center(child: Text("Không có nhân viên nào"))
                      : SingleChildScrollView(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 30.h,
                        crossAxisSpacing: 10.w,
                        childAspectRatio: 5 / 1.5,
                      ),
                      itemCount: _staffList.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final staff = _staffList[index];
                        return GestureDetector(
                          onTap: () => _showStaffDetails(context, staff),
                          child: Container(
                            padding: EdgeInsets.all(5.sp),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(width: 5.w),
                                      Container(
                                        width: 16.w,
                                        height: 70.h,
                                        child: CircleAvatar(
                                          radius: 8.r,
                                          backgroundImage: staff.imageUrl.isNotEmpty
                                              ? NetworkImage(staff.imageUrl)
                                              : null,
                                          child: staff.imageUrl.isEmpty
                                              ? Icon(Icons.person, size: 40.w)
                                              : null,
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              staff.name,
                                              style: TextStyle(
                                                fontFamily: "Oswald",
                                                fontSize: 6.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              staff.isFree ? "Đang rảnh" : "Đang bận",
                                              style: TextStyle(
                                                fontSize: 4.sp,
                                                color: staff.isFree ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
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
          SizedBox(height: 20.h),
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
                    _filterStaffByPosition(value);
                  });
                },
              ),
              SizedBox(height: 30.h),
              SizedBox(
                height: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection("staffs").snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Center(child: Text("Lỗi dữ liệu"));

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // 👉 Hiển thị shimmer loading
                      return ListView.separated(
                        itemCount: 6,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (context, index) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Row(
                            children: [
                              CircleAvatar(radius: 30.r, backgroundColor: Colors.white),
                              SizedBox(width: 25.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 150.w,
                                    height: 20.h,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    width: 100.w,
                                    height: 15.h,
                                    color: Colors.white,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }

                    final allStaffs = snapshot.data!.docs.map((doc) => Staff.fromFirestore(doc)).toList();

                    final staffs = (_selectedPosition == null || _selectedPosition == "Tất cả")
                        ? allStaffs
                        : allStaffs.where((staff) => staff.position == _selectedPosition).toList();

                    if (staffs.isEmpty) return const Center(child: Text("Không có nhân viên nào"));

                    return ListView.separated(
                      itemCount: staffs.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey,
                        thickness: 0.2.w,
                        indent: 2.w,
                        endIndent: 2.w,
                      ),
                      itemBuilder: (context, index) {
                        final staff = staffs[index];
                        return GestureDetector(
                          onTap: () => _showStaffDetails(context, staff),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30.r,
                                      backgroundImage: staff.imageUrl.isNotEmpty
                                          ? NetworkImage(staff.imageUrl)
                                          : null,
                                      child: staff.imageUrl.isEmpty
                                          ? Icon(Icons.person, size: 10.r)
                                          : null,
                                    ),
                                    SizedBox(width: 25.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff.name.isNotEmpty ? staff.name : "Không tên",
                                          style: TextStyle(
                                            fontFamily: "Oswald",
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(children: [
                                          Text(
                                            staff.position.isNotEmpty ? staff.position : "Không rõ vai trò",
                                            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                                          ),
                                          SizedBox(width: 25.w),
                                          Container(
                                            width: 10.w,
                                            height: 12.h,
                                            decoration: BoxDecoration(
                                              color: staff.isFree ? Colors.green : Colors.red,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
// Hàm lọc nhân viên theo chức vụ
  Widget buildFilterDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
  }) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(color: Colors.black, fontSize: isLandscape ? 5.sp : 15.sp),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString(), // Ép kiểu thành String cho cả String và int
                    style: TextStyle(fontSize: isLandscape ? 5.sp : 15.sp),
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: isLandscape ? 15.w : 25.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: isLandscape ? 200.w : 324.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: isLandscape ? 10.w : 27.w),
              ),
            ),
          ),
        ),
      ),
    );
  }
}







