import 'dart:async'; // Thêm import Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an/src/models/apartment.dart';
import 'package:do_an/src/resources/contract_info_page.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart'; // Thêm import shimmer

class ApartmentFilterPage extends StatefulWidget {
  const ApartmentFilterPage({Key? key}) : super(key: key);

  @override
  State<ApartmentFilterPage> createState() => _ApartmentFilterPageState();
}

class _ApartmentFilterPageState extends State<ApartmentFilterPage> {
  List<Apartment> allApartments = [];
  List<Apartment> filteredApartments = [];

  String? selectedBuilding;
  int? selectedFloor;

  List<String> getAvailableBuildings() {
    return allApartments.map((a) => a.building).toSet().toList()..sort();
  }

  Timer? _debounce;

  double minArea = 50;
  double maxArea = 120;
  RangeValues selectedAreaRange = const RangeValues(50, 120);

  void showApartmentDialog(BuildContext context, Apartment apartment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Phòng ${apartment.apartmentName}", textAlign: TextAlign.center, style: TextStyle(fontFamily: "Oswald", fontWeight: FontWeight.bold, fontSize: 8.sp),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h,),
            Text('Diện tích: ${apartment.area} m²', style: TextStyle(fontSize: 4.sp),),
            SizedBox(height: 30.h,),
            Text(apartment.description, style: TextStyle(fontSize: 4.sp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContractInfoPage(
                      apartmentData: apartment,
                      contractType: 'thuê',
                      apartmentId: apartment.id, // 👈 truyền ID
                    ),
                  ));
            },
            child: Text("Thuê"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContractInfoPage(
                      apartmentData: apartment,
                      contractType: 'mua',
                      apartmentId: apartment.id, // 👈 truyền ID
                    ),
                  ));
            },
            child: Text("Mua"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadApartmentsFromFirestore();
    fetchAreaRangeFromFirestore();
  }

  @override
  void dispose(){
    _debounce?.cancel();
    super.dispose();

  }

  Future<void> fetchAreaRangeFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('apartments').get();
    final areas = snapshot.docs
        .map((doc) => (doc['area'] as num).toDouble())
        .toList();

    if (areas.isNotEmpty) {
      final min = areas.reduce(minFunction);
      final max = areas.reduce(maxFunction);

      setState(() {
        minArea = min;
        maxArea = max;
        selectedAreaRange = RangeValues(minArea, maxArea);
      });
    }
  }

  double minFunction(double a, double b) => a < b ? a : b;
  double maxFunction(double a, double b) => a > b ? a : b;

  Future<void> loadApartmentsFromFirestore() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('apartments').get();
      List<Apartment> apartments = [];

      for (var doc in snapshot.docs) {
        try {
          apartments.add(Apartment.fromFirestore(doc));
        } catch (e) {
          print('❌ Error parsing document ${doc.id}: $e');
        }
      }

      // Sort căn hộ theo tòa nhà, tầng và tên căn hộ
      apartments.sort((a, b) {
        int buildingCompare = a.building.compareTo(b.building);
        if (buildingCompare != 0) return buildingCompare;
        int floorCompare = a.floor.compareTo(b.floor);
        if (floorCompare != 0) return floorCompare;
        return a.apartmentName.compareTo(b.apartmentName);
      });

      if (mounted) {
        setState(() {
          allApartments = apartments;
          filteredApartments = apartments; // Mặc định tất cả căn hộ
        });
      }
    } catch (e) {
      print('Error loading apartments: $e');
    }
  }

  void applyFilters() {
    List<Apartment> result = allApartments;

    if (selectedBuilding != null) {
      result = result.where((a) => a.building == selectedBuilding).toList();
    }

    if (selectedFloor != null) {
      result = result.where((a) => a.floor == selectedFloor).toList();
    }

    result = result
        .where((a) =>
            a.area >= selectedAreaRange.start &&
            a.area <= selectedAreaRange.end)
        .toList();

    setState(() {
      filteredApartments = result;
    });
  }

  List<int> getFloorsByBuilding(
      List<Apartment> apartments, String selectedBuilding) {
    final filtered =
        apartments.where((apt) => apt.building == selectedBuilding);
    final floors = filtered.map((apt) => apt.floor).toSet().toList();
    floors.sort();
    return floors;
  }

  List<int> getFloorsForSelectedBuilding() {
    if (selectedBuilding == null) {
      return [];
    }
    return getFloorsByBuilding(allApartments, selectedBuilding!);
  }

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: EdgeInsets.only(left: 30.w, right: 30.w, top: 170.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Danh sách căn hộ",
                    style: TextStyle(
                      fontFamily: "Oswald",
                      fontWeight: FontWeight.w700,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  SizedBox(
                      height: MediaQuery.of(context).size.height - 360.h ,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Cột bên trái: Bộ lọc
                          Expanded(
                            child: Column(
                              children: [
                                buildFilterDropdown<String>(
                                  label: "Chọn tòa",
                                  items: getAvailableBuildings(),
                                  selectedValue: selectedBuilding,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBuilding = value;
                                      selectedFloor = null;
                                    });
                                    applyFilters();
                                  },
                                ),
                                SizedBox(height: 50.h),
                                buildFilterDropdown<int>(
                                  label: "Chọn tầng",
                                  items: getFloorsForSelectedBuilding(),
                                  selectedValue: selectedFloor,
                                  itemLabelBuilder: (floor) => "Tầng $floor",
                                  onChanged: (value) {
                                    setState(() {
                                      selectedFloor = value;
                                    });
                                    applyFilters();
                                  },
                                ),
                                SizedBox(height: 50.h),
                                buildAreaFilter(),
                              ],
                            ),
                          ),
                          Expanded(
                            child: allApartments.isEmpty
                                ? ListView.builder(
                                    itemCount: 6,
                                    itemBuilder: (context, index) => Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 4.h),
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(
                                          height: 80.h,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : (filteredApartments.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Không có căn hộ nào',
                                          style: TextStyle(
                                              fontSize: 5.sp,
                                              color: Colors.black54),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredApartments.length,
                                        itemBuilder: (context, index) {
                                          final apartment =
                                              filteredApartments[index];

                                          Icon statusIcon;
                                          String statusText;

                                          if (apartment.isRent == true) {
                                            statusIcon = const Icon(
                                                Icons.person,
                                                color: Colors.orange);
                                            statusText = "Đang cho thuê";
                                          } else if (apartment.isSale == true) {
                                            statusIcon = const Icon(
                                                Icons.shopping_cart,
                                                color: Colors.green);
                                            statusText = "Đang bán";
                                          } else {
                                            statusIcon = const Icon(
                                                Icons.home_outlined,
                                                color: Colors.grey);
                                            statusText = "Trống";
                                          }

                                          return Card(
                                            color: Color(0xFFF7FEFF),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r)),
                                            elevation: 2,
                                            child: ListTile(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 16.w,
                                                      vertical: 8.h),
                                              title: Text(
                                                  '${apartment.building} - ${apartment.apartmentName}',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Diện tích: ${apartment.area} m²'),
                                                  SizedBox(height: 4.h),
                                                  Row(
                                                    children: [
                                                      statusIcon,
                                                      SizedBox(width: 4.w),
                                                      Text(statusText,
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black54)),
                                                    ],
                                                  )
                                                ],
                                              ),
                                              onTap: () {
                                                showApartmentDialog(
                                                    context, apartment);
                                              },
                                            ),
                                          );
                                        },
                                      )),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget buildFilterDropdown<T>({
    required String label,
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabelBuilder, // <--- thêm hàm tùy chọn
  }) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 30.w, 8.h),
      child: SizedBox(
        height: 60.h,
        child: Container(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              hint: Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isLandscape ? 5.sp : 15.sp,
                ),
              ),
              items: items.map((item) {
                final displayText = itemLabelBuilder != null
                    ? itemLabelBuilder(item)
                    : item.toString();

                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayText,
                    style: TextStyle(fontSize: isLandscape ? 5.sp : 15.sp),
                  ),
                );
              }).toList(),
              value: selectedValue,
              onChanged: onChanged,
              selectedItemBuilder: (context) {
                return items.map((item) {
                  final displayText = itemLabelBuilder != null
                      ? itemLabelBuilder(item)
                      : item.toString();

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayText,
                      style: TextStyle(fontSize: isLandscape ? 5.sp : 15.sp),
                    ),
                  );
                }).toList();
              },
              buttonStyleData: ButtonStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(
                  vertical: 2.h,
                  horizontal: isLandscape ? 10.w : 25.w,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: Color(0xe2707070)),
                  color: Color(0xFFF7FEFF),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200.h,
                width: isLandscape ? 100.w : 324.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  color: Color(0xFFF7FEFF),
                ),
                elevation: 4,
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 40.h,
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 10.w : 27.w,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAreaFilter() {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < size.width;

    return Padding(
      padding: EdgeInsets.fromLTRB(0.w, 10.h, 30.w, 8.h),
      // Điều chỉnh padding nếu cần
      child: SizedBox(
        height: 60.h, // Điều chỉnh chiều cao phù hợp
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: Color(0xe2707070)),
            color: Color(0xFFF7FEFF), // Màu nền nhẹ
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            // Điều chỉnh padding ngang
            child: Row(
              children: [
                Text('Diện tích',
                    style: TextStyle(fontSize: isLandscape ? 5.sp : 15.sp)),
                SizedBox(
                  width: 3.w,
                ),
                Expanded(
                  child: RangeSlider(
                    values: selectedAreaRange,
                    min: minArea,
                    max: maxArea,
                    divisions: (maxArea - minArea).toInt(),
                    labels: RangeLabels(
                      '${selectedAreaRange.start.round()} m²',
                      '${selectedAreaRange.end.round()} m²',
                    ),
                    onChanged: (values) {
                      setState(() {
                        selectedAreaRange = values;
                      });

                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
